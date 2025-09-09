#!/bin/bash

# AIU Dance GitHub Repository Setup Script
# Acest script configurează repository-ul GitHub și creează primul release

set -e  # Exit on any error

echo "🚀 AIU Dance GitHub Repository Setup"
echo "===================================="

# Configurare
PROJECT_DIR="$HOME/aiu_dance"
REPO_URL="https://github.com/AdiVlop/aiu-dance-app.git"
APK_FILE="$HOME/Desktop/AIU_Dance_APK.apk"
VERSION="v1.0.0"

# Verifică dacă directorul proiectului există
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: Directorul proiectului nu există: $PROJECT_DIR"
    echo "Te rog să rulezi scriptul din directorul corect."
    exit 1
fi

echo "📁 Intrăm în directorul proiectului: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 1. Inițializează repo git (dacă nu există)
if [ ! -d ".git" ]; then
    echo "🔧 Inițializăm repository-ul Git..."
    git init
else
    echo "✅ Repository-ul Git există deja"
fi

# 2. Creează .gitignore optimizat pentru Flutter
echo "📝 Creăm .gitignore optimizat pentru Flutter..."
cat > .gitignore << 'EOF'
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# Android
android/app/debug
android/app/profile
android/app/release
android/gradle/
android/gradlew
android/gradlew.bat
android/local.properties
android/key.properties
android/.gradle/
android/captures/
android/gradlew
android/gradlew.bat
android/local.properties
android/key.properties
android/.gradle/
android/captures/
android/gradlew
android/gradlew.bat
android/local.properties
android/key.properties
android/.gradle/
android/captures/

# iOS
ios/Flutter/App.framework
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Flutter/Generated.xcconfig
ios/Flutter/app.flx
ios/Flutter/app.zip
ios/Flutter/flutter_assets/
ios/Flutter/flutter_export_environment.sh
ios/ServiceDefinitions.json
ios/Runner/GeneratedPluginRegistrant.*
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Flutter/Generated.xcconfig
ios/Flutter/app.flx
ios/Flutter/app.zip
ios/Flutter/flutter_assets/
ios/Flutter/flutter_export_environment.sh
ios/ServiceDefinitions.json
ios/Runner/GeneratedPluginRegistrant.*

# Web
web/

# APK files
*.apk
*.aab

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Environment variables
.env
.env.local
.env.production

# Firebase
firebase-debug.log
.firebase/

# Temporary files
*.tmp
*.temp
EOF

echo "✅ .gitignore creat cu succes"

# 3. Creează README.md
echo "📖 Creăm README.md..."
cat > README.md << 'EOF'
# AIU Dance

Aplicația AIU Dance pentru gestionarea școlii de dans.

## Descriere

AIU Dance este o aplicație Flutter completă pentru gestionarea unei școli de dans, cu funcționalități avansate pentru:

- 🎓 **Gestionare cursuri** - Înscrieri, programe, instructori
- 💰 **Portofel digital** - Plăți online, Revolut, Stripe
- 📱 **Sistem QR** - Check-in automat, comenzi bar
- 🍹 **Bar digital** - Meniu, comenzi, plăți QR
- 📊 **Rapoarte** - Statistici, analize, export

## Tehnologii

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **Plăți**: Stripe, Revolut
- **Hosting**: Firebase Hosting
- **APK Hosting**: GitHub Releases

## Instalare

### Android APK
Descarcă ultima versiune din [Releases](https://github.com/AdiVlop/aiu-dance-app/releases).

### Dezvoltare
```bash
git clone https://github.com/AdiVlop/aiu-dance-app.git
cd aiu-dance-app
flutter pub get
flutter run
```

## Versiuni

- **v1.0.0** - Prima versiune publică

## Contact

- **Email**: admin@aiudance.ro
- **Website**: https://aiu-dance.web.app
- **WhatsApp**: +40712345678

## Licență

Proprietate AIU Dance. Toate drepturile rezervate.
EOF

echo "✅ README.md creat cu succes"

# 4. Adaugă toate fișierele (exceptând cele din .gitignore)
echo "📦 Adăugăm fișierele în Git..."
git add .

# 5. Commit inițial
echo "💾 Facem commit inițial..."
git commit -m "chore: initial project import

- Adăugat structura completă Flutter
- Configurat Supabase backend
- Implementat sistemul de plăți
- Adăugat funcționalități QR
- Configurat hosting Firebase
- Pregătit pentru release v1.0.0"

# 6. Setează branch-ul principal
echo "🌿 Setăm branch-ul principal ca 'main'..."
git branch -M main

# 7. Adaugă remote-ul
echo "🔗 Adăugăm remote-ul GitHub..."
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

# 8. Push la GitHub
echo "⬆️  Facem push la GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo "✅ Push reușit!"
else
    echo "❌ Push eșuat! Verifică autentificarea GitHub."
    exit 1
fi

# 9. Verifică dacă APK-ul există
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: APK-ul nu există la: $APK_FILE"
    echo "Te rog să copiezi APK-ul pe Desktop cu numele 'AIU_Dance_APK.apk'"
    exit 1
fi

echo "📱 APK găsit: $APK_FILE"

# 10. Creează release cu GitHub CLI
echo "🚀 Creăm release-ul GitHub..."

# Verifică dacă GitHub CLI este instalat
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI nu este instalat!"
    echo "Instalează cu: brew install gh"
    exit 1
fi

# Verifică autentificarea
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Nu ești autentificat cu GitHub CLI!"
    echo "Autentifică-te cu: gh auth login"
    exit 1
fi

# Creează release-ul
gh release create "$VERSION" "$APK_FILE" \
    -R AdiVlop/aiu-dance-app \
    --title "AIU Dance $VERSION" \
    --notes "Prima versiune publică AIU Dance (Android APK).

## Funcționalități
- 🎓 Gestionare cursuri de dans
- 💰 Portofel digital integrat
- 📱 QR codes pentru prezență
- 🍹 Meniu bar cu plăți QR
- 📊 Rapoarte și statistici

## Instalare
1. Descarcă APK-ul
2. Activează 'Surse necunoscute' în Setări → Securitate
3. Instalează aplicația
4. Deschide AIU Dance

## Cerințe
- Android 6.0+ (API 23)
- 100MB spațiu liber
- Conexiune internet

## Suport
- Email: admin@aiudance.ro
- WhatsApp: +40712345678
- Website: https://aiu-dance.web.app"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Repository-ul și release-ul au fost create cu succes!"
    echo ""
    echo "🔗 URLs:"
    echo "Repository: https://github.com/AdiVlop/aiu-dance-app"
    echo "Release: https://github.com/AdiVlop/aiu-dance-app/releases/tag/$VERSION"
    echo "Download APK: https://github.com/AdiVlop/aiu-dance-app/releases/download/$VERSION/AIU_Dance_APK.apk"
    echo ""
    echo "📱 Acum poți actualiza pagina de download cu noul URL!"
else
    echo "❌ Eroare la crearea release-ului!"
    exit 1
fi

echo ""
echo "✅ Setup complet! Repository-ul GitHub este gata pentru utilizare."
