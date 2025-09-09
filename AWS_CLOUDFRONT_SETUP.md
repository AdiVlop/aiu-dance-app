# 🌐 AWS S3 + CloudFront APK Hosting Setup

## 🎯 Overview

This guide sets up AWS S3 + CloudFront for hosting AIU Dance APK with a custom domain `download.aiu-dance.com`.

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Domain `aiu-dance.com` managed in Route 53 (or external DNS)
- APK file built and ready (`aiu_dance_release.apk`)

## 🚀 Quick Setup

### 1. Run the Setup Script

```bash
./scripts/aws-s3-cloudfront-setup.sh
```

This will:
- Create S3 bucket `aiu-dance-downloads` in `eu-west-1`
- Upload APK with correct metadata
- Set up bucket policy for public access

### 2. Manual CloudFront Setup (AWS Console)

#### Step 1: Create CloudFront Distribution

1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront/)
2. Click "Create Distribution"
3. Configure:

**Origin Settings:**
- Origin Domain: `aiu-dance-downloads.s3.eu-west-1.amazonaws.com`
- Origin Path: (leave empty)
- Origin Access: **Origin Access Control (OAC)** - Recommended
- Origin Access Control: Create new OAC

**Default Cache Behavior:**
- Viewer Protocol Policy: **Redirect HTTP to HTTPS**
- Allowed HTTP Methods: **GET, HEAD**
- Cache Policy: **CachingOptimized**
- Origin Request Policy: **CORS-S3Origin**

**Distribution Settings:**
- Alternate Domain Names (CNAMEs): `download.aiu-dance.com`
- SSL Certificate: **Request or Import a Certificate with ACM**
- Minimum TLS Version: **TLSv1.2**

#### Step 2: Create SSL Certificate

1. Go to [ACM Console](https://console.aws.amazon.com/acm/) in **us-east-1**
2. Request a certificate for `download.aiu-dance.com`
3. Validate via DNS (Route 53)
4. Attach to CloudFront distribution

#### Step 3: Update S3 Bucket Policy for OAC

Replace the temporary public policy with OAC policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::aiu-dance-downloads/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT-ID:distribution/DISTRIBUTION-ID"
        }
      }
    }
  ]
}
```

#### Step 4: DNS Configuration

**Route 53 (if using AWS DNS):**
1. Go to Route 53 → Hosted Zones
2. Select `aiu-dance.com` zone
3. Create record:
   - Name: `download`
   - Type: `CNAME`
   - Value: `d1234567890.cloudfront.net` (your CloudFront domain)

**External DNS:**
Create CNAME record:
```
download.aiu-dance.com → d1234567890.cloudfront.net
```

## 🔧 CLI Commands

### Create S3 Bucket
```bash
aws s3api create-bucket \
  --bucket aiu-dance-downloads \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1
```

### Upload APK with Metadata
```bash
aws s3 cp ./aiu_dance_release.apk s3://aiu-dance-downloads/aiu-dance.apk \
  --content-type "application/vnd.android.package-archive" \
  --metadata-directive REPLACE \
  --cache-control "public, max-age=3600" \
  --content-disposition "attachment; filename=\"aiu-dance.apk\""
```

### Set Bucket Policy (Temporary Public)
```bash
cat > bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGET",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::aiu-dance-downloads/*"]
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket aiu-dance-downloads --policy file://bucket-policy.json
```

## 🧪 Testing & Verification

### Test S3 Direct Access
```bash
curl -I https://aiu-dance-downloads.s3.eu-west-1.amazonaws.com/aiu-dance.apk
```

Expected headers:
```
content-type: application/vnd.android.package-archive
content-disposition: attachment; filename="aiu-dance.apk"
cache-control: public, max-age=3600
```

### Test CloudFront Distribution
```bash
curl -I https://d1234567890.cloudfront.net/aiu-dance.apk
```

### Test Custom Domain
```bash
curl -I https://download.aiu-dance.com/aiu-dance.apk
```

## 📱 Update Download Page

Update `public/download.html`:

```html
<a class="btn" href="https://download.aiu-dance.com/aiu-dance.apk" download>
  📥 Download AIU Dance APK
</a>
```

## 💰 Cost Estimation

**S3 Storage:**
- 51MB APK: ~$0.001/month

**CloudFront:**
- 1,000 downloads/month: ~$0.085
- 10,000 downloads/month: ~$0.85

**Total: <$1/month for typical usage**

## 🔐 Security Best Practices

1. **Use OAC** instead of public bucket access
2. **HTTPS only** with SSL certificate
3. **Restrict CloudFront** to specific geographic regions if needed
4. **Monitor access** with CloudWatch logs
5. **Regular security audits** of bucket policies

## 🚨 Troubleshooting

### Common Issues

1. **403 Forbidden**
   - Check bucket policy
   - Verify OAC configuration
   - Ensure CloudFront has proper permissions

2. **SSL Certificate Issues**
   - Certificate must be in `us-east-1` for CloudFront
   - Domain validation required

3. **DNS Propagation**
   - CNAME changes can take up to 48 hours
   - Use `dig` to verify DNS resolution

4. **Cache Issues**
   - CloudFront caches for 24 hours by default
   - Invalidate cache if needed: `aws cloudfront create-invalidation --distribution-id DISTRIBUTION-ID --paths "/*"`

## 📊 Monitoring

### CloudWatch Metrics
- Requests
- Data transfer
- Error rates
- Cache hit ratio

### Access Logs
Enable CloudFront access logs to monitor:
- Download patterns
- Geographic distribution
- User agents
- Error rates

## 🎉 Final URLs

- **Custom Domain**: https://download.aiu-dance.com/aiu-dance.apk
- **CloudFront**: https://d1234567890.cloudfront.net/aiu-dance.apk
- **S3 Direct**: https://aiu-dance-downloads.s3.eu-west-1.amazonaws.com/aiu-dance.apk

---

**Status**: ✅ Production Ready
**Last Updated**: September 8, 2025


