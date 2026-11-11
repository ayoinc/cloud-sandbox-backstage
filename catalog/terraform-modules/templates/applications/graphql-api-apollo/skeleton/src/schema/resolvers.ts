import { GraphQLError } from 'graphql';
import { authorize } from '../auth.js';
import type { Resolvers } from '../generated/graphql.js';

export const PRODUCT_CREATED = 'PRODUCT_CREATED';

const MAX_PAGE_SIZE = 100;

export const resolvers: Resolvers = {
  Query: {
    products: (_parent, { limit, offset }, { products }) => {
      if (limit < 1 || limit > MAX_PAGE_SIZE || offset < 0) {
        throw new GraphQLError(`limit must be between 1 and ${MAX_PAGE_SIZE}, and offset 0 or more.`, {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }
      return products.list(limit, offset);
    },
    product: async (_parent, { id }, { products }) => (await products.get(id)) ?? null,
    viewer: (_parent, _args, { viewer }) => viewer,
  },
  Mutation: {
    createProduct: async (_parent, { input }, { auth, viewer, products, pubsub }) => {
      authorize(auth, viewer, 'admin');
      if (input.name.trim() === '' || input.priceCents < 0) {
        throw new GraphQLError('name must not be empty and priceCents must be 0 or more.', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }
      const product = await products.create(input);
      await pubsub.publish(PRODUCT_CREATED, { productCreated: product });
      return product;
    },
    deleteProduct: (_parent, { id }, { auth, viewer, products }) => {
      authorize(auth, viewer, 'admin');
      return products.delete(id);
    },
  },
};

export const subscriptionResolvers: Resolvers = {
  Subscription: {
    productCreated: {
      subscribe: (_parent, _args, { pubsub }) => pubsub.asyncIterableIterator(PRODUCT_CREATED),
    },
  },
};
