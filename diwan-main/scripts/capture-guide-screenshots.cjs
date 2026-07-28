/**
 * Guide Screenshot Capture Script
 * Captures all screenshots referenced by User Guide content blocks.
 *
 * Usage:
 *   node scripts/capture-guide-screenshots.cjs
 *
 * Prerequisites:
 *   npx playwright install chromium
 *   Dev server running at http://localhost:3000
 */

const { chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const OUT = path.join(__dirname, '..', 'public', 'guide-screenshots');
const EMAIL = 'educationleadershipexpo@gmail.com';
const PASS  = 'admin123';

const DESKTOP = { width: 1280, height: 800 };
const MOBILE  = { width: 390, height: 844 };

async function login(page) {
  await page.goto(`${BASE_URL}/login`);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(1200);

  // Step 1: click the Staff portal card (first card, labelled "Staff Portal")
  // The portal buttons are <button> elements on the portal-selection step
  const staffBtn = page.locator('button').filter({ hasText: /staff/i }).first();
  await staffBtn.click();
  await page.waitForTimeout(800);

  // Step 2: fill email (type=text, id=email) and password, then submit
  await page.fill('#email', EMAIL);
  await page.fill('#password', PASS);
  await page.click('button[type="submit"]');
  await page.waitForURL(`${BASE_URL}/**`, { timeout: 20000 });
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(1500);
  // Dismiss any notification popups
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
  console.log('✅  Logged in');
}

async function snap(page, filename, url, waitMs = 800) {
  try {
    await page.goto(`${BASE_URL}${url}`);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(waitMs);
    // Dismiss any notification / modal that might be open
    await page.keyboard.press('Escape');
    await page.waitForTimeout(200);
    const fp = path.join(OUT, filename);
    await page.screenshot({ path: fp });
    console.log(`📸  ${filename}`);
  } catch (e) {
    console.warn(`⚠️   ${filename} — ${e.message.split('\n')[0]}`);
  }
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });

  // ── Desktop browser ────────────────────────────────────────────────────
  const browser = await chromium.launch({
    headless: false,   // Edge requires non-headless on some systems
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const ctx     = await browser.newContext({ viewport: DESKTOP });
  const page    = await ctx.newPage();
  await login(page);

  // Login / shared
  await snap(page, 'login-portal.png',           '/login',                      600);

  // Admin / Super Admin
  await snap(page, 'admin-dashboard.png',        '/dashboard',                  1000);
  await snap(page, 'admin-students.png',         '/students',                   800);
  await snap(page, 'admin-users.png',            '/settings/users',             800);
  await snap(page, 'admin-system-settings.png',  '/settings',                   800);
  await snap(page, 'admin-timetable.png',        '/academics/timetable',        800);

  // Teacher
  await snap(page, 'teacher-dashboard.png',      '/dashboard',                  800);
  await snap(page, 'teacher-attendance.png',     '/attendance',                 800);
  await snap(page, 'teacher-gradebook.png',      '/academics/gradebook',        800);

  // Parent (views as admin — best approximation available)
  await snap(page, 'parent-dashboard.png',       '/dashboard',                  800);
  await snap(page, 'parent-fees.png',            '/finance/fees',               800);

  // Student
  await snap(page, 'student-dashboard.png',      '/dashboard',                  800);
  await snap(page, 'student-timetable.png',      '/academics/timetable',        800);

  // Finance / Accountant
  await snap(page, 'finance-dashboard.png',      '/finance/overview',           800);
  await snap(page, 'finance-fees.png',           '/finance/fees',               800);

  // HR
  await snap(page, 'hr-staff.png',              '/hr/staff',                   800);
  await snap(page, 'hr-leave.png',              '/hr/leave',                   800);

  // Transport
  await snap(page, 'transport-routes.png',       '/transport/routes',           800);
  await snap(page, 'transport-vehicles.png',     '/transport/vehicles',         800);

  // Library
  await snap(page, 'library-books.png',          '/library',                    800);
  await snap(page, 'library-issues.png',         '/library',                    800);

  await ctx.close();

  // ── Mobile browser (for mobile app guide screenshots) ─────────────────
  // Mobile context uses the same browser instance
  const mCtx  = await browser.newContext({ viewport: MOBILE, isMobile: true, hasTouch: true });
  const mPage = await mCtx.newPage();
  await login(mPage);

  await snap(mPage, 'mobile-login.png',     '/login',      600);
  await snap(mPage, 'mobile-dashboard.png', '/dashboard',  1000);

  await mCtx.close();
  await browser.close();

  const count = fs.readdirSync(OUT).filter(f => f.endsWith('.png')).length;
  console.log(`\n✅  Done — ${count} screenshots saved to public/guide-screenshots/`);
}

main().catch(e => { console.error(e); process.exit(1); });
