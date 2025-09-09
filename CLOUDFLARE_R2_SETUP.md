# ☁️ Cloudflare R2 APK Hosting

## 🎯 Overview

Host APK on Cloudflare R2 with custom domain - cost-effective alternative to AWS S3.

## ✅ Pros
- **Low Cost**: $0.015/GB/month storage, $0.40/GB egress
- **Fast**: Cloudflare's global network
- **Custom Domain**: Easy domain binding
- **No Egress Fees**: For Cloudflare customers
- **S3 Compatible**: Familiar API

## ❌ Cons
- **Newer Service**: Less mature than AWS S3
- **Cloudflare Dependency**: Relies on Cloudflare
- **Limited Features**: Fewer advanced features than AWS

## 🚀 Setup Steps

### 1. Create R2 Bucket

#### Via Cloudflare Dashboard:
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to R2 Object Storage
3. Click "Create bucket"
4. Name: `aiu-dance-downloads`
5. Location: Choose closest to your users

#### Via Wrangler CLI:
```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Create bucket
wrangler r2 bucket create aiu-dance-downloads
```

### 2. Upload APK with Metadata

#### Via Dashboard:
1. Go to your R2 bucket
2. Click "Upload"
3. Select `aiu_dance_release.apk`
4. Set metadata:
   - Content-Type: `application/vnd.android.package-archive`
   - Cache-Control: `public, max-age=3600`
   - Content-Disposition: `attachment; filename="aiu-dance.apk"`

#### Via Wrangler CLI:
```bash
# Upload with metadata
wrangler r2 object put aiu-dance-downloads/aiu-dance.apk \
  --file ./aiu_dance_release.apk \
  --content-type "application/vnd.android.package-archive" \
  --cache-control "public, max-age=3600" \
  --content-disposition "attachment; filename=\"aiu-dance.apk\""
```

### 3. Enable Public Access

#### Via Dashboard:
1. Go to bucket settings
2. Enable "Public Access"
3. Set CORS policy if needed

#### Via Wrangler CLI:
```bash
# Create public access policy
cat > r2-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::aiu-dance-downloads/*"
    }
  ]
}
EOF

# Apply policy (if supported)
wrangler r2 bucket policy put aiu-dance-downloads --policy r2-policy.json
```

### 4. Bind Custom Domain

#### Via Dashboard:
1. Go to R2 → Custom Domains
2. Click "Connect Domain"
3. Enter: `download.aiu-dance.com`
4. Follow DNS setup instructions

#### DNS Configuration:
Create CNAME record:
```
download.aiu-dance.com → aiu-dance-downloads.your-account.r2.cloudflarestorage.com
```

### 5. Test Setup

```bash
# Test direct R2 URL
curl -I https://aiu-dance-downloads.your-account.r2.cloudflarestorage.com/aiu-dance.apk

# Test custom domain
curl -I https://download.aiu-dance.com/aiu-dance.apk

# Expected headers:
# content-type: application/vnd.android.package-archive
# content-disposition: attachment; filename="aiu-dance.apk"
# cache-control: public, max-age=3600
```

## 🔧 Automation Script

Create `scripts/cloudflare-r2-upload.sh`:

```bash
#!/bin/bash

# Cloudflare R2 APK Upload Script
BUCKET_NAME="aiu-dance-downloads"
APK_FILE="aiu_dance_release.apk"
DOMAIN="download.aiu-dance.com"

echo "🚀 Uploading APK to Cloudflare R2"

# Check if Wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Error: Wrangler CLI not found!"
    echo "Install with: npm install -g wrangler"
    exit 1
fi

# Check if APK exists
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: $APK_FILE not found!"
    exit 1
fi

# Upload APK
wrangler r2 object put $BUCKET_NAME/aiu-dance.apk \
  --file ./$APK_FILE \
  --content-type "application/vnd.android.package-archive" \
  --cache-control "public, max-age=3600" \
  --content-disposition "attachment; filename=\"aiu-dance.apk\""

if [ $? -eq 0 ]; then
    echo "✅ APK uploaded successfully!"
    echo ""
    echo "🔗 URLs:"
    echo "R2 Direct: https://$BUCKET_NAME.your-account.r2.cloudflarestorage.com/aiu-dance.apk"
    echo "Custom Domain: https://$DOMAIN/aiu-dance.apk"
else
    echo "❌ Upload failed!"
    exit 1
fi
```

## 📱 Update Download Page

Update `public/download.html`:

```html
<a class="btn" href="https://download.aiu-dance.com/aiu-dance.apk" download>
  📥 Download AIU Dance APK
</a>
```

## 💰 Cost Comparison

| Service | Storage | Egress | Total (1GB/month) |
|---------|---------|--------|-------------------|
| **Cloudflare R2** | $0.015 | $0.40 | ~$0.42 |
| **AWS S3** | $0.023 | $0.09 | ~$0.11 |
| **GitHub Releases** | Free | Free | $0 |

*Note: Cloudflare R2 has no egress fees for Cloudflare customers*

## 🔐 Security Features

- **HTTPS Only**: All traffic encrypted
- **Custom Domain**: Professional appearance
- **Access Control**: Bucket-level permissions
- **CORS Support**: Cross-origin resource sharing
- **Cache Control**: Configurable caching headers

## 🚨 Troubleshooting

### Common Issues

1. **403 Forbidden**
   - Check bucket public access settings
   - Verify CORS configuration
   - Ensure proper permissions

2. **DNS Issues**
   - Verify CNAME record
   - Check DNS propagation
   - Use `dig` to test resolution

3. **Upload Failures**
   - Check Wrangler authentication
   - Verify bucket exists
   - Check file permissions

## 📊 Monitoring

### Cloudflare Analytics
- Request volume
- Geographic distribution
- Cache hit ratio
- Error rates

### Custom Monitoring
```bash
# Monitor download success
curl -s -o /dev/null -w "%{http_code}" https://download.aiu-dance.com/aiu-dance.apk

# Check file size
curl -s -I https://download.aiu-dance.com/aiu-dance.apk | grep -i content-length
```

## 🎉 Final URLs

- **Custom Domain**: https://download.aiu-dance.com/aiu-dance.apk
- **R2 Direct**: https://aiu-dance-downloads.your-account.r2.cloudflarestorage.com/aiu-dance.apk

---

**Status**: ✅ Cost-Effective Alternative
**Cost**: ~$0.42/month for 1GB
**Last Updated**: September 8, 2025


