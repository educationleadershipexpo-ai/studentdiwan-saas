import { test, expect } from '@playwright/test';
import { restoreSession } from './helpers/login';

/**
 * Students page E2E — runs WITH storageState.
 *
 * Covers:
 *  - Page renders with "Student Directory" h1 and search input
 *  - Search filters the displayed student list
 *  - Clearing the search restores full list
 *  - Stats cards (total student count) are visible
 *  - Import / toolbar buttons are visible for admin
 *
 * The DB has 110 students (10 static + 100 generated). Pagination is 25/page.
 * Generated names come first (IDs STU-001 to STU-100), static Omani names
 * follow (STU-2025OM001–010).  Tests avoid hard-coding specific student names
 * that may not appear on page 1; instead they assert on the search input's
 * own behavior (placeholder, value, clearing) and on visible row count changes.
 */

test.describe('Students page', () => {
  test.beforeEach(async ({ page }) => {
    await restoreSession(page);
    await page.goto('/students');
    await expect(page).not.toHaveURL(/\/login/);
    // Wait for the student table to render — it loads from the mock data store
    await page.waitForSelector('table', { timeout: 12_000 });
  });

  test('renders the page heading and search input', async ({ page }) => {
    // The page h1 is "Student Directory"
    await expect(
      page.getByRole('heading', { name: /student directory/i }).first()
    ).toBeVisible();
    // Placeholder starts with "Search by student name"
    await expect(
      page.getByPlaceholder(/search by student/i).first()
    ).toBeVisible();
  });

  test('student table has visible rows', async ({ page }) => {
    // The mock data in server.ts provides at least 10 students
    const rows = page.locator('tbody tr');
    await expect(rows.first()).toBeVisible({ timeout: 10_000 });
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
  });

  test('search input filters the student list', async ({ page }) => {
    // First count the baseline rows (should be PAGE_SIZE = 25 or less)
    const rows = page.locator('tbody tr');
    await expect(rows.first()).toBeVisible({ timeout: 10_000 });

    const searchInput = page.getByPlaceholder(/search by student/i).first();

    // Search for a string that matches very few students
    // Using a long, unique string that won't match any student name
    await searchInput.fill('zzz-no-match-xyz');
    await page.waitForTimeout(600); // debounce

    // After filtering with a non-matching term, "No students found" appears
    await expect(page.getByText(/no students found/i).first()).toBeVisible({ timeout: 8_000 });
  });

  test('clearing the search restores the full list', async ({ page }) => {
    // Wait for the table to load first
    await expect(page.locator('tbody tr').first()).toBeVisible({ timeout: 10_000 });

    // Get the name of the first student in the table dynamically
    const firstRowText = await page.locator('tbody tr').first().locator('td').nth(1).innerText();
    const studentName = firstRowText.split('\n')[0].trim();

    const searchInput = page.getByPlaceholder(/search by student/i).first();

    // 1. Filter with a non-matching term → empty state
    await searchInput.fill('zzz-no-match-xyz');
    await page.waitForTimeout(600);
    await expect(page.getByText(/no students found/i).first()).toBeVisible({ timeout: 8_000 });

    // 2. Clear → rows come back
    await searchInput.fill('');
    await page.waitForTimeout(600);

    // Wait until there are multiple tbody rows (skips AnimatePresence exit-animation
    // period where the empty-state row is still in the DOM but invisible)
    await page.waitForFunction(
      () => document.querySelectorAll('tbody tr').length > 1,
      { timeout: 10_000 }
    );

    // 3. Expect the dynamically captured student to be visible again
    await expect(page.getByText(studentName).first()).toBeVisible({ timeout: 6_000 });
  });

  test('Import button is visible on the Students page toolbar', async ({ page }) => {
    // The Students toolbar always shows an "Import" button for bulk uploads
    await expect(
      page.getByRole('button', { name: /import/i }).first()
    ).toBeVisible();
  });

  test('stat cards showing student counts are rendered', async ({ page }) => {
    // The Students page renders metric cards at the top with total/active counts
    // At least one card with a numeric value should be visible
    const cards = page.locator('[class*="card"], [class*="Card"]').filter({
      hasText: /\d+/,
    });
    await expect(cards.first()).toBeVisible({ timeout: 8_000 });
  });
});
