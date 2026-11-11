import { QueryClient } from "@tanstack/react-query";

/** Creates the query client with the defaults of the application. */
export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        // Data is reused for a minute before it is fetched again.
        staleTime: 60_000,
        retry: 1,
      },
    },
  });
}
