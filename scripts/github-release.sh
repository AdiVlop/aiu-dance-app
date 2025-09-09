#!/bin/bash

# GitHub Release APK Upload Script
REPO="adrianpersonal/aiu_dance"  # Replace with your actual repo
VERSION="v1.0.0"
APK_FILE="aiu_dance_release.apk"

echo "🚀 Creating GitHub Release for AIU Dance"

# Check if APK exists
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: $APK_FILE not found!"
    echo "Please build the APK first with: flutter build apk --release"
    exit 1
fi

echo "✅ Found APK file: $APK_FILE"
echo "📦 Size: $(du -h $APK_FILE | cut -f1)"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI not found!"
    echo "Please install GitHub CLI:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://cli.github.com/"
    echo "  Windows: winget install GitHub.cli"
    exit 1
fi

# Check if logged in to GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not logged in to GitHub!"
    echo "Please login: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI configured"

# Create release
echo "📤 Creating release $VERSION..."
gh release create $VERSION $APK_FILE \
  --title "AIU Dance $VERSION" \
  --notes "Production release of AIU Dance Android app

## Features
- 🎓 Course management and enrollment
- 💰 Digital wallet with multiple payment methods
- 📱 QR code check-in system
- 🍹 Bar ordering with QR payments
- 📊 Comprehensive reporting and analytics
- 🔔 Push notifications and announcements

## Installation Instructions
1. Download the APK file below
2. Enable 'Unknown sources' in Android Settings → Security
3. Install the APK file
4. Open AIU Dance app and enjoy!

## System Requirements
- Android 6.0+ (API level 23)
- ARM64 architecture (99% of modern devices)
- 100MB free storage space

## Support
- Email: admin@aiudance.ro
- WhatsApp: +40712345678
- Website: https://aiu-dance.web.app"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Release created successfully!"
    echo ""
    echo "🔗 URLs:"
    echo "Release Page: https://github.com/$REPO/releases/tag/$VERSION"
    echo "Download URL: https://github.com/$REPO/releases/download/$VERSION/$APK_FILE"
    echo ""
    echo "📱 Next steps:"
    echo "1. Update public/download.html with the download URL"
    echo "2. Deploy the updated website"
    echo "3. Test the download functionality"
else
    echo "❌ Release creation failed!"
    exit 1
fi


