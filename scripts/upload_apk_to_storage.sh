#!/bin/bash

# AIU Dance APK Upload to Firebase Storage Script
# This script uploads the APK file to Firebase Storage for hosting

echo "🚀 AIU Dance APK Upload to Firebase Storage"
echo "=========================================="

# Check if APK file exists
if [ ! -f "aiu_dance_release.apk" ]; then
    echo "❌ Error: aiu_dance_release.apk not found!"
    echo "Please build the APK first with: flutter build apk --release"
    exit 1
fi

echo "✅ Found APK file: aiu_dance_release.apk"
echo "📦 Size: $(du -h aiu_dance_release.apk | cut -f1)"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI not found!"
    echo "Please install Firebase CLI: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Error: Not logged in to Firebase!"
    echo "Please login: firebase login"
    exit 1
fi

echo ""
echo "📤 Uploading APK to Firebase Storage..."

# Upload to Firebase Storage
firebase storage:upload aiu_dance_release.apk gs://aiu-dance.appspot.com/aiu-dance.apk

if [ $? -eq 0 ]; then
    echo "✅ APK uploaded successfully to Firebase Storage!"
    echo ""
    echo "🔗 Download URL:"
    echo "https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media"
    echo ""
    echo "📱 Test the download:"
    echo "https://aiu-dance.web.app/download.html"
    echo ""
    echo "🔧 To make the file publicly accessible:"
    echo "1. Go to Firebase Console → Storage"
    echo "2. Find aiu-dance.apk"
    echo "3. Right-click → Edit permissions"
    echo "4. Set to 'Public' or add read permission for all users"
else
    echo "❌ Upload failed!"
    echo ""
    echo "🔧 Manual upload instructions:"
    echo "1. Go to Firebase Console → Storage"
    echo "2. Click 'Upload file'"
    echo "3. Select aiu_dance_release.apk"
    echo "4. Rename to 'aiu-dance.apk'"
    echo "5. Set permissions to public"
    echo ""
    echo "🔗 Then use this URL:"
    echo "https://firebasestorage.googleapis.com/v0/b/aiu-dance.appspot.com/o/aiu-dance.apk?alt=media"
fi

echo ""
echo "🎉 APK upload process completed!"


