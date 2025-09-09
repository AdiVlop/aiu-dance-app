# 📱 AIU Dance APK Download System

## 🎯 Overview

This document describes the complete APK download system for AIU Dance, including direct download, fallback methods, and deployment procedures.

## 🌐 Live URLs

- **Main Download Page**: https://aiu-dance.web.app/download.html
- **Home Page**: https://aiu-dance.web.app/
- **Direct APK Download**: https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media

## 📁 File Structure

```
public/
├── index.html              # Main landing page
├── download.html           # APK download page
└── apk/
    └── .keep              # Placeholder (APK hosted on Firebase Storage)
```

## 🔧 Configuration

### Firebase Hosting Configuration (`firebase.json`)

```json
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/download.html",
        "destination": "/download.html"
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**/*.@(html|json)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=0"
          }
        ]
      }
    ]
  }
}
```

## 📱 APK Files Available

| File | Size | Description |
|------|------|-------------|
| `aiu_dance_release.apk` | 51MB | Production release (optimized) |
| `aiu_dance_debug.apk` | 127MB | Debug version (with symbols) |
| `aiu_dance_lite.apk` | 36MB | Lightweight version |

## 🚀 Deployment Process

### 1. Build APK
```bash
flutter build apk --release
```

### 2. Upload to Firebase Storage
```bash
./scripts/upload_apk_to_storage.sh
```

### 3. Deploy Hosting
```bash
firebase deploy --only hosting
```

## 🔄 Fallback Methods

### Method 1: Firebase Storage (Primary)
- **URL**: `https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media`
- **Pros**: Fast, reliable, integrated with Firebase
- **Cons**: Requires Firebase Storage setup

### Method 2: Email Request
- **URL**: `mailto:admin@aiudance.ro?subject=Cerere APK AIU Dance&body=...`
- **Pros**: Personal contact, secure
- **Cons**: Manual process

### Method 3: WhatsApp Request
- **URL**: `https://wa.me/40712345678?text=...`
- **Pros**: Quick response, mobile-friendly
- **Cons**: Requires phone number

### Method 4: GitHub Releases (Future)
- **URL**: `https://github.com/org/repo/releases/download/v1.0.0/aiu-dance.apk`
- **Pros**: Stable URL, CDN, version control
- **Cons**: Requires public repository

## 🛠️ Troubleshooting

### Common Issues

1. **"Executable files are forbidden"**
   - **Cause**: Firebase Hosting Spark plan restrictions
   - **Solution**: Use Firebase Storage fallback

2. **"App not installed" on Android**
   - **Cause**: Old version or security restrictions
   - **Solution**: Uninstall old version, enable "Unknown sources"

3. **Download doesn't start**
   - **Cause**: Browser security or network issues
   - **Solution**: Try alternative download methods

4. **Play Protect blocks installation**
   - **Cause**: Google Play Protect security
   - **Solution**: Allow installation from unknown sources

### Testing Commands

```bash
# Test download page
curl -I https://aiu-dance.web.app/download.html

# Test APK download
curl -I https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media

# Check file size
curl -s -I https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media | grep -i content-length
```

## 📊 Analytics & Monitoring

### Download Tracking
- Firebase Analytics integration
- Download button click tracking
- Error monitoring

### Performance Metrics
- Download success rate
- Average download time
- User device statistics

## 🔐 Security Considerations

1. **APK Signing**: All APKs are properly signed
2. **Virus Scanning**: Regular security scans
3. **Access Control**: Firebase Storage permissions
4. **HTTPS**: All downloads over secure connections

## 📋 Maintenance Tasks

### Regular Updates
- [ ] Update APK version numbers
- [ ] Test download functionality
- [ ] Monitor storage usage
- [ ] Update documentation

### Version Management
- [ ] Tag releases in Git
- [ ] Update download page version info
- [ ] Archive old APK versions
- [ ] Update fallback URLs

## 🎉 Success Metrics

- ✅ Direct download URL working
- ✅ Fallback methods available
- ✅ Mobile-friendly download page
- ✅ Proper APK headers and MIME types
- ✅ Firebase Storage integration
- ✅ Error handling and user guidance

## 📞 Support

For issues with APK downloads:
- **Email**: admin@aiudance.ro
- **WhatsApp**: +40712345678
- **Website**: https://aiu-dance.web.app

---

**Last Updated**: September 8, 2025
**Version**: 1.0.0
**Status**: ✅ Production Ready


