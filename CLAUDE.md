# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A satirical multi-brand static website ("Four Schmucks") deployed to AWS as a single S3 bucket + CloudFront distribution, with subdomain-based routing to different HTML pages. There is no build step, no framework, and no package.json — every page is a hand-written, self-contained HTML file with inline `<style>` and `<script>` blocks.

## Commands

- `./test-sites.sh` — validates that all required HTML files exist, have basic valid structure (`<!DOCTYPE html>`/`</html>`), and that `cloudformation.yaml` defines the Lambda@Edge routing function and every subdomain. This is the closest thing to a test suite; run it before deploying.
- `DOMAIN_NAME=fourschmucks.com BUCKET_NAME=fourschmucks-static-site ./deploy.sh` — deploys/updates the CloudFormation stack (`fourschmucks-site`), syncs all files (including `logos/`) to S3, and invalidates the CloudFront cache for every page. Requires AWS CLI configured with permissions for S3, CloudFront, ACM, Route53, Lambda, and IAM. `deploy.sh`, `cloudformation.yaml`, `pipeline.yaml`, and `buildspec.yml` are excluded from the S3 sync (they're infra, not site content).
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

## Page conventions

Each HTML page is fully self-contained: inline CSS in a `<style>` block, inline JS if needed, no shared/external stylesheet. Pages share a similar structure (fixed header/nav, hero section with background image from `/logos/`, content sections) but each duplicates its own styles rather than importing a common one — follow this existing pattern rather than introducing a build step or shared asset pipeline unless explicitly asked to. Google Analytics (`gtag.js`) and Open Graph/Twitter meta tags are embedded per-page.
