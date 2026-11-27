const { chromium } = require('playwright');
(async () => {
  const proxy = process.env.HTTPS_PROXY || process.env.https_proxy;
  const b = await chromium.launch(proxy ? { proxy: { server: proxy, bypass: 'localhost,127.0.0.1' } } : {});
  const G = process.argv[2];
  const shots = [
    ['n_home.png', '앱을 열면 바로<br>오늘의 뉴스가 보여요', 'screenshot-1.png'],
    ['n_latest.png', '7개 언론사 최신 뉴스<br>출처·발행 일시 그대로', 'screenshot-2.png'],
    ['n_news.png', '관심 키워드 기사만<br>골라서 알려드려요', 'screenshot-3.png'],
    ['n_contact.png', '개인정보 수집 없이<br>문의는 언제든 편하게', 'screenshot-4.png'],
  ];
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  for (const [img, t, out] of shots) {
    await p.goto(`http://localhost:8765/../frame.html?t=${encodeURIComponent(t)}&i=${img}`.replace('/../', '/'), { waitUntil: 'networkidle' });
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(500);
    await p.screenshot({ path: `${G}/${out}` });
  }
  const f = await b.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
  await f.goto('http://localhost:8765/feature.html', { waitUntil: 'networkidle' });
  await f.evaluate(() => document.fonts.ready); await f.waitForTimeout(500);
  await f.screenshot({ path: `${G}/feature-graphic.png` });
  await b.close();
})();
