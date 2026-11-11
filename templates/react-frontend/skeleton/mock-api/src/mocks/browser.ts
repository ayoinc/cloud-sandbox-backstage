import { setupWorker } from "msw/browser";
import { handlers } from "./handlers";

/** Service worker that answers API requests in the browser during development. */
export const worker = setupWorker(...handlers);
