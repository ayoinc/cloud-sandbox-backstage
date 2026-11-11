import type { Handle, HandleServerError } from '@sveltejs/kit/hooks';
import { log } from '#lib/server/logger.ts';

/** Gives every request an identifier and logs it with its status and duration. */
export const handle: Handle = async ({ event, resolve }) => {
	const start = performance.now();
	event.locals.requestId = event.request.headers.get('x-request-id') ?? crypto.randomUUID();

	const response = await resolve(event);
	response.headers.set('x-request-id', event.locals.requestId);

	log('info', 'request', {
		requestId: event.locals.requestId,
		method: event.request.method,
		path: event.url.pathname,
		status: response.status,
		durationMs: Math.round(performance.now() - start)
	});
	return response;
};

/**
 * Logs errors thrown by the app's own code with their stack. Expected errors
 * (those raised with `error()` and the framework's, such as 404) are not
 * logged. The page receives SvelteKit's safe message and the request
 * identifier, never the cause.
 */
export const handleError: HandleServerError = ({ kind, error, event }) => {
	if (kind === 'unknown') {
		log('error', 'unhandled error', {
			requestId: event.locals.requestId,
			path: event.url.pathname,
			error: error instanceof Error ? error.message : String(error),
			stack: error instanceof Error ? error.stack : undefined
		});
	}
	return { requestId: event.locals.requestId };
};
