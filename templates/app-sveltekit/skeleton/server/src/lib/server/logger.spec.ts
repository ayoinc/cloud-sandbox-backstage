import { afterEach, describe, expect, it, vi } from 'vitest';
import site from '../site.json';
import { log } from './logger.ts';

describe('log', () => {
	afterEach(() => vi.restoreAllMocks());

	it('writes one JSON line with the service name', () => {
		const write = vi.spyOn(console, 'log').mockImplementation(() => {});

		log('info', 'request', { status: 200 });

		expect(write).toHaveBeenCalledOnce();
		expect(JSON.parse(String(write.mock.calls[0]?.[0]))).toMatchObject({
			level: 'info',
			service: site.name,
			message: 'request',
			status: 200
		});
	});

	it('writes errors to standard error', () => {
		const write = vi.spyOn(console, 'error').mockImplementation(() => {});

		log('error', 'failed');

		expect(write).toHaveBeenCalledOnce();
	});
});
