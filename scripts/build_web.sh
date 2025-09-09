#!/bin/bash

# AIU Dance Web Build Script
# Optimized for production web deployment

echo "🚀 Starting AIU Dance Web Build Process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Analyze code for errors
echo "🔍 Analyzing code..."
flutter analyze

# Run tests (if any)
echo "🧪 Running tests..."
flutter test

# Build for web with optimizations
echo "🌐 Building for web with optimizations..."
flutter build web \
  --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --web-renderer canvaskit \
  --pwa-strategy offline-first \
  --base-href "/" \
  --source-maps

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Web build completed successfully!"
    echo "📁 Build files are in: build/web/"
    echo "🌐 To serve locally: flutter run -d chrome --release"
    echo "📊 Build size:"
    du -sh build/web/
else
    echo "❌ Web build failed!"
    exit 1
fi

# Optional: Deploy to Firebase Hosting (if configured)
if [ -f "firebase.json" ]; then
    echo "🔥 Deploying to Firebase Hosting..."
    firebase deploy --only hosting
fi

echo "🎉 Build process completed!"

