// See https://svelte.dev/docs/kit/types#app.d.ts
declare global {
	namespace App {
		interface Error {
			message: string;
			/** Identifier to quote when reporting the error; it is in the logs. */
			requestId?: string;
		}
		interface Locals {
			requestId: string;
		}
	}
}

export {};
