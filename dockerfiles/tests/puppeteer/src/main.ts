import puppeteer from "puppeteer";
import fs from "fs";

async function main() {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--disable-accelerated-2d-canvas",
      "--no-first-run",
      "--no-zygote",
      "--disable-gpu",
    ],
  });
  const page = await browser.newPage();
  await page.goto("https://www.google.com/search?q=puppeteer", {
    waitUntil: "networkidle2",
  });
  fs.mkdirSync("screenshots", { recursive: true });
  await page.screenshot({ path: "screenshots/screenshot.png" });
  await browser.close();
}

(async () => {
  await main();
})();
