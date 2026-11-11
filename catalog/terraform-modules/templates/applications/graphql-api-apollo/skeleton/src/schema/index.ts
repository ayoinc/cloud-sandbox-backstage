import { readFileSync } from 'node:fs';
import { makeExecutableSchema } from '@graphql-tools/schema';
import type { GraphQLSchema } from 'graphql';
import { resolvers, subscriptionResolvers } from './resolvers.js';

function sdl(file: string): string {
  return readFileSync(new URL(file, import.meta.url), 'utf8');
}

/** Builds the schema. The Subscription type is only part of it when subscriptions are on. */
export function buildSchema(options: { subscriptions: boolean }): GraphQLSchema {
  return makeExecutableSchema({
    typeDefs: [sdl('./schema.graphql'), ...(options.subscriptions ? [sdl('./subscriptions.graphql')] : [])],
    resolvers: [resolvers, ...(options.subscriptions ? [subscriptionResolvers] : [])],
  });
}
