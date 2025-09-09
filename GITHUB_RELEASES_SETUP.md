# 🐙 GitHub Releases APK Hosting

## 🎯 Overview

Host APK via GitHub Releases - simple, free, and stable solution with built-in CDN.

## ✅ Pros
- **Free**: No hosting costs
- **Stable URLs**: Never change
- **CDN**: GitHub's global CDN
- **Version Control**: Automatic versioning
- **Public/Private**: Choose repository visibility

## ❌ Cons
- **Public Repo**: APK visible to everyone (or need auth for private)
- **GitHub Dependency**: Relies on GitHub availability
- **File Size**: 100MB limit per file

## 🚀 Setup Steps

### 1. Create GitHub Release

#### Via GitHub Web Interface:
1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Create new tag: `v1.0.0`
4. Release title: `AIU Dance v1.0.0`
5. Attach file: `aiu_dance_release.apk`
6. Publish release

#### Via GitHub CLI:
```bash
# Install GitHub CLI if not installed
# brew install gh (macOS) or download from https://cli.github.com/

# Login to GitHub
gh auth login

# Create release with APK
gh release create v1.0.0 aiu_dance_release.apk \
  --title "AIU Dance v1.0.0" \
  --notes "Production release of AIU Dance Android app"
```

### 2. Get Download URL

After creating the release, the direct download URL will be:
```
https://github.com/USERNAME/REPOSITORY/releases/download/v1.0.0/aiu_dance_release.apk
```

Replace:
- `USERNAME`: Your GitHub username
- `REPOSITORY`: Repository name
- `v1.0.0`: Release tag

### 3. Update Download Page

Update `public/download.html`:

```html
<a class="btn" href="https://github.com/USERNAME/REPOSITORY/releases/download/v1.0.0/aiu_dance_release.apk" download>
  📥 Download AIU Dance APK
</a>
```

## 🧪 Testing

```bash
# Test download URL
curl -I https://github.com/USERNAME/REPOSITORY/releases/download/v1.0.0/aiu_dance_release.apk

# Expected response:
# HTTP/2 302
# location: https://github-releases.githubusercontent.com/...
```

## 📋 Automation Script

Create `scripts/github-release.sh`:

```bash
#!/bin/bash

# GitHub Release APK Upload Script
REPO="USERNAME/REPOSITORY"  # Replace with your repo
VERSION="v1.0.0"
APK_FILE="aiu_dance_release.apk"

echo "🚀 Creating GitHub Release for AIU Dance"

# Check if APK exists
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: $APK_FILE not found!"
    exit 1
fi

# Create release
gh release create $VERSION $APK_FILE \
  --title "AIU Dance $VERSION" \
  --notes "Production release of AIU Dance Android app

## Features
- 🎓 Course management
- 💰 Digital wallet
- 📱 QR check-in
- 🍹 Bar ordering system

## Installation
1. Download the APK file
2. Enable 'Unknown sources' in Android settings
3. Install the APK
4. Open AIU Dance app"

echo "✅ Release created: https://github.com/$REPO/releases/tag/$VERSION"
echo "📱 Download URL: https://github.com/$REPO/releases/download/$VERSION/$APK_FILE"
```

## 🔄 Version Management

### Semantic Versioning
- `v1.0.0` - Major release
- `v1.0.1` - Bug fixes
- `v1.1.0` - New features
- `v2.0.0` - Breaking changes

### Update Process
1. Build new APK
2. Create new release with incremented version
3. Update download page URL
4. Deploy updated website

## 🔐 Security Considerations

### Public Repository
- APK is publicly accessible
- Anyone can download
- Good for open source projects

### Private Repository
- APK requires authentication
- More secure but complex setup
- Need to handle auth in download flow

## 📊 Analytics

GitHub provides basic download statistics:
- Go to Releases page
- Click on release
- View download count

For detailed analytics, consider:
- Google Analytics on download page
- Custom tracking in app
- Server-side logging

## 🎉 Final Setup

After setup, your download URL will be:
```
https://github.com/USERNAME/REPOSITORY/releases/download/v1.0.0/aiu_dance_release.apk
```

Update your download page and test the complete flow!

---

**Status**: ✅ Simple & Effective
**Cost**: Free
**Last Updated**: September 8, 2025


