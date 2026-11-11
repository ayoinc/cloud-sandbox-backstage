import { expect, test } from '@playwright/test';

test('the home page works as an app', async ({ page }) => {
	await page.goto('/');
	await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

	await page.getByLabel('New task').fill('Ship it');
	await page.getByRole('button', { name: 'Add' }).click();

	await expect(page.getByRole('status')).toHaveText('1 of 1 left');
	await page.getByRole('checkbox').check();
	await expect(page.getByRole('status')).toHaveText('0 of 1 left');
});

test('unknown pages answer 404', async ({ page }) => {
	const response = await page.goto('/nowhere');
	expect(response?.status()).toBe(404);
	await expect(page.getByRole('heading', { level: 1 })).toHaveText('404');
});
