import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { ExpressInstrumentation } from '@opentelemetry/instrumentation-express';
import { GraphQLInstrumentation } from '@opentelemetry/instrumentation-graphql';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { NodeSDK } from '@opentelemetry/sdk-node';
import type { Config } from './config.js';

/**
 * Starts OpenTelemetry tracing of HTTP requests and GraphQL operations and
 * exports the spans over OTLP/HTTP. It must run before express and graphql
 * are loaded, which is why instrument.ts is preloaded with --import.
 *
 * Returns the function that flushes pending spans, or undefined when tracing
 * is off or no collector endpoint is configured.
 */
export function startTracing(
  tracing: Config['tracing'],
  serviceName: string,
): (() => Promise<void>) | undefined {
  if (!tracing.enabled || !tracing.endpoint) return undefined;

  const sdk = new NodeSDK({
    serviceName,
    // The exporter reads the endpoint and headers from OTEL_EXPORTER_OTLP_*.
    traceExporter: new OTLPTraceExporter(),
    instrumentations: [
      new HttpInstrumentation(),
      new ExpressInstrumentation(),
      new GraphQLInstrumentation({ ignoreTrivialResolveSpans: true, mergeItems: true }),
    ],
  });
  sdk.start();
  return () => sdk.shutdown();
}
