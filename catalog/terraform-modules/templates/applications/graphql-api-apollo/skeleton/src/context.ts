import type { PubSub } from 'graphql-subscriptions';
import type { Viewer } from './auth.js';
import type { AuthConfig } from './config.js';
import type { ProductRepository } from './db/products.js';

/** What every resolver receives as its third argument. */
export interface Context {
  /** The caller, or null for an anonymous request. */
  viewer: Viewer | null;
  auth: Pick<AuthConfig, 'enabled' | 'rbac'>;
  products: ProductRepository;
  pubsub: PubSub;
}
