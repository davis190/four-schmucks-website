# Four Schmucks Subdomain Routing

## 🌐 How Subdomain Routing Works

The Four Schmucks infrastructure uses **Lambda@Edge** functions with **CloudFront** to route different subdomains to different HTML files within the same S3 bucket.

## 🔧 Technical Implementation

### 1. **Lambda@Edge Function**
The `SubdomainRoutingFunction` intercepts all requests to CloudFront and routes them based on the subdomain:

```javascript
// Extract subdomain from host header
const subdomain = host.split('.')[0];

// Map subdomains to HTML files
const subdomainMap = {
  'www': 'index.html',
  'lifestyle': 'lifestyle.html',
  'plumbing': 'plumbing.html',
  'poop': 'plumbing.html',        // Alternative domain for plumbing
  'brewing': 'brewing.html',
  'consulting': 'consulting.html',
  'stonks': 'stonks.html',
  'rickroll': 'rickroll.html',
  'mirage': 'mirage.html',
  'launder': 'launder.html',
  'fraud': 'launder.html'      // Alternative domain for Fraud & Launder
};
```

### 2. **Request Flow**
1. User visits `https://lifestyle.fourschmucks.com`
2. CloudFront receives the request
3. Lambda@Edge function extracts `lifestyle` from the host header
4. Function maps `lifestyle` → `lifestyle.html`
5. Function modifies the request URI to `/lifestyle.html`
6. CloudFront fetches `lifestyle.html` from S3
7. User sees the lifestyle site

### 3. **URL Structure**
```
https://www.fourschmucks.com          → index.html (main site)
https://lifestyle.fourschmucks.com → lifestyle.html
https://plumbing.fourschmucks.com  → plumbing.html
https://poop.fourschmucks.com      → plumbing.html (alternative)
https://brewing.fourschmucks.com   → brewing.html
https://consulting.fourschmucks.com → consulting.html
https://stonks.fourschmucks.com    → stonks.html
https://rickroll.fourschmucks.com  → rickroll.html
https://mirage.fourschmucks.com    → mirage.html
https://launder.fourschmucks.com   → launder.html
https://fraud.fourschmucks.com     → launder.html (alternative)
```

## 🚀 Deployment Process

### 1. **CloudFormation Stack**
- Creates S3 bucket for static hosting
- Creates Lambda@Edge function for routing
- Creates CloudFront distribution with all subdomains
- Creates ACM certificate for HTTPS

### 2. **Lambda@Edge Deployment**
- Function is deployed to `us-east-1` region (required)
- Function version is created for CloudFront association
- Function is associated with CloudFront's **`viewer-request`** event

  It must stay on `viewer-request`. The distribution does not forward the `Host`
  header, so `Host` is not part of the cache key — the rewritten URI is what varies
  per subdomain. Moving the function to `origin-request` would run it *after* the
  cache lookup and cause one subdomain's page to be served on another.

### 3. **File Sync**
- All site files are synced to S3 (recursively, so `assets/`, `images/` and `logos/`
  are included automatically; infra scripts and repo docs are excluded)
- CloudFront cache is invalidated with a single `/*` wildcard. The pages share
  `/assets/site.css`, the distribution forwards no query string (so `?v=` cache-busting
  does nothing) and sets no `Cache-Control` (so CloudFront's 24h default TTL applies) —
  a per-page invalidation list would leave changed CSS stale for a day.
- Lambda@Edge function propagates globally (5-10 minutes)

## ⚠️ Important Notes

### **Lambda@Edge Limitations**
- **Region**: Must be deployed to `us-east-1`
- **Deployment Time**: Can take 5-10 minutes to propagate globally
- **Cold Starts**: First request to each subdomain may be slower
- **Memory**: Limited to 128MB (sufficient for routing logic)

### **CloudFront Behavior**
- **Caching**: Each subdomain is cached separately
- **Invalidation**: Cache invalidation affects all subdomains
- **Edge Locations**: Content is served from nearest edge location

### **SSL Certificate**
- **Wildcard**: the cert is `fourschmucks.com` + `*.fourschmucks.com`. A wildcard matches
  exactly one label, which is all this site uses, so **adding a service line requires no
  certificate change at all** — no SAN edit, no re-validation, nothing blocking the stack.
  Adding the subdomain to `CloudFrontDistribution.Aliases` is an in-place distribution
  update, and the alias is accepted because the cert already covers it.
- **The apex is separate**: `*.fourschmucks.com` does **not** match `fourschmucks.com`, so
  the bare domain stays as `Certificate.DomainName`.
- **Validation**: ACM issues a *single* CNAME covering both the apex and the wildcard.
- **History**: this was an enumerated SAN list until August 2026. Every new subdomain
  replaced the certificate and stalled the stack on fresh DNS validation, which made it
  the slowest and riskiest part of shipping a brand. The wildcard removed that step.
- **Renewal**: Automatic renewal through ACM

## 🔍 Troubleshooting

### **Subdomain Not Working**
1. Check if Lambda@Edge function is deployed (wait 5-10 minutes)
2. Verify CloudFront distribution is enabled
3. Check ACM certificate validation status
4. Verify DNS records point to CloudFront

### **Wrong Content Showing**
1. Check Lambda@Edge function logs in CloudWatch
2. Verify HTML files are synced to S3
3. Check CloudFront cache invalidation
4. Verify subdomain mapping in Lambda function

### **SSL Certificate Issues**
1. Check ACM certificate validation status
2. Verify DNS records are correct
3. Wait for certificate to be issued
4. Check CloudFront viewer certificate configuration

## 📊 Monitoring

### **CloudWatch Logs**
- Lambda@Edge function logs appear in CloudWatch
- Logs are in the region where the function is deployed (`us-east-1`)
- Log group: `/aws/lambda/fourschmucks-subdomain-routing-{domain}`

### **CloudFront Metrics**
- Request counts per subdomain
- Error rates and cache hit ratios
- Geographic distribution of requests
- Performance metrics

## 🔮 Future Enhancements

### **Advanced Routing**
- Path-based routing within subdomains
- A/B testing support
- Geographic routing
- User agent-based routing

### **Performance Optimization**
- Edge-optimized Lambda functions
- Intelligent caching strategies
- CDN optimization
- Image optimization

---

*This routing system ensures that each Four Schmucks subdomain displays its corresponding content while maintaining a single S3 bucket and CloudFront distribution for cost efficiency and simplicity.* 