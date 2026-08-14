/* ==========================================================================
   Social share card generator
   --------------------------------------------------------------------------
   Renders images/card-<key>.png at 1200x630, one per brand.

   Why render rather than generate: these cards are mostly TEXT — the brand
   name, the tagline, the subdomain. Image models still can't be trusted to
   spell those exactly, and the cards need the real accent colours and the
   real logo. Rendering from HTML is pixel-exact and reproducible.

   The output PNGs are committed, so this only needs re-running when a brand
   is added or a tagline changes. It is NOT part of the deploy — tools/ is
   excluded from the S3 sync.

     npm i playwright && node tools/make-og-cards.mjs

   Typography lives here rather than in assets/brands.js on purpose: the
   shipped registry drives nav and links, and shouldn't carry build-time-only
   font metadata.
   ========================================================================== */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// Resolve playwright from the project, or from an explicit path if it lives
// elsewhere on this machine:  PLAYWRIGHT_PATH=/abs/path/to/playwright node ...
let chromium;
for (const spec of [process.env.PLAYWRIGHT_PATH, 'playwright'].filter(Boolean)) {
  try { ({ chromium } = await import(spec)); break; } catch { /* try next */ }
}
if (!chromium) {
  console.error('playwright not found. Run:  npm i playwright');
  console.error('(or set PLAYWRIGHT_PATH to an existing install)');
  process.exit(1);
}

// Pull the registry out of assets/brands.js without importing it as a module
// (it assigns to `window`, which doesn't exist in Node).
const registrySrc = readFileSync(join(ROOT, 'assets/brands.js'), 'utf8');
const registry = new Function(
  'window',
  registrySrc + '\nreturn window.SCHMUCK_BRANDS;'
)({});

// Display face per brand, mirroring each page's --font-display.
const TYPE = {
  index:      { family: 'Space Grotesk',        spec: 'Space+Grotesk:wght@500;700' },
  lifestyle:  { family: 'Fraunces',             spec: 'Fraunces:opsz,wght@9..144,600;9..144,700' },
  plumbing:   { family: 'Archivo',              spec: 'Archivo:wght@600;800' },
  brewing:    { family: 'Bricolage Grotesque',  spec: 'Bricolage+Grotesque:wght@600;800' },
  consulting: { family: 'Inter Tight',          spec: 'Inter+Tight:wght@500;700' },
  stonks:     { family: 'JetBrains Mono',       spec: 'JetBrains+Mono:wght@500;700' },
  mirage:     { family: 'Space Grotesk',        spec: 'Space+Grotesk:wght@500;700' },
  launder:    { family: 'Libre Baskerville',    spec: 'Libre+Baskerville:wght@400;700' },
  rickroll:   { family: 'Space Grotesk',        spec: 'Space+Grotesk:wght@500;700' }
};

const SECONDARY = {
  index: '#22d3ee', lifestyle: '#e8b4b8', plumbing: '#f97316', brewing: '#fcd34d',
  consulting: '#cbd5e1', stonks: '#fbbf24', mirage: '#22d3ee', launder: '#d6b16a',
  rickroll: '#ffd700'
};

// The holding company isn't a subsidiary, so it isn't in the registry.
const cards = [
  {
    key: 'index',
    name: 'Four Schmucks',
    eyebrow: 'Diversified Global Holdings',
    tagline: 'Eight subsidiaries. One holding company. One logo.',
    sub: 'www',
    accent: '#6366f1'
  },
  ...registry.map(b => ({
    key: b.key,
    name: b.name.replace(/^Four Schmucks ?/, '') || 'Four Schmucks',
    eyebrow: 'Four Schmucks',
    tagline: b.tagline,
    sub: b.sub,
    accent: b.accent
  }))
];

const logoDataUri =
  'data:image/png;base64,' +
  readFileSync(join(ROOT, 'logos/four_schmucks_curling.png')).toString('base64');

function html(c) {
  const t = TYPE[c.key];
  const a2 = SECONDARY[c.key];
  return `<!DOCTYPE html><html><head><meta charset="utf-8">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=${t.spec}&display=block">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body {
    width:1200px; height:630px; overflow:hidden;
    font-family:'Inter',system-ui,sans-serif; color:#e8eaf2;
    background:
      radial-gradient(ellipse 65% 60% at 18% 15%, ${c.accent}66, transparent 62%),
      radial-gradient(ellipse 55% 55% at 88% 88%, ${a2}44, transparent 58%),
      linear-gradient(160deg,#0d0f16,#08090d 65%);
    position:relative;
  }
  /* same grain the site heroes use, so cards feel of a piece with the pages */
  body::after {
    content:''; position:absolute; inset:0; opacity:.3; pointer-events:none;
    background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='140' height='140'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3'/%3E%3C/filter%3E%3Crect width='140' height='140' filter='url(%23n)' opacity='.4'/%3E%3C/svg%3E");
  }
  .card { position:relative; z-index:1; height:100%; padding:72px 80px; display:flex; flex-direction:column; }
  .top { display:flex; align-items:center; gap:16px; }
  .top img { height:64px; width:auto; filter:drop-shadow(0 0 14px ${c.accent}88); }
  .top span { font-size:20px; font-weight:600; letter-spacing:.16em; text-transform:uppercase; color:${a2}; }
  .mid { margin-top:auto; }
  h1 {
    font-family:'${t.family}','Space Grotesk',sans-serif; font-weight:700;
    font-size:${c.name.length > 14 ? 84 : 104}px; line-height:1;
    letter-spacing:-.035em; margin-bottom:22px;
    background:linear-gradient(100deg,#ffffff 25%,${c.accent} 72%,${a2} 100%);
    -webkit-background-clip:text; background-clip:text; color:transparent;
    padding-bottom:.06em;
  }
  p { font-size:31px; line-height:1.35; color:#b9c0d2; max-width:900px; }
  .rule { height:5px; width:110px; border-radius:4px; margin:44px 0 22px;
          background:linear-gradient(90deg,${c.accent},${a2}); }
  .url { font-size:23px; letter-spacing:.05em; color:#79809a; }
</style></head><body>
  <div class="card">
    <div class="top"><img src="${logoDataUri}" alt=""><span>${c.eyebrow}</span></div>
    <div class="mid">
      <h1>${c.name}</h1>
      <p>${c.tagline}</p>
      <div class="rule"></div>
      <div class="url">${c.sub}.fourschmucks.com</div>
    </div>
  </div>
</body></html>`;
}

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
const page = await ctx.newPage();

for (const c of cards) {
  await page.setContent(html(c), { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);
  // JPEG, not PNG: these are full-bleed gradients with grain, so PNG lands
  // around 1.1MB each while JPEG holds up at ~10% of that. Every social
  // scraper handles JPEG; WebP support across them is still patchy.
  const out = join(ROOT, `images/card-${c.key}.jpg`);
  await page.screenshot({ path: out, type: 'jpeg', quality: 88 });
  console.log(`  wrote images/card-${c.key}.jpg`);
}

await browser.close();
console.log(`\n${cards.length} social cards rendered at 1200x630.`);
