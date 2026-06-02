import { chromium } from 'playwright';
import { mkdir, readdir } from 'fs/promises';
import { join } from 'path';

const ASSETS_DIR = './store-assets';
const OUTPUT_DIR = './store-assets/generated';
const BASE_URL = `file://${process.cwd()}`;

const ASSETS = [
  // Screenshots (1280x800)
  { file: 'screenshot-1.html', name: 'screenshot-1.png', width: 1280, height: 800 },
  { file: 'screenshot-2.html', name: 'screenshot-2.png', width: 1280, height: 800 },
  { file: 'screenshot-3.html', name: 'screenshot-3.png', width: 1280, height: 800 },
  { file: 'screenshot-4.html', name: 'screenshot-4.png', width: 1280, height: 800 },
  // Small promo tile (440x280)
  { file: 'promo-small.html', name: 'promo-small.png', width: 440, height: 280 },
  // Marquee promo tile (1400x560)
  { file: 'promo-large.html', name: 'promo-large.png', width: 1400, height: 560 },
  // Store icon (128x128) - special handling, render from icon.html if exists
];

async function generateAssets() {
  // Ensure output directory exists
  await mkdir(OUTPUT_DIR, { recursive: true });

  // Launch browser
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  console.log('Generating Chrome Web Store assets...\n');

  for (const asset of ASSETS) {
    const inputPath = `${BASE_URL}/${ASSETS_DIR}/${asset.file}`;
    const outputPath = `${OUTPUT_DIR}/${asset.name}`;

    try {
      console.log(`Rendering ${asset.file} (${asset.width}x${asset.height})...`);
      await page.goto(`file://${join(process.cwd(), ASSETS_DIR, asset.file)}`, {
        waitUntil: 'networkidle',
      });

      // Set viewport to exact size
      await page.setViewportSize({ width: asset.width, height: asset.height });

      // Wait for fonts to load
      await page.waitForTimeout(500);

      // Take screenshot without alpha (24-bit PNG)
      await page.screenshot({
        path: outputPath,
        type: 'png',
        omitBackground: false, // White background instead of transparent
      });

      console.log(`  ✓ Saved to ${outputPath}`);
    } catch (error) {
      console.error(`  ✗ Failed: ${error.message}`);
    }
  }

  // Generate store icon (128x128) - render from promo-small.html
  try {
    const iconPath = `${OUTPUT_DIR}/store-icon.png`;
    console.log('\nRendering store-icon.png (128x128)...');

    await page.goto(`file://${join(process.cwd(), ASSETS_DIR, 'icon.html')}`, {
      waitUntil: 'networkidle',
    });
    await page.setViewportSize({ width: 128, height: 128 });
    await page.waitForTimeout(300);

    await page.screenshot({
      path: iconPath,
      type: 'png',
      omitBackground: false,
    });
    console.log(`  ✓ Saved to ${iconPath}`);
  } catch (error) {
    console.log(`  ⚠ No icon.html found, skipping store icon`);
  }

  await browser.close();

  console.log('\n✅ All assets generated in', OUTPUT_DIR);
}

generateAssets().catch(console.error);
