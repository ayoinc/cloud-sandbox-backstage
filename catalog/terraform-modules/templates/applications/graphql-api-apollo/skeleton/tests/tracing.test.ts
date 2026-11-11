import { spawn } from 'node:child_process';
import http from 'node:http';
import type { AddressInfo } from 'node:net';
import { describe, expect, it } from 'vitest';
import { startTracing } from '../src/tracing.js';
import { testConfig } from './helpers.js';

describe('tracing', () => {
  it('stays off without a collector endpoint or when disabled', () => {
    expect(startTracing({ enabled: true }, 'test')).toBeUndefined();
    expect(startTracing({ enabled: false, endpoint: 'http://127.0.0.1:4318' }, 'test')).toBeUndefined();
  });

  it('exports spans of HTTP requests and GraphQL operations to the collector', async () => {
    // A stand-in collector that keeps the names of the instrumentations it hears from.
    const scopes = new Set<string>();
    const collector = http.createServer((req, res) => {
      const chunks: Buffer[] = [];
      req.on('data', chunk => chunks.push(chunk));
      req.on('end', () => {
        const body = JSON.parse(Buffer.concat(chunks).toString());
        for (const resource of body.resourceSpans ?? []) {
          for (const scope of resource.scopeSpans ?? []) scopes.add(scope.scope.name);
        }
        res.end('{}');
      });
    });
    await new Promise<void>(resolve => collector.listen(0, '127.0.0.1', resolve));
    const endpoint = `http://127.0.0.1:${(collector.address() as AddressInfo).port}`;

    // The API in a process of its own, started the way `npm run dev` starts it.
    const { database } = testConfig();
    const api = spawn(process.execPath, ['--import', 'tsx', '--import', './src/instrument.ts', 'src/index.ts'], {
      env: {
        ...process.env,
        PORT: '0',
        DATABASE_URL: database.url,
        AUTH_ENABLED: 'false',
        CACHE_ENABLED: 'false',
        TRACING_ENABLED: 'true',
        OTEL_EXPORTER_OTLP_ENDPOINT: endpoint,
        OTEL_EXPORTER_OTLP_PROTOCOL: 'http/json',
        OTEL_BSP_SCHEDULE_DELAY: '100',
      },
      stdio: ['ignore', 'pipe', 'inherit'],
    });

    try {
      const url = await new Promise<string>((resolve, reject) => {
        api.stdout.on('data', (data: Buffer) => {
          const match = /ready at (\S+)/.exec(data.toString());
          if (match) resolve(match[1]!);
        });
        api.once('exit', code => reject(new Error(`the API exited with code ${code}`)));
      });
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ query: '{ products { id } }' }),
      });
      expect(response.status).toBe(200);

      await expect
        .poll(() => [...scopes], { timeout: 10_000 })
        .toEqual(
          expect.arrayContaining(['@opentelemetry/instrumentation-http', '@opentelemetry/instrumentation-graphql']),
        );
    } finally {
      api.kill();
      await new Promise(resolve => collector.close(resolve));
    }
  });
});
