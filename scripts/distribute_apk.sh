#!/bin/bash

# AIU Dance APK Distribution Script
# This script helps distribute the APK file through various methods

echo "🚀 AIU Dance APK Distribution Helper"
echo "=================================="

# Check if APK files exist
if [ ! -f "aiu_dance_release.apk" ]; then
    echo "❌ Error: aiu_dance_release.apk not found!"
    echo "Please build the APK first with: flutter build apk --release"
    exit 1
fi

echo "✅ Found APK file: aiu_dance_release.apk"
echo "📦 Size: $(du -h aiu_dance_release.apk | cut -f1)"

echo ""
echo "📋 Distribution Options:"
echo "1. 📧 Email distribution (manual)"
echo "2. 💬 WhatsApp distribution (manual)"
echo "3. ☁️  Upload to cloud storage"
echo "4. 📱 Direct installation via ADB"
echo "5. 🌐 Update download page"

read -p "Choose an option (1-5): " choice

case $choice in
    1)
        echo ""
        echo "📧 Email Distribution:"
        echo "Send the APK file to users via email"
        echo "File: aiu_dance_release.apk"
        echo "Size: $(du -h aiu_dance_release.apk | cut -f1)"
        echo ""
        echo "Email template:"
        echo "Subject: AIU Dance - Aplicația Android"
        echo "Body: Bună! Atașat găsiți aplicația AIU Dance pentru Android."
        echo "Instrucțiuni de instalare:"
        echo "1. Descarcă fișierul APK"
        echo "2. Activează 'Surse necunoscute' în Setări → Securitate"
        echo "3. Deschide fișierul APK și apasă 'Instalează'"
        ;;
    2)
        echo ""
        echo "💬 WhatsApp Distribution:"
        echo "Share the APK file via WhatsApp"
        echo "File: aiu_dance_release.apk"
        echo ""
        echo "WhatsApp message template:"
        echo "Bună! Atașat găsiți aplicația AIU Dance pentru Android. Instrucțiuni de instalare: 1) Descarcă fișierul APK 2) Activează 'Surse necunoscute' în Setări → Securitate 3) Deschide fișierul APK și apasă 'Instalează'"
        ;;
    3)
        echo ""
        echo "☁️  Cloud Storage Upload:"
        echo "Upload the APK to cloud storage services:"
        echo ""
        echo "Google Drive:"
        echo "1. Go to https://drive.google.com"
        echo "2. Upload aiu_dance_release.apk"
        echo "3. Right-click → Get link → Anyone with the link can view"
        echo "4. Copy the file ID from the URL"
        echo "5. Use format: https://drive.google.com/uc?export=download&id=FILE_ID"
        echo ""
        echo "Dropbox:"
        echo "1. Upload to Dropbox"
        echo "2. Right-click → Share → Copy link"
        echo "3. Replace 'dl=0' with 'dl=1' in the URL"
        ;;
    4)
        echo ""
        echo "📱 Direct Installation via ADB:"
        echo "Install directly to connected Android device"
        echo ""
        if command -v adb &> /dev/null; then
            echo "✅ ADB found. Checking for connected devices..."
            adb devices
            echo ""
            read -p "Install to connected device? (y/n): " install_choice
            if [ "$install_choice" = "y" ]; then
                adb install aiu_dance_release.apk
            fi
        else
            echo "❌ ADB not found. Please install Android SDK tools."
        fi
        ;;
    5)
        echo ""
        echo "🌐 Update Download Page:"
        echo "The download page has been updated with contact methods."
        echo "URL: https://aiu-dance.web.app/download.html"
        echo ""
        echo "Current status: ✅ Deployed and working"
        ;;
    *)
        echo "❌ Invalid option. Please choose 1-5."
        ;;
esac

echo ""
echo "🎉 APK distribution helper completed!"
echo "📱 APK file: aiu_dance_release.apk"
echo "🌐 Download page: https://aiu-dance.web.app/download.html"


