# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A satirical multi-brand static website ("Four Schmucks") deployed to AWS as a single S3 bucket + CloudFront distribution, with subdomain-based routing to different HTML pages. There is no build step, no framework, and no package.json — every page is a hand-written HTML file that links one shared stylesheet (`assets/site.css`) and re-themes it with a small inline `<style>` block.

## Commands

- `./test-sites.sh` — the deploy gate. Validates that every required HTML file exists and has valid structure, that each page links `/assets/site.css` and loads both JS files, that no page has regressed to hotlinking Unsplash, that every brand in `assets/brands.js` has a corresponding page, and that `cloudformation.yaml` defines the routing function, error responses, and every subdomain in both `subdomainMap` and `Aliases`. **It exits non-zero on failure** — `buildspec.yml` runs it in `pre_build`, so a failure stops the deploy. Missing hero images are reported as a note, not a failure.
- `DOMAIN_NAME=fourschmucks.com BUCKET_NAME=fourschmucks-static-site ./deploy.sh` — deploys/updates the CloudFormation stack (`fourschmucks-site`), syncs the site to S3, and invalidates the CloudFront cache with a single `/*`. Requires AWS CLI configured with permissions for S3, CloudFront, ACM, Route53, Lambda, and IAM. The sync is recursive with a deny-list (infra scripts, `pipeline.yaml`, `buildspec.yml`, and the repo's `.md` docs are excluded), so new asset directories are picked up with no change to `deploy.sh`.
- No linting, testing framework, or dependency install is needed — these are plain HTML files.
- Pushes to `main` on GitHub (`davis190/four-schmucks-website`) auto-deploy via CodePipeline (`fourschmucks-site-pipeline`) + CodeBuild (`fourschmucks-site-deploy`, driven by `buildspec.yml`), which just runs `test-sites.sh` then `deploy.sh` with `DOMAIN_NAME`/`BUCKET_NAME` set as CodeBuild project env vars. That pipeline itself is defined in `pipeline.yaml` but is a separate stack (`fourschmucks-pipeline`) bootstrapped manually via `aws cloudformation deploy` — it does not self-update, so changes to `pipeline.yaml` need a manual re-deploy of that stack, not just a push.

## Architecture: subdomain routing via Lambda@Edge

All brand pages live in one S3 bucket behind one CloudFront distribution. Routing to the correct HTML file per subdomain happens in a Lambda@Edge function (`SubdomainRoutingFunction`), inlined directly in `cloudformation.yaml`, associated with CloudFront's `viewer-request` event. It must be deployed to `us-east-1` (a hard Lambda@Edge constraint) regardless of the stack's primary region, and can take 5-10 minutes to propagate globally after a deploy.

The subdomain → file mapping (defined identically in the Lambda function code, and documented in `SUBDOMAIN_ROUTING.md`):

| Subdomain | File |
|---|---|
| `www` | `index.html` |
| `lifestyle` | `lifestyle.html` |
| `plumbing` / `poop` | `plumbing.html` |
| `brewing` | `brewing.html` |
| `consulting` | `consulting.html` |
| `stonks` | `stonks.html` |
| `rickroll` | `rickroll.html` |
| `mirage` | `mirage.html` |

When adding a new brand/subdomain page, you must update in lockstep:
1. The new `.html` file at the repo root.
2. `subdomainMap` inside the Lambda function code in `cloudformation.yaml`.
3. The ACM `Certificate.SubjectAlternativeNames` list and `CloudFrontDistribution.Aliases` list in `cloudformation.yaml`.
4. The `required_files` and `subdomains` arrays in `test-sites.sh`.
5. The CloudFront invalidation paths and printed URLs at the end of `deploy.sh`.
6. The routing table in `SUBDOMAIN_ROUTING.md`.
7. The `LambdaRoutingCodeVersion` parameter's default in `cloudformation.yaml` — bump it (e.g. "2" -> "3"). `AWS::Lambda::Version` is immutable and CloudFormation only publishes a new one when a property of that resource changes; without bumping this, CloudFront keeps using the stale Lambda@Edge version and the new subdomain silently falls back to serving the homepage instead of 404ing (this exact bug shipped once already).

The Lambda routing logic only rewrites the URI when the path is `/`, empty, or extensionless and not under `/logos/` — asset requests (e.g. `/logos/foo.png`) pass through untouched.

## Page conventions: one design system, themed per brand

The site shares a single dark design system. **Do not add a build step, a framework, or a second stylesheet.**

```
assets/site.css     the whole design system — layout, chrome, components, motion
assets/site.js      mobile nav toggle, scroll reveal, registry-driven rendering
assets/brands.js    the service-line registry (single source of truth)
images/             deployed assets: hero-*.webp, product *.webp, card-*.jpg
images/src/         heavy generated originals — NOT deployed, gitignored from sync
tools/              asset generators — NOT deployed
logos/              four_schmucks_curling.png — the nav mark
favicon.ico, favicon-32.png, apple-touch-icon.png
```

### Images

Every image is optional and degrades: heroes fall back to their mesh gradient, product
tiles fall back to an emoji tile (the `<img>` carries `onerror="this.remove()"`, revealing
the emoji underneath). Prompts and the full workflow live in `images/PROMPTS.md`.

- **Generated art** (heroes, product shots): drop the raw output anywhere in `images/`
  under the target filename and run `./tools/optimize-images.sh`. It sweeps stray
  originals from `images/` root into `images/src/`, then emits compressed `.webp` —
  heroes capped at 2560px, product tiles at 900px (they render ~350px wide, so that's
  already 2x DPR). Typical reduction is 95–99%: the 25 current images went from 46 MB
  of PNG to 1.4 MB of WebP.
- **`images/` root is deployed verbatim**, so only optimised output belongs there
  (`*.webp` and `card-*.jpg`). `test-sites.sh` **fails the build** on any other image
  file found there — without that guard the sync would silently push full-size PNGs,
  which it nearly did once.
- **Social cards** (`images/card-*.jpg`, 1200×630) are *rendered, not generated*, by
  `node tools/make-og-cards.mjs` — they're mostly text and need exact spelling, exact
  accent colours and the real logo. Requires `npm i playwright`. Re-run after adding a
  brand or changing a tagline. Every page's `og:image`/`twitter:image` points at its own
  card, so a missing one breaks link previews — `test-sites.sh` fails on that.
- **Favicons** are derived from the logo with ImageMagick (see `images/PROMPTS.md`). The
  source is 486×401, so it must be padded square or browsers squash it.

Every page links `/assets/site.css`, then overrides these variables in its own `:root` to become its brand. **Nothing brand-specific belongs in `site.css`:**

```css
:root {
  --accent:       #0ea5e9;   /* primary brand colour */
  --accent-2:     #f97316;   /* secondary — gradients, .tag.alt, eyebrow */
  --glow:         rgba(14,165,233,.35);
  --surface-tint: rgba(14,165,233,.06);
  --font-display: 'Archivo', system-ui, sans-serif;
  --hero-img:     url('/images/hero-plumbing.webp');
}
```

Shared components: `.header`/`.nav`/`.nav-toggle`, `.hero` + `.eyebrow` + `.lede`, `.btn`/`.btn-ghost`, `.wrap`, `.section` (+ `.tinted`/`.raised`), `.section-head` + `.kicker`, `.grid` (+ `.cols-2`/`.cols-4`), `.card` (+ `.person`), `.tile`, `.stat`, `.tag` (+ `.alt`), `.step`, `.quote`, `.avatar`, `.results`, `.fine-print`, `.disclaimer`, `.faq`, `.contact-panel`, `.brand-strip`, `.footer`, `.reveal`.

Beyond the theme variables, each page defines **one bespoke section** in its inline `<style>` — that's what keeps the brands from feeling like recolours of each other (plumbing's Clog Severity Index, brewing's ABV/Regret chart, consulting's Synergy Matrix, stonks' ticker tape, lifestyle's Aspiration Index, mirage's dial). Keep the CSS for it inline on that page.

Hero images are optional: a missing `--hero-img` file simply doesn't paint, and the mesh gradient underneath carries the hero on its own.

Google Analytics (`gtag.js`, `G-701KZR6WCN`), canonical, `theme-color`, favicon and absolute-URL Open Graph/Twitter tags are embedded per-page. Copy voice is deadpan enterprise-speak applied to absurd services; most pages carry a `.fine-print` line undercutting their most confident claim.

## Adding a new service line

1. Append one object to `assets/brands.js`. This is the source of truth — the footer brand strip on every page and the homepage brand grid both render from it, so both update automatically.
2. Create `<key>.html` at the repo root. Copy an existing page, swap the theme block, write one bespoke section. Set `<body data-brand="<key>">` so the brand strip can mark itself current.
3. Add a `<li>` to the `<noscript>` fallback list in `index.html` (the only place the registry is duplicated, so crawlers without JS still see the portfolio).
3b. Add the brand's display font to the `TYPE` map in `tools/make-og-cards.mjs`, then re-run it to render the new social card. Without this the page's `og:image` 404s and `test-sites.sh` fails.
4. `subdomainMap` inside the Lambda function code in `cloudformation.yaml`.
5. `Certificate.SubjectAlternativeNames` **and** `CloudFrontDistribution.Aliases` in `cloudformation.yaml`. Note the cert is an enumerated list, not a wildcard — adding a SAN replaces the certificate and the stack update blocks on new DNS validation. This is the slow, risky step.
6. Bump the `LambdaRoutingCodeVersion` parameter default in `cloudformation.yaml` (e.g. "2" → "3"). `AWS::Lambda::Version` is immutable and CloudFormation only publishes a new one when a property of that resource changes; without bumping this, CloudFront keeps using the stale Lambda@Edge version and the new subdomain silently falls back to serving the homepage instead of 404ing (this exact bug shipped once already).
7. `required_files` and `subdomains` arrays in `test-sites.sh`.
8. The printed URLs at the end of `deploy.sh`, and the routing table in `SUBDOMAIN_ROUTING.md`.

`deploy.sh` needs no other changes — the S3 sync is recursive with a deny-list, and the CloudFront invalidation is a single `/*` wildcard.
