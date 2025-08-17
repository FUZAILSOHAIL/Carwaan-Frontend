# Flutter Specific ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core rules to fix APK build
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn com.google.android.play.core.**

# OpenGL ES Configuration
-keep public class javax.microedition.khronos.** { *; }
-keep public class android.opengl.** { *; }
-keep public class com.example.carwaan.MainActivity { *; }

# Keep the EGL classes to avoid the "unimplemented OpenGL ES API" errors
-keep class javax.microedition.khronos.egl.** { *; }
-keep class android.opengl.** { *; }
-keep class android.graphics.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep onClick handlers for the UI
-keepclassmembers class * extends android.view.View {
    public void *(android.view.View);
    public void set*(***);
    public *** get*();
}

# For native libraries
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Flutter engine
-keep class io.flutter.embedding.engine.** { *; }