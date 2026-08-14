/* ==========================================================================
   Four Schmucks — service-line registry
   --------------------------------------------------------------------------
   THIS IS THE SINGLE SOURCE OF TRUTH for the brand portfolio.

   To add a service line to the site, append one object here. site.js renders
   the footer brand strip on every page and the brand grid on the homepage
   from this array, so both update everywhere automatically.

   Adding a brand to this file does NOT create the page or the DNS record —
   see the "Adding a new service line" checklist in CLAUDE.md for the full
   lockstep (new .html, Lambda subdomainMap, ACM SANs, CloudFront Aliases,
   LambdaRoutingCodeVersion bump, test-sites.sh arrays).

   Fields:
     key      matches the page filename and <body data-brand="...">
     name     full brand name
     short    label used in the compact footer chips
     sub      subdomain (https://<sub>.fourschmucks.com)
     file     local filename, used when previewing off a local server
     tagline  one line, shown on the homepage card
     accent   the brand's primary hex — keep it in sync with the page's --accent
     icon     single emoji used on the homepage card
   ========================================================================== */

window.SCHMUCK_BRANDS = [
  {
    key: 'lifestyle',
    name: 'Four Schmucks Life',
    short: 'Life',
    sub: 'lifestyle',
    file: 'lifestyle.html',
    tagline: 'Curated objects for people who have run out of problems.',
    accent: '#d4af37',
    icon: '✦'
  },
  {
    key: 'plumbing',
    name: 'Four Schmucks Plumbing',
    short: 'Plumbing',
    sub: 'plumbing',
    file: 'plumbing.html',
    tagline: 'Six continents. One drain snake. Zero judgment.',
    accent: '#0ea5e9',
    icon: '🔧'
  },
  {
    key: 'brewing',
    name: 'Four Schmucks Brewing',
    short: 'Brewing',
    sub: 'brewing',
    file: 'brewing.html',
    tagline: 'Craft beer named by people who peaked at one pun.',
    accent: '#f59e0b',
    icon: '🍺'
  },
  {
    key: 'consulting',
    name: 'Four Schmucks Consulting',
    short: 'Consulting',
    sub: 'consulting',
    file: 'consulting.html',
    tagline: 'We will tell you what you already knew, in a deck.',
    accent: '#3b82f6',
    icon: '📈'
  },
  {
    key: 'stonks',
    name: 'Four Schmucks Stonks',
    short: 'Stonks',
    sub: 'stonks',
    file: 'stonks.html',
    tagline: 'Wealth management powered by Schmuckonomics™.',
    accent: '#22c55e',
    icon: '📊'
  },
  {
    key: 'mirage',
    name: 'Four Schmucks Mirage',
    short: 'Mirage',
    sub: 'mirage',
    file: 'mirage.html',
    tagline: 'AI visibility. AI invisibility. Your call.',
    accent: '#a855f7',
    icon: '🌫'
  },
  {
    key: 'launder',
    name: 'Four Schmucks Fraud & Launder',
    short: 'Fraud & Launder',
    sub: 'launder',
    file: 'launder.html',
    tagline: 'A compliance firm named after its founders. Please stop asking.',
    accent: '#be123c',
    icon: '⚖️'
  },
  {
    key: 'rickroll',
    name: 'Four Schmucks Sponsorship',
    short: 'Sponsorship',
    sub: 'rickroll',
    file: 'rickroll.html',
    tagline: 'Our brand partnerships division. Click it. We dare you.',
    accent: '#ec4899',
    icon: '🎁'
  }
];
