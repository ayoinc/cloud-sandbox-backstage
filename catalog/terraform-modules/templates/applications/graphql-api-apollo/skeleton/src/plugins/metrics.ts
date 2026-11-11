import type { ApolloServerPlugin } from '@apollo/server';
import { collectDefaultMetrics, Histogram, Registry } from '@prometheus-io/client';

export interface Metrics {
  registry: Registry;
  plugin: ApolloServerPlugin;
}

/**
 * Creates the Prometheus registry of the API: the Node.js process metrics and
 * a histogram of the GraphQL request durations, labelled by operation name,
 * operation type and outcome.
 */
export function createMetrics(): Metrics {
  const registry = new Registry();
  collectDefaultMetrics({ register: registry });
  const duration = new Histogram({
    name: 'graphql_request_duration_seconds',
    help: 'Duration of GraphQL requests in seconds.',
    labelNames: ['operation_name', 'operation_type', 'status'],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
    registers: [registry],
  });

  const plugin: ApolloServerPlugin = {
    async requestDidStart() {
      const stop = duration.startTimer();
      return {
        async willSendResponse({ operationName, operation, errors }) {
          stop({
            // Only named operations get their own series: anonymous ones would
            // otherwise make the label values unbounded.
            operation_name: operationName ?? 'anonymous',
            operation_type: operation?.operation ?? 'unknown',
            status: errors?.length ? 'error' : 'ok',
          });
        },
      };
    },
  };
  return { registry, plugin };
}
