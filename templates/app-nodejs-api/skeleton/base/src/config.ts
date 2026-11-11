import 'dotenv/config';

export const config = {
  name: '${{ values.name }}',
  port: Number.parseInt(process.env.PORT ?? '${{ values.port }}', 10),
  environment: process.env.APP_ENV ?? '${{ values.environment }}',
  // Tests run without log output unless LOG_LEVEL says otherwise.
  logLevel:
    process.env.LOG_LEVEL ??
    (process.env.NODE_ENV === 'test' ? 'silent' : 'info'),
};
