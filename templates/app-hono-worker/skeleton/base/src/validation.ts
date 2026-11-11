import { zValidator } from '@hono/zod-validator';
import type { ZodType } from 'zod';

/**
 * Validates the JSON body against `schema`. A body that does not match is
 * answered with 422 and the list of problems.
 */
export const jsonBody = <T extends ZodType>(schema: T) =>
  zValidator('json', schema, (result, c) => {
    if (!result.success) {
      return c.json(
        {
          error: 'The request body is invalid',
          issues: result.error.issues.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message,
          })),
        },
        422,
      );
    }
  });
