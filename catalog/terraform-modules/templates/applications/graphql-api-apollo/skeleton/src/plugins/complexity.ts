import type { ApolloServerPlugin } from '@apollo/server';
import { GraphQLError, type GraphQLSchema } from 'graphql';
import { type ComplexityEstimator, getComplexity, simpleEstimator } from 'graphql-query-complexity';

/** A list field costs what one of its items costs times the page size asked for. */
const pageSizeEstimator: ComplexityEstimator = ({ args, childComplexity }) =>
  typeof args.limit === 'number' ? 1 + args.limit * childComplexity : undefined;

/**
 * Rejects operations that cost more than the limit before they run. Every
 * field costs 1; see pageSizeEstimator for lists.
 */
export function complexityPlugin(schema: GraphQLSchema, limit: number): ApolloServerPlugin {
  return {
    async requestDidStart() {
      return {
        async didResolveOperation({ request, document }) {
          const complexity = getComplexity({
            schema,
            query: document,
            operationName: request.operationName,
            variables: request.variables,
            estimators: [pageSizeEstimator, simpleEstimator({ defaultComplexity: 1 })],
          });
          if (complexity > limit) {
            throw new GraphQLError(`The query is too complex: it costs ${complexity}, the limit is ${limit}.`, {
              extensions: { code: 'QUERY_TOO_COMPLEX', complexity, limit, http: { status: 400 } },
            });
          }
        },
      };
    },
  };
}
