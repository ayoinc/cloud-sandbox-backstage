// Preloaded before the application (node --import): tracing has to be in
// place before the modules it instruments are loaded.
import { loadConfig } from './config.js';
import { startTracing } from './tracing.js';

const serviceName = process.env.OTEL_SERVICE_NAME ?? '${{ values.apiName }}';
const flush = startTracing(loadConfig().tracing, serviceName);
if (flush) {
  process.once('SIGTERM', () => void flush());
  process.once('SIGINT', () => void flush());
}
