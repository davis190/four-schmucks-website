#!/bin/bash
#
# Pre-deploy validation. Run from the repo root.
#
# buildspec.yml runs this in pre_build as the deploy gate, so it MUST exit non-zero
# when something is wrong — an earlier version only printed warnings and always
# exited 0, which meant a broken site would deploy anyway.

echo "🔍 Testing Four Schmucks Site Files..."
echo "======================================"

failures=0

fail() {
    echo "     ❌ $1"
    failures=$((failures + 1))
}

# Every page that must exist and be deployable.
required_files=("index.html" "404.html" "lifestyle.html" "plumbing.html" "brewing.html" "consulting.html" "stonks.html" "rickroll.html" "mirage.html")

# Shared assets the pages depend on. A page that loses its stylesheet still renders,
# just as unstyled markup, so the DOCTYPE check alone would not catch it.
required_assets=("assets/site.css" "assets/site.js" "assets/brands.js")

echo ""
echo "📁 Checking HTML files:"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file - Found"

        if grep -qi "<!DOCTYPE html>" "$file" && grep -q "</html>" "$file"; then
            echo "     ✅ Valid HTML structure"
        else
            fail "$file: missing DOCTYPE or closing </html>"
        fi

        if grep -q 'href="/assets/site.css"' "$file"; then
            echo "     ✅ Links the shared stylesheet"
        else
            fail "$file: does not link /assets/site.css"
        fi

        if grep -q 'src="/assets/brands.js"' "$file" && grep -q 'src="/assets/site.js"' "$file"; then
            echo "     ✅ Loads brands.js and site.js"
        else
            fail "$file: does not load both /assets/brands.js and /assets/site.js"
        fi

        # The redesign replaced every hotlinked stock photo with CSS gradient tiles.
        if grep -q "unsplash" "$file"; then
            fail "$file: still references unsplash.com"
        fi

        echo "     📏 File size: $(wc -c < "$file") bytes"
    else
        echo "  ❌ $file - Missing!"
        failures=$((failures + 1))
    fi
done

echo ""
echo "🎨 Checking shared assets:"
for asset in "${required_assets[@]}"; do
    if [ -f "$asset" ]; then
        echo "  ✅ $asset - Found ($(wc -c < "$asset") bytes)"
    else
        echo "  ❌ $asset - Missing!"
        failures=$((failures + 1))
    fi
done

# Every brand in the registry needs a page to point at. This is the check that catches
# a service line added to brands.js without its .html file being created.
if [ -f "assets/brands.js" ]; then
    echo ""
    echo "🔗 Checking brand registry against pages:"
    for page in $(grep -oE "file: '[^']+'" assets/brands.js | sed "s/file: '//;s/'//"); do
        if [ -f "$page" ]; then
            echo "  ✅ $page - registered and present"
        else
            echo "  ❌ $page - listed in brands.js but the file is missing!"
            failures=$((failures + 1))
        fi
    done
fi

echo ""
echo "🖼️  Checking image directories:"
if [ -d "logos" ]; then
    echo "  ✅ logos/ exists ($(ls logos/ | wc -l | tr -d ' ') files)"
else
    echo "  ❌ logos/ directory missing!"
    failures=$((failures + 1))
fi

# Social cards are NOT optional: every page's og:image points at one, and a 404 there
# means broken link previews everywhere the site gets shared.
for key in index lifestyle plumbing brewing consulting stonks mirage rickroll; do
    if [ -f "images/card-${key}.jpg" ]; then
        echo "  ✅ images/card-${key}.jpg"
    else
        fail "images/card-${key}.jpg missing — run: node tools/make-og-cards.mjs"
    fi
done

# Favicons are referenced by every page.
for icon in favicon.ico favicon-32.png apple-touch-icon.png; do
    [ -f "$icon" ] && echo "  ✅ $icon" || fail "$icon missing (see images/PROMPTS.md)"
done

