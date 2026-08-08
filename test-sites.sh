#!/bin/bash

echo "🔍 Testing Four Schmucks Site Files..."
echo "======================================"

# Check if all required HTML files exist
required_files=("index.html" "lifestyle.html" "plumbing.html" "brewing.html" "consulting.html" "stonks.html" "rickroll.html" "mirage.html")

echo ""
echo "📁 Checking HTML files:"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file - Found"
        
        # Check if file has proper HTML structure
        if grep -q "<!DOCTYPE html>" "$file" && grep -q "</html>" "$file"; then
            echo "     ✅ Valid HTML structure"
        else
            echo "     ❌ Invalid HTML structure"
        fi
        
        # Check file size
        size=$(wc -c < "$file")
        echo "     📏 File size: ${size} bytes"
        
    else
        echo "  ❌ $file - Missing!"
    fi
done

echo ""
echo "🖼️  Checking logo directory:"
if [ -d "logos" ]; then
    echo "  ✅ logos/ directory exists"
    logo_count=$(ls logos/ | wc -l)
    echo "     📊 Logo files: $logo_count"
    ls -la logos/
else
    echo "  ❌ logos/ directory missing!"
fi

echo ""
echo "☁️  Checking CloudFormation template:"
if [ -f "cloudformation.yaml" ]; then
    echo "  ✅ cloudformation.yaml - Found"
    
    # Check if Lambda@Edge function is defined
    if grep -q "SubdomainRoutingFunction" "cloudformation.yaml"; then
        echo "     ✅ Lambda@Edge routing function defined"
    else
        echo "     ❌ Lambda@Edge routing function missing"
    fi
    
    # Check subdomain mappings
    subdomains=("lifestyle" "plumbing" "poop" "brewing" "consulting" "stonks" "rickroll" "mirage")
    for subdomain in "${subdomains[@]}"; do
        if grep -q "$subdomain" "cloudformation.yaml"; then
            echo "     ✅ $subdomain subdomain configured"
        else
            echo "     ❌ $subdomain subdomain missing from config"
        fi
    done
else
    echo "  ❌ cloudformation.yaml - Missing!"
fi

echo ""
echo "🚀 Checking deployment script:"
if [ -f "deploy.sh" ]; then
    echo "  ✅ deploy.sh - Found"
    if [ -x "deploy.sh" ]; then
        echo "     ✅ Script is executable"
    else
        echo "     ❌ Script is not executable (run: chmod +x deploy.sh)"
    fi
else
    echo "  ❌ deploy.sh - Missing!"
fi

echo ""
echo "📋 Summary:"
echo "==========="

missing_files=0
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -eq 0 ]; then
    echo "🎉 All required files are present!"
    echo "✅ Ready for deployment"
else
    echo "⚠️  Missing $missing_files required file(s)"
    echo "❌ Please fix missing files before deployment"
fi

echo ""
echo "🔧 To deploy, run:"
echo "   DOMAIN_NAME=yourdomain.com BUCKET_NAME=your-bucket ./deploy.sh" 