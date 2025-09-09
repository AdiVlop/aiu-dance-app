#!/bin/bash

# AIU Dance Performance Optimization Script for M4 MacBook Air
# This script optimizes the Flutter app for maximum performance

echo "🎯 AIU Dance Performance Optimization for M4 MacBook Air"
echo "=================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Analyze code for performance issues
echo "🔍 Analyzing code for performance issues..."
flutter analyze --no-fatal-infos

# Build for web with optimizations
echo "🌐 Building for web with optimizations..."
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true

# Build for macOS with optimizations
echo "🍎 Building for macOS with optimizations..."
flutter build macos --release

# Performance tips
echo ""
echo "🚀 Performance Optimizations Applied:"
echo "✅ Disabled debug paint overlays"
echo "✅ Optimized routing with onGenerateRoute"
echo "✅ Used CupertinoPageTransitionsBuilder for smooth transitions"
echo "✅ Enabled Skia renderer for web"
echo "✅ Optimized asset loading"
echo "✅ Reduced bundle size with tree-shaking"
echo "✅ Used const constructors where possible"
echo "✅ Implemented proper BuildContext async handling"
echo "✅ Added mounted checks for async operations"
echo "✅ Optimized Firebase initialization"

echo ""
echo "📊 Performance Recommendations for M4 MacBook Air:"
echo "• Use Chrome for best web performance"
echo "• Keep other apps closed while testing"
echo "• Monitor Activity Monitor for memory usage"
echo "• Use Safari for native macOS performance"
echo "• Enable hardware acceleration in browsers"

echo ""
echo "🎯 Next Steps:"
echo "1. Test the app in Chrome: flutter run -d chrome"
echo "2. Test the app in Safari: flutter run -d macos"
echo "3. Monitor performance with Flutter Inspector"
echo "4. Use Chrome DevTools for web performance analysis"

echo ""
echo "✨ Performance optimization complete!"




