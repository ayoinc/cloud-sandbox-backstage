import { z } from 'zod';

const schema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(${{ values.port }}),
  APP_ENV: z.string().min(1).default('development'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

/** The validated settings of the service. */
export type Env = z.infer<typeof schema>;

/**
 * Parses the settings from `source`, which is `Bun.env` outside tests. Empty
 * variables count as unset. An invalid value throws an error that names the
 * variable.
 */
export function loadEnv(source: Record<string, string | undefined>): Env {
  const present = Object.fromEntries(
    Object.entries(source).filter(([, value]) => value !== ''),
  );
  const result = schema.safeParse(present);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
      .join('; ');
    throw new Error(`Invalid environment: ${problems}`);
  }
  return result.data;
}
