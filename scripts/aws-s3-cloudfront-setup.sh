#!/bin/bash

# AIU Dance AWS S3 + CloudFront Setup Script
# This script sets up S3 bucket and CloudFront distribution for APK hosting

echo "🚀 AIU Dance AWS S3 + CloudFront Setup"
echo "====================================="

# Configuration
BUCKET_NAME="aiu-dance-downloads"
REGION="eu-west-1"
DOMAIN="download.aiu-dance.com"
APK_FILE="aiu_dance_release.apk"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: AWS CLI not configured!"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured"
echo "📋 Configuration:"
echo "   Bucket: $BUCKET_NAME"
echo "   Region: $REGION"
echo "   Domain: $DOMAIN"
echo "   APK File: $APK_FILE"
echo ""

# Check if APK file exists
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: $APK_FILE not found!"
    echo "Please build the APK first with: flutter build apk --release"
    exit 1
fi

echo "✅ Found APK file: $APK_FILE"
echo "📦 Size: $(du -h $APK_FILE | cut -f1)"
echo ""

# Step 1: Create S3 bucket
echo "📦 Step 1: Creating S3 bucket..."
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

if [ $? -eq 0 ]; then
    echo "✅ S3 bucket created: $BUCKET_NAME"
else
    echo "⚠️  Bucket might already exist, continuing..."
fi

# Step 2: Upload APK with proper metadata
echo ""
echo "📤 Step 2: Uploading APK with metadata..."
aws s3 cp ./$APK_FILE s3://$BUCKET_NAME/aiu-dance.apk \
    --content-type "application/vnd.android.package-archive" \
    --metadata-directive REPLACE \
    --cache-control "public, max-age=3600" \
    --content-disposition "attachment; filename=\"aiu-dance.apk\""

if [ $? -eq 0 ]; then
    echo "✅ APK uploaded with correct metadata"
else
    echo "❌ APK upload failed!"
    exit 1
fi

# Step 3: Create bucket policy (temporary public access)
echo ""
echo "🔐 Step 3: Setting up bucket policy..."
cat > bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGET",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::$BUCKET_NAME/*"]
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

if [ $? -eq 0 ]; then
    echo "✅ Bucket policy applied"
else
    echo "❌ Bucket policy failed!"
    exit 1
fi

# Clean up
rm bucket-policy.json

echo ""
echo "🎉 S3 Setup Complete!"
echo ""
echo "📋 Next Steps (Manual):"
echo "1. Create CloudFront distribution:"
echo "   - Origin: s3://$BUCKET_NAME"
echo "   - Enable Origin Access Control (OAC)"
echo "   - Add Alternate Domain Name: $DOMAIN"
echo "   - Request ACM certificate in us-east-1 for $DOMAIN"
echo ""
echo "2. Update DNS:"
echo "   - Create CNAME: $DOMAIN → CloudFront distribution domain"
echo ""
echo "3. Test:"
echo "   curl -I https://$DOMAIN/aiu-dance.apk"
echo ""
echo "🔗 Current S3 URL (temporary):"
echo "https://$BUCKET_NAME.s3.$REGION.amazonaws.com/aiu-dance.apk"


