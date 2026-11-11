import { setupServer } from "msw/node";
import { handlers } from "../../src/mocks/handlers";

/** Intercepts the requests made by the code under test and answers them with the mock handlers. */
export const server = setupServer(...handlers);
