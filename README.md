# Four Schmucks Rickroll Site

This project deploys a static website to AWS S3 and serves it via CloudFront at `https://www.fourschmucks.com`. The site is a rickroll destination for QR code campaigns.

## Features
- Static HTML site with a Rick Astley video and your logo
- S3 bucket for static hosting
- CloudFront distribution for global delivery
- ACM certificate for HTTPS
- Route53 DNS setup for your domain
- One-command deploy script
- **No state management required** (uses CloudFormation)

---

## Prerequisites
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with appropriate permissions
- Your domain (`fourschmucks.com`) managed in Route53 (or ready to transfer)
- Bash shell (for `deploy.sh`)

---

## Setup & Deployment

### 1. Clone the Repo
```sh
git clone <this-repo-url>
cd fourschmucks
```

### 2. Set Deployment Parameters
Set the following environment variables before running the deploy script:
- `DOMAIN_NAME` (e.g., fourschmucks.com)
- `BUCKET_NAME` (e.g., fourschmucks-static-site)

Example:
```sh
export DOMAIN_NAME="fourschmucks.com"
export BUCKET_NAME="fourschmucks-static-site"
```

### 3. Deploy the Site and Infrastructure
Run the deploy script:
```sh
./deploy.sh
```
- This will deploy the CloudFormation stack, create/update all AWS resources, sync your static site to S3, and invalidate the CloudFront cache.
- The script will automatically extract the S3 bucket and CloudFront distribution from stack outputs.

### 4. Test
Visit `https://www.fourschmucks.com` (or your domain) to verify the rickroll site is live!

---

## Customization
- Edit `index.html` for your own message or branding.
- Place additional images in the `logos/` directory.

---

## Troubleshooting
- **ACM Certificate:** If HTTPS doesn’t work, check ACM certificate validation in the AWS Console.
- **DNS:** Make sure your domain is using the Route53 nameservers.
- **Permissions:** Ensure your AWS user has permissions for S3, CloudFront, ACM, and Route53.
- **CloudFormation Errors:** Check the AWS Console for stack events and error messages.

---

## Cleanup
To remove all resources, delete the CloudFormation stack:
```sh
aws cloudformation delete-stack --stack-name fourschmucks-site
```

---

## License
MIT 