#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

(async () => {
  const url = process.env.SCREENSHOT_URL || 'http://127.0.0.1:4001';
  const output = process.env.SCREENSHOT_PATH || path.join('screenshots', 'home-empty.png');
  const waitSelector = process.env.SCREENSHOT_WAIT_SELECTOR;
  const delayMs = parseInt(process.env.SCREENSHOT_DELAY_MS || '2000', 10);
  const postScript = process.env.SCREENSHOT_POST_JS;

  const outputDir = path.dirname(output);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const puppeteer = require('puppeteer');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
    if (waitSelector) {
      await page.waitForSelector(waitSelector, { timeout: 60000 }).catch(() => {});
    }
    if (postScript) {
      await page.evaluate((code) => {
        try {
          // eslint-disable-next-line no-eval
          const result = eval(code);
          return result;
        } catch (error) {
          console.error('Failed to execute post script', error);
        }
        return null;
      }, postScript);
    }
    if (delayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
    await page.screenshot({ path: output, fullPage: true });
    console.log(`Saved homepage screenshot to ${output}`);
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error('Failed to capture homepage screenshot:', error);
  process.exit(1);
});
