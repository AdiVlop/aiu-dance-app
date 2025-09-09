# Flutter and Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Stripe specific rules
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# React Native Stripe SDK
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Firebase (if still referenced)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Image picker and camera
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# QR Scanner
-keep class com.github.sbugert.rn_admob.** { *; }
-dontwarn com.github.sbugert.rn_admob.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
}




