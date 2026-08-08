#!/bin/bash
set -e

# Usage: DOMAIN_NAME=your-domain.com BUCKET_NAME=your-bucket ./deploy.sh

# Cleanup function for failed deployments
cleanup() {
    echo "🧹 Cleaning up on failure..."
    if [ -n "$STACK_NAME" ]; then
        echo "⚠️  Stack may be in a failed state. Check CloudFormation console."
        echo "💡 To delete failed stack: aws cloudformation delete-stack --stack-name $STACK_NAME"
    fi
}

# Note: Cleanup function available for manual use if needed

if [ -z "$DOMAIN_NAME" ] || [ -z "$BUCKET_NAME" ]; then
  echo "DOMAIN_NAME and BUCKET_NAME environment variables must be set."
  exit 1
fi

# Validate domain name format
if [[ "$DOMAIN_NAME" =~ \. ]]; then
  echo "✅ Domain name format looks good: $DOMAIN_NAME"
else
  echo "❌ Invalid domain name format: $DOMAIN_NAME"
  echo "💡 Domain should include a dot (e.g., fourschmucks.com)"
  exit 1
fi

# Validate bucket name format
if [[ "$BUCKET_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  echo "✅ Bucket name format looks good: $BUCKET_NAME"
else
  echo "❌ Invalid bucket name format: $BUCKET_NAME"
  echo "💡 Bucket name should be lowercase, no underscores, start/end with alphanumeric"
  exit 1
fi

STACK_NAME=fourschmucks-site
REGION=$(aws configure get region 2>/dev/null || true)
REGION="${REGION:-${AWS_DEFAULT_REGION:-$AWS_REGION}}"
if [ -z "$REGION" ]; then
  echo "❌ Could not determine AWS region. Set AWS_DEFAULT_REGION or configure a default region."
  exit 1
fi
LAMBDA_REGION="us-east-1"  # Lambda@Edge must be deployed to us-east-1

echo "Deploying to region: $REGION"
echo "Lambda@Edge will be deployed to: $LAMBDA_REGION"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
if ! aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides DomainName=$DOMAIN_NAME BucketName=$BUCKET_NAME; then
    echo "❌ CloudFormation deployment failed"
    echo "💡 Check the CloudFormation console for detailed error messages"
    exit 1
fi

echo "Waiting for stack to be created/updated..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME || \
  aws cloudformation wait stack-update-complete --stack-name $STACK_NAME

# Get outputs
echo "Getting stack outputs..."
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text)
CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDomain'].OutputValue" --output text)
CLOUDFRONT_DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$CLOUDFRONT_DOMAIN'].Id" --output text)

# Validate outputs
if [ -z "$S3_BUCKET" ] || [ "$S3_BUCKET" = "None" ]; then
    echo "❌ Failed to get S3 bucket name from stack outputs"
    exit 1
fi

if [ -z "$CLOUDFRONT_DOMAIN" ] || [ "$CLOUDFRONT_DOMAIN" = "None" ]; then
    echo "❌ Failed to get CloudFront domain from stack outputs"
    exit 1
fi

if [ -z "$CLOUDFRONT_DIST_ID" ] || [ "$CLOUDFRONT_DIST_ID" = "None" ]; then
    echo "❌ Failed to get CloudFront distribution ID"
    exit 1
fi

echo "✅ S3 Bucket: $S3_BUCKET"
echo "✅ CloudFront Domain: $CLOUDFRONT_DOMAIN"
echo "✅ CloudFront Distribution ID: $CLOUDFRONT_DIST_ID"

echo "Syncing static site to S3 bucket: $S3_BUCKET"
aws s3 sync . s3://$S3_BUCKET/ --exclude ".git/*" --exclude "deploy.sh" --exclude "cloudformation.yaml" --delete
aws s3 sync ./logos s3://$S3_BUCKET/logos/ --delete

echo "Invalidating CloudFront distribution: $CLOUDFRONT_DIST_ID"
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DIST_ID --paths "/" "/index.html" "/lifestyle.html" "/plumbing.html" "/brewing.html" "/consulting.html" "/stonks.html" "/rickroll.html" "/mirage.html"

echo "Waiting for CloudFront deployment to complete..."
echo "Note: Lambda@Edge functions can take 5-10 minutes to deploy globally."
echo "Your sites may not work immediately. Please wait for full deployment."

echo "Deployment complete!"
echo ""
echo "Your Four Schmucks sites are now available at:"
echo "  Main site: https://$DOMAIN_NAME"
echo "  Lifestyle: https://lifestyle.$DOMAIN_NAME"
echo "  Plumbing: https://plumbing.$DOMAIN_NAME (also https://poop.$DOMAIN_NAME)"
echo "  Brewing: https://brewing.$DOMAIN_NAME"
echo "  Consulting: https://consulting.$DOMAIN_NAME"
echo "  Stonks: https://stonks.$DOMAIN_NAME"
echo "  Rickroll: https://rickroll.$DOMAIN_NAME"
echo "  Mirage: https://mirage.$DOMAIN_NAME"
echo ""
echo "Note: Lambda@Edge deployment can take 5-10 minutes to propagate globally." 