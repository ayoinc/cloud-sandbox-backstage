// Prints the schema the API serves with the current configuration, in SDL.
// Used to publish it to a schema registry.
import { printSchema } from 'graphql';
import { loadConfig } from '../src/config.js';
import { buildSchema } from '../src/schema/index.js';

const subscriptions = process.env.SUBSCRIPTIONS_ENABLED
  ? process.env.SUBSCRIPTIONS_ENABLED === 'true'
  : loadConfig({ AUTH_ENABLED: 'false' }).subscriptions;
console.log(printSchema(buildSchema({ subscriptions })));
