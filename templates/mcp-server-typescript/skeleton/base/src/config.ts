import { z } from 'zod';

const LOOPBACK_HOSTS = new Set(['127.0.0.1', 'localhost', '::1']);

const environment = z.object({
  MCP_TRANSPORT: z.enum(['http', 'stdio']).default('http'),
  HOST: z.string().min(1).default('127.0.0.1'),
  PORT: z.coerce.number().int().min(0).max(65535).default(${{ values.port }}),
  MCP_AUTH_TOKEN: z.string().min(32, 'MCP_AUTH_TOKEN must be at least 32 characters').optional(),
  MCP_ALLOWED_HOSTS: z.string().optional(),
});

export interface Config {
  transport: 'http' | 'stdio';
  host: string;
  port: number;
  /** Bearer token required on the HTTP transport. Undefined on loopback only. */
  authToken: string | undefined;
  /** Host names accepted in the Host header. Undefined keeps the loopback default. */
  allowedHosts: string[] | undefined;
}

export class ConfigError extends Error {}

/** Unset and empty variables are the same thing: both take the default. */
function withoutEmpty(env: NodeJS.ProcessEnv): Record<string, string> {
  return Object.fromEntries(
    Object.entries(env).filter((entry): entry is [string, string] => Boolean(entry[1])),
  );
}

/**
 * Reads the configuration from environment variables. `--stdio` on the command
 * line selects the stdio transport, which is how desktop clients start servers.
 */
export function loadConfig(
  env: NodeJS.ProcessEnv = process.env,
  argv: readonly string[] = process.argv.slice(2),
): Config {
  const parsed = environment.safeParse(withoutEmpty(env));
  if (!parsed.success) {
    throw new ConfigError(z.prettifyError(parsed.error));
  }
  const values = parsed.data;
  const transport = argv.includes('--stdio') ? 'stdio' : values.MCP_TRANSPORT;
  const allowedHosts = values.MCP_ALLOWED_HOSTS?.split(',')
    .map(host => host.trim())
    .filter(host => host.length > 0);

  if (transport === 'http' && !LOOPBACK_HOSTS.has(values.HOST) && !values.MCP_AUTH_TOKEN) {
    throw new ConfigError(
      `Refusing to listen on ${values.HOST} without authentication. ` +
        'Set MCP_AUTH_TOKEN, or set HOST to 127.0.0.1 for local use.',
    );
  }

  return {
    transport,
    host: values.HOST,
    port: values.PORT,
    authToken: values.MCP_AUTH_TOKEN,
    allowedHosts: allowedHosts?.length ? allowedHosts : undefined,
  };
}

export function isLoopback(host: string): boolean {
  return LOOPBACK_HOSTS.has(host);
}