# Heroes and product photos ARE optional — heroes fall back to the mesh gradient and
# product tiles fall back to the emoji tile (the <img> removes itself on error).
missing_heroes=0
for brand in index lifestyle plumbing brewing consulting stonks mirage; do
    [ -f "images/hero-${brand}.webp" ] || missing_heroes=$((missing_heroes + 1))
done
[ "$missing_heroes" -eq 0 ] \
    && echo "  ✅ all 7 hero images present" \
    || echo "  ℹ️  $missing_heroes/7 heroes not yet generated — pages fall back to gradients"

missing_products=0
for slug in brew-ipa brew-golden brew-stout brew-wheat brew-pale brew-sour \
            merch-tee merch-hoodie merch-glass merch-cap \
            life-wardrobe life-travel life-home life-candle life-vessel life-scarf life-chair; do
    [ -f "images/${slug}.webp" ] || missing_products=$((missing_products + 1))
done
[ "$missing_products" -eq 0 ] \
    && echo "  ✅ all 17 product images present" \
    || echo "  ℹ️  $missing_products/17 product photos not yet generated — tiles fall back to emoji"

# images/ root is deployed verbatim, so only optimised output belongs there: .webp
# for heroes and tiles, card-*.jpg for the social cards. A raw generated PNG left
# here would ship at full size — 44MB of them nearly did. This is a hard failure,
# not a warning, because the sync would otherwise push them silently.
for f in images/*.png images/*.jpg images/*.jpeg images/*.PNG images/*.JPG; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in card-*.jpg) continue ;; esac
    kb=$(( $(wc -c < "$f") / 1024 ))
    fail "$f (${kb}KB) is an unoptimised source in images/ root — run ./tools/optimize-images.sh"
done

echo ""
echo "☁️  Checking CloudFormation template:"
if [ -f "cloudformation.yaml" ]; then
    echo "  ✅ cloudformation.yaml - Found"

    if grep -q "SubdomainRoutingFunction" "cloudformation.yaml"; then
        echo "     ✅ Lambda@Edge routing function defined"
    else
        fail "cloudformation.yaml: SubdomainRoutingFunction not defined"
    fi

    # Each subdomain needs an entry in the Lambda's subdomainMap, an ACM SAN and a
    # CloudFront alias. Checking for the quoted map key specifically, rather than a
    # bare substring anywhere in the file, so a stray mention in a comment can't pass.
    subdomains=("lifestyle" "plumbing" "poop" "brewing" "consulting" "stonks" "rickroll" "mirage")
    for subdomain in "${subdomains[@]}"; do
        if grep -q "'${subdomain}':" "cloudformation.yaml" && grep -q "${subdomain}\.\${DomainName}" "cloudformation.yaml"; then
            echo "     ✅ $subdomain routed and aliased"
        else
            fail "$subdomain: missing from subdomainMap and/or Aliases in cloudformation.yaml"
        fi
    done

    if grep -q "CustomErrorResponses" "cloudformation.yaml"; then
        echo "     ✅ Custom error responses configured"
    else
        fail "cloudformation.yaml: no CustomErrorResponses (404s return raw S3 XML)"
    fi
else
    echo "  ❌ cloudformation.yaml - Missing!"
    failures=$((failures + 1))
fi

echo ""
echo "🚀 Checking deployment script:"
if [ -f "deploy.sh" ] && [ -x "deploy.sh" ]; then
    echo "  ✅ deploy.sh - Found and executable"
else
    echo "  ❌ deploy.sh - missing or not executable (run: chmod +x deploy.sh)"
    failures=$((failures + 1))
fi

echo ""
echo "📋 Summary:"
echo "==========="

if [ "$failures" -eq 0 ]; then
    echo "🎉 All checks passed — ready for deployment."
    echo ""
    echo "🔧 To deploy, run:"
    echo "   DOMAIN_NAME=fourschmucks.com BUCKET_NAME=fourschmucks-static-site ./deploy.sh"
    exit 0
else
    echo "❌ $failures check(s) failed. Fix these before deploying."
    exit 1
fi
