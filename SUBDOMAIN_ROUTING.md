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
  'mirage': 'mirage.html'
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
- Function is associated with CloudFront's `origin-request` event

### 3. **File Sync**
- All HTML files are synced to S3 bucket
- CloudFront cache is invalidated
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
- **Wildcard**: Certificate covers all subdomains
- **Validation**: DNS validation required for each subdomain
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