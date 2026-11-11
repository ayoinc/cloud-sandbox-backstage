import type { CodegenConfig } from '@graphql-codegen/cli';

// Generates the TypeScript types of the schema and its resolvers. Run
// `npm run codegen` after every schema change and commit the result.
const config: CodegenConfig = {
  schema: 'src/schema/*.graphql',
  generates: {
    'src/generated/graphql.ts': {
      plugins: ['typescript', 'typescript-resolvers'],
      config: {
        useTypeImports: true,
        contextType: '../context.js#Context',
        // What resolvers return for these types, before field resolvers run.
        mappers: {
          Product: '../db/products.js#Product as ProductRecord',
          Viewer: '../auth.js#Viewer as AuthenticatedViewer',
        },
      },
    },
  },
};

export default config;
