import { McpServer, ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { NoteLimitError, type NoteStore } from './notes.js';

export const SERVER_NAME = '${{ values.name }}';
export const SERVER_VERSION = '0.1.0';

const noteShape = {
  id: z.string(),
  title: z.string(),
  body: z.string(),
  tags: z.array(z.string()),
  createdAt: z.string(),
};

const json = (value: unknown): string => JSON.stringify(value, null, 2);

/**
 * Builds an MCP server over the given store. The HTTP transport is stateless
 * and builds one per request, so this function must stay cheap and must keep
 * all state in the store.
 */
export function createServer(store: NoteStore): McpServer {
  const server = new McpServer(
    { name: SERVER_NAME, version: SERVER_VERSION },
    {
      instructions:
        'Stores short notes. Use add_note to save one, search_notes to find notes by text or tag, ' +
        'and delete_note to remove one. Every note is also readable as a resource.',
    },
  );

  server.registerTool(
    'add_note',
    {
      title: 'Add note',
      description: 'Save a note with a title, a body and optional tags. Returns the stored note with its id.',
      inputSchema: {
        title: z.string().min(1).max(200).describe('Short title of the note'),
        body: z.string().max(10_000).describe('Text of the note'),
        tags: z.array(z.string().min(1).max(50)).max(10).optional().describe('Labels to find the note by'),
      },
      outputSchema: { note: z.object(noteShape) },
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
    },
    ({ title, body, tags }) => {
      try {
        const note = store.add({ title, body, ...(tags ? { tags } : {}) });
        return { content: [{ type: 'text', text: json(note) }], structuredContent: { note } };
      } catch (error) {
        if (error instanceof NoteLimitError) {
          // A tool error is returned to the model, which can then act on it.
          return { content: [{ type: 'text', text: error.message }], isError: true };
        }
        throw error;
      }
    },
  );

  server.registerTool(
    'search_notes',
    {
      title: 'Search notes',
      description:
        'Find notes whose title, body or tags contain the query. An empty query lists every note. ' +
        'Optionally restrict the result to one tag.',
      inputSchema: {
        query: z.string().max(200).describe('Text to look for; empty to list all notes'),
        tag: z.string().min(1).max(50).optional().describe('Only return notes with this tag'),
      },
      outputSchema: { count: z.number().int(), notes: z.array(z.object(noteShape)) },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    ({ query, tag }) => {
      const notes = store.search(query, tag);
      const result = { count: notes.length, notes };
      return { content: [{ type: 'text', text: json(result) }], structuredContent: result };
    },
  );

  server.registerTool(
    'delete_note',
    {
      title: 'Delete note',
      description: 'Permanently delete the note with the given id.',
      inputSchema: { id: z.uuid().describe('Id of the note, as returned by add_note or search_notes') },
      annotations: { readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false },
    },
    ({ id }) => {
      if (!store.delete(id)) {
        return { content: [{ type: 'text', text: `There is no note with id ${id}.` }], isError: true };
      }
      return { content: [{ type: 'text', text: `Deleted note ${id}.` }] };
    },
  );

  server.registerResource(
    'all-notes',
    'notes://all',
    { title: 'All notes', description: 'Every stored note as a JSON array', mimeType: 'application/json' },
    uri => ({
      contents: [{ uri: uri.href, mimeType: 'application/json', text: json(store.list()) }],
    }),
  );

  server.registerResource(
    'note',
    new ResourceTemplate('notes://note/{id}', {
      list: () => ({
        resources: store.list().map(note => ({
          uri: `notes://note/${note.id}`,
          name: note.title,
          mimeType: 'application/json',
        })),
      }),
    }),
    { title: 'Note', description: 'One note by id', mimeType: 'application/json' },
    (uri, { id }) => {
      const note = store.get(String(id));
      if (!note) {
        throw new Error(`There is no note with id ${String(id)}.`);
      }
      return { contents: [{ uri: uri.href, mimeType: 'application/json', text: json(note) }] };
    },
  );

  server.registerPrompt(
    'summarise_notes',
    {
      title: 'Summarise notes',
      description: 'Ask the model to summarise the stored notes, optionally only those with one tag.',
      argsSchema: { tag: z.string().optional().describe('Only summarise notes with this tag') },
    },
    ({ tag }) => ({
      messages: [
        {
          role: 'user',
          content: {
            type: 'text',
            text:
              `Call search_notes with an empty query${tag ? ` and the tag "${tag}"` : ''}, ` +
              'then summarise the notes in at most five bullet points and list any open questions they raise.',
          },
        },
      ],
    }),
  );

  return server;
}
