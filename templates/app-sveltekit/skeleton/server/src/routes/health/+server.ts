import { json } from '@sveltejs/kit';
import site from '#lib/site.json';
import type { RequestHandler } from './$types';

export const prerender = false;

/** Liveness and readiness probe: the server answers requests. */
export const GET: RequestHandler = () =>
	json(
		{ status: 'ok', service: site.name, timestamp: new Date().toISOString() },
		{ headers: { 'cache-control': 'no-store' } }
	);
