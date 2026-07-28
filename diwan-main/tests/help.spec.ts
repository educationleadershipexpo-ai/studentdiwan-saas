import { test, expect } from '@playwright/test';
import { restoreSession } from './helpers/login';

test.describe('Help Center & Documentation CMS', () => {
  
  test('unauthenticated visit to /help redirects to /login', async ({ page }) => {
    await page.goto('/help');
    await expect(page).toHaveURL(/\/login/, { timeout: 8_000 });
  });

  test.describe('Authenticated user', () => {
    test.beforeEach(async ({ page }) => {
      await restoreSession(page);
      await page.goto('/help');
      await expect(page).not.toHaveURL(/\/login/);
    });

    test('renders help center home page with categories', async ({ page }) => {
      // Check heading is visible
      await expect(
        page.getByRole('heading', { name: /how can we help/i }).first()
      ).toBeVisible();

      // Check some categories are visible
      await expect(page.getByText('Getting Started').first()).toBeVisible();
      await expect(page.getByText('User Guides').first()).toBeVisible();
      await expect(page.getByText('Module Documentation').first()).toBeVisible();
    });

    test('can search articles', async ({ page }) => {
      // Click the search button in the left sidebar
      await page.getByRole('button', { name: /search docs/i }).click();
      
      const searchInput = page.getByPlaceholder(/search the entire/i).first();
      await expect(searchInput).toBeVisible();
      
      // Search for "Welcome"
      await searchInput.fill('Welcome');
      
      // Result link should appear
      await expect(
        page.getByRole('button', { name: /Welcome to Student Diwan/i }).first()
      ).toBeVisible();
    });

    test('can open an article and see content, reading time, and downloads', async ({ page }) => {
      // Go directly to the welcome article
      await page.goto('/help/getting-started/welcome');
      
      // Title
      await expect(
        page.getByRole('heading', { name: /Welcome to Student Diwan/i }).first()
      ).toBeVisible();
      
      // Reading time
      await expect(page.getByText(/min read/i).first()).toBeVisible();
      
      // Download button
      await expect(page.getByText(/download doc/i).first()).toBeVisible();
    });

    test('admin can access CMS dashboard', async ({ page }) => {
      await page.goto('/help/cms');
      
      // Check CMS heading
      await expect(
        page.getByRole('heading', { name: /documentation cms/i }).first()
      ).toBeVisible();
      
      // Check that Create Article button is present
      await expect(
        page.getByRole('button', { name: /create article/i }).first()
      ).toBeVisible();
    });
  });
});
