import { chromium } from 'playwright';

async function run() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  page.on('console', msg => {
    console.log(`[BROWSER CONSOLE] [${msg.type()}] ${msg.text()}`);
  });
  
  page.on('pageerror', err => {
    console.log(`[BROWSER ERROR] ${err.stack || err.message}`);
  });

  console.log("Navigating to http://localhost:3001...");
  try {
    await page.goto('http://localhost:3001', { timeout: 10000 });
    console.log("Navigated. Waiting 5 seconds...");
    await page.waitForTimeout(5000);
    
    const screenshotPath = 'C:\\Users\\abish\\.gemini\\antigravity-ide\\brain\\36b13e08-0947-4867-acc3-6cc3011ed4aa\\scratch\\screenshot.png';
    await page.screenshot({ path: screenshotPath });
    console.log(`Screenshot saved to ${screenshotPath}`);
  } catch (error) {
    console.error("Navigation/Test failed:", error);
  } finally {
    await browser.close();
  }
}

run();
