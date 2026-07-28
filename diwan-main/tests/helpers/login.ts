import { Page } from '@playwright/test';

/**
 * Shared E2E login helpers.
 *
 * selectPortal   — clicks a portal card on the portal-selection step.
 * loginAs        — full login flow: portal → fill credentials → submit → wait for dashboard.
 * fillLoginForm  — fills email + password after a portal is already selected (does not submit).
 */

export type Portal = 'Staff Portal' | 'Student Portal' | 'Parent Portal';

/** Click a portal card and wait for the login form to appear. */
export async function selectPortal(page: Page, portal: Portal) {
  await page.waitForLoadState('networkidle');
  const card = page.getByText(portal).first();
  await card.waitFor({ state: 'visible' });
  // Buffer to ensure React event listeners are fully bound
  await page.waitForTimeout(500);
  await card.click();

  try {
    // Wait for the login form input to be visible
    await page.getByLabel('Email or Login ID').waitFor({ state: 'visible', timeout: 3000 });
  } catch (err) {
    // If the click was lost before hydration, click again
    await card.click({ force: true });
    await page.getByLabel('Email or Login ID').waitFor({ state: 'visible', timeout: 5000 });
  }
}

/** Fill login credentials (call after selectPortal). */
export async function fillLoginForm(page: Page, email: string, password: string) {
  await page.getByLabel('Email or Login ID').fill(email);
  await page.locator('input#password').fill(password);
}

/** Full login flow → waits until URL is no longer /login. */
export async function loginAs(
  page: Page,
  portal: Portal,
  email: string,
  password: string,
  timeout = 20_000,
) {
  await page.goto('/');
  await selectPortal(page, portal);
  await fillLoginForm(page, email, password);
  await page.getByRole('button', { name: /sign in to/i }).click();
  await page.waitForURL((url) => !url.pathname.startsWith('/login'), { timeout });
}

import * as fs from 'fs';
import * as path from 'path';

/** Restores sessionStorage (sd_token) from setup auth stage. */
export async function restoreSession(page: Page) {
  try {
    const sessionPath = path.resolve('tests/setup/.auth/session.json');
    if (fs.existsSync(sessionPath)) {
      const sessionData = JSON.parse(fs.readFileSync(sessionPath, 'utf8'));
      await page.addInitScript((data) => {
        for (const [key, value] of Object.entries(data)) {
          window.sessionStorage.setItem(key, value as string);
        }
      }, sessionData);
    }
  } catch (err) {
    console.error('Failed to restore sessionStorage:', err);
  }
}

