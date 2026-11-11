import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { InMemoryTransport } from '@modelcontextprotocol/sdk/inMemory.js';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { NoteStore, type Note } from '../src/notes.js';
import { createServer, SERVER_NAME } from '../src/server.js';

describe('MCP server', () => {
  let store: NoteStore;
  let client: Client;

  beforeEach(async () => {
    store = new NoteStore(3);
    const server = createServer(store);
    const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
    client = new Client({ name: 'test-client', version: '1.0.0' });
    await Promise.all([server.connect(serverTransport), client.connect(clientTransport)]);
  });

  afterEach(async () => {
    await client.close();
  });

  const addNote = async (title: string, tags: string[] = []): Promise<Note> => {
    const result = await client.callTool({ name: 'add_note', arguments: { title, body: `About ${title}`, tags } });
    expect(result.isError).toBeFalsy();
    return (result.structuredContent as { note: Note }).note;
  };

  it('identifies itself and gives instructions', () => {
    expect(client.getServerVersion()?.name).toBe(SERVER_NAME);
    expect(client.getInstructions()).toContain('add_note');
  });

  it('lists its tools with schemas and annotations', async () => {
    const { tools } = await client.listTools();
    expect(tools.map(tool => tool.name).sort()).toEqual(['add_note', 'delete_note', 'search_notes']);

    const search = tools.find(tool => tool.name === 'search_notes');
    expect(search?.annotations?.readOnlyHint).toBe(true);
    expect(search?.inputSchema.required).toEqual(['query']);
    expect(search?.outputSchema?.properties).toHaveProperty('notes');
    expect(tools.find(tool => tool.name === 'delete_note')?.annotations?.destructiveHint).toBe(true);
  });

  it('adds a note and returns it as structured content', async () => {
    const note = await addNote('Release plan', ['Planning']);
    expect(note).toMatchObject({ title: 'Release plan', body: 'About Release plan', tags: ['planning'] });
    expect(store.get(note.id)).toEqual(note);
  });

  it('searches by text and by tag', async () => {
    await addNote('Release plan', ['planning']);
    await addNote('Incident review', ['operations']);

    const byText = await client.callTool({ name: 'search_notes', arguments: { query: 'incident' } });
    expect(byText.structuredContent).toMatchObject({ count: 1, notes: [{ title: 'Incident review' }] });

    const byTag = await client.callTool({ name: 'search_notes', arguments: { query: '', tag: 'planning' } });
    expect(byTag.structuredContent).toMatchObject({ count: 1, notes: [{ title: 'Release plan' }] });
  });

  it('rejects arguments that do not match the input schema', async () => {
    const result = await client.callTool({ name: 'add_note', arguments: { title: '', body: 'x' } });
    expect(result.isError).toBe(true);
    expect(store.list()).toHaveLength(0);
  });

  it('reports a full store as a tool error', async () => {
    await addNote('one');
    await addNote('two');
    await addNote('three');
    const result = await client.callTool({ name: 'add_note', arguments: { title: 'four', body: '' } });
    expect(result.isError).toBe(true);
    expect(JSON.stringify(result.content)).toContain('at most 3 notes');
  });

  it('deletes a note and reports a missing one as a tool error', async () => {
    const note = await addNote('Temporary');

    const deleted = await client.callTool({ name: 'delete_note', arguments: { id: note.id } });
    expect(deleted.isError).toBeFalsy();
    expect(store.list()).toHaveLength(0);

    const again = await client.callTool({ name: 'delete_note', arguments: { id: note.id } });
    expect(again.isError).toBe(true);
  });

  it('serves notes as resources', async () => {
    const note = await addNote('Release plan');

    const all = await client.readResource({ uri: 'notes://all' });
    expect(JSON.parse((all.contents[0] as { text: string }).text)).toEqual([note]);

    const { resources } = await client.listResources();
    expect(resources.map(resource => resource.uri)).toEqual(
      expect.arrayContaining(['notes://all', `notes://note/${note.id}`]),
    );

    const one = await client.readResource({ uri: `notes://note/${note.id}` });
    expect(JSON.parse((one.contents[0] as { text: string }).text)).toEqual(note);

    await expect(client.readResource({ uri: 'notes://note/unknown' })).rejects.toThrow(/no note/);
  });

  it('offers a prompt that takes an optional tag', async () => {
    const { prompts } = await client.listPrompts();
    expect(prompts.map(prompt => prompt.name)).toEqual(['summarise_notes']);

    const prompt = await client.getPrompt({ name: 'summarise_notes', arguments: { tag: 'planning' } });
    expect(JSON.stringify(prompt.messages)).toContain('planning');
  });
});
