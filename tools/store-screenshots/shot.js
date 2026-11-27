const { chromium } = require('playwright');
const fs = require('fs');
const S = process.argv[2], out = process.argv[3], steps = JSON.parse(process.argv[4] || '[]');
(async () => {
  const proxy = process.env.HTTPS_PROXY || process.env.https_proxy;
  const browser = await chromium.launch(proxy ? { proxy: { server: proxy, bypass: 'localhost,127.0.0.1' } } : {});
  const ctx = await browser.newContext({ viewport: { width: 360, height: parseInt(process.env.VH || '640') }, deviceScaleFactor: 3, timezoneId: 'Asia/Seoul', locale: 'ko-KR', ignoreHTTPSErrors: true });
  const seed = JSON.parse(fs.readFileSync(S + '/seed_ls.json', 'utf8'));
  await ctx.addInitScript(s => { if (!sessionStorage.getItem('seeded')) { for (const [k, v] of Object.entries(s)) localStorage.setItem(k, v); sessionStorage.setItem('seeded', '1'); } }, seed);
  const page = await ctx.newPage();
  page.on('console', m => { if (m.type() === 'error') console.log('console:', m.text().slice(0, 200)); });
  await page.goto('http://localhost:8765/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(6000);
  for (const st of steps) {
    if (st.click) await page.mouse.click(st.click[0], st.click[1]);
    if (st.type) await page.keyboard.type(st.type);
    if (st.wheel) { await page.mouse.move(180, 300); await page.mouse.wheel(0, st.wheel); }
    await page.waitForTimeout(st.wait || 2500);
  }
  await page.screenshot({ path: out });
  await browser.close();
})();
