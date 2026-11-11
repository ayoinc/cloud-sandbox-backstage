import { describe, expect, it } from 'bun:test';
import { loadEnv } from '../src/env';

describe('loadEnv', () => {
  it('applies the defaults', () => {
    expect(loadEnv({})).toEqual({
      PORT: ${{ values.port }},
      APP_ENV: 'development',
      LOG_LEVEL: 'info',
    });
  });

  it('reads and converts the variables', () => {
    const env = loadEnv({
      PORT: '9000',
      APP_ENV: 'production',
      LOG_LEVEL: 'warn',
    });
    expect(env).toEqual({
      PORT: 9000,
      APP_ENV: 'production',
      LOG_LEVEL: 'warn',
    });
  });

  it('treats empty variables as unset', () => {
    expect(loadEnv({ PORT: '', LOG_LEVEL: '' }).PORT).toBe(${{ values.port }});
  });

  it('names the invalid variable', () => {
    expect(() => loadEnv({ PORT: 'http' })).toThrow(/PORT/);
    expect(() => loadEnv({ LOG_LEVEL: 'loud' })).toThrow(/LOG_LEVEL/);
  });
});
