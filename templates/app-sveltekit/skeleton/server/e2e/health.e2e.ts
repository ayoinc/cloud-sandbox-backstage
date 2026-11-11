import { expect, test } from '@playwright/test';

test('the health endpoint reports the service', async ({ request }) => {
	const response = await request.get('/health');

	expect(response.status()).toBe(200);
	expect(response.headers()['x-request-id']).toBeTruthy();
	expect(await response.json()).toMatchObject({ status: 'ok' });
});
