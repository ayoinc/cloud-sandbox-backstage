import { describe, expect, it } from 'vitest';
import { ConfigError, loadConfig } from '../src/config.js';

const TOKEN = 'a-token-that-is-long-enough-0123456789';

describe('loadConfig', () => {
  it('defaults to HTTP on loopback', () => {
    expect(loadConfig({}, [])).toEqual({
      transport: 'http',
      host: '127.0.0.1',
      port: ${{ values.port }},
      authToken: undefined,
      allowedHosts: undefined,
    });
  });

  it('selects stdio with the flag or the variable', () => {
    expect(loadConfig({}, ['--stdio']).transport).toBe('stdio');
    expect(loadConfig({ MCP_TRANSPORT: 'stdio' }, []).transport).toBe('stdio');
  });

  it('treats empty variables as unset', () => {
    expect(loadConfig({ PORT: '', MCP_AUTH_TOKEN: '', MCP_ALLOWED_HOSTS: '' }, [])).toMatchObject({
      port: ${{ values.port }},
      authToken: undefined,
      allowedHosts: undefined,
    });
  });

  it('refuses to listen on a public address without a token', () => {
    expect(() => loadConfig({ HOST: '0.0.0.0' }, [])).toThrow(ConfigError);
    expect(loadConfig({ HOST: '0.0.0.0', MCP_AUTH_TOKEN: TOKEN }, []).authToken).toBe(TOKEN);
  });

  it('does not require a token on stdio', () => {
    expect(loadConfig({ HOST: '0.0.0.0' }, ['--stdio']).transport).toBe('stdio');
  });

  it('rejects a short token and an invalid port', () => {
    expect(() => loadConfig({ MCP_AUTH_TOKEN: 'short' }, [])).toThrow(/at least 32 characters/);
    expect(() => loadConfig({ PORT: 'eighty' }, [])).toThrow(ConfigError);
  });

  it('splits the allowed hosts', () => {
    expect(loadConfig({ MCP_ALLOWED_HOSTS: 'mcp.internal, localhost' }, []).allowedHosts).toEqual([
      'mcp.internal',
      'localhost',
    ]);
  });
});
