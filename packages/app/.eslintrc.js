module.exports = {
  ...require('@backstage/cli/config/eslint-factory')(__dirname),
  overrides: [
    {
      // Allow console statements and unused variables in e2e tests for debugging and test setup
      files: ['e2e-tests/**/*.ts', 'e2e-tests/**/*.tsx'],
      rules: {
        'no-console': 'off',
        '@typescript-eslint/no-unused-vars': [
          'warn',
          {
            argsIgnorePattern: '^_',
            varsIgnorePattern: '^_',
          },
        ],
      },
    },
    {
      // Allow console.warn and console.error for error handling in components
      files: ['src/components/**/*.ts', 'src/components/**/*.tsx'],
      rules: {
        'no-console': ['error', { allow: ['warn', 'error'] }],
      },
    },
  ],
};
