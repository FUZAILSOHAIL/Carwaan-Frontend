plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// Client keys are not committed. Copy .env.example to .env at the repo root,
// or export the same variables in the environment (environment wins).
fun loadDotEnv(envFile: java.io.File): Map<String, String> {
    if (!envFile.isFile) {
        return emptyMap()
    }
    val values = linkedMapOf<String, String>()
    for (rawLine in envFile.readLines()) {
        var line = rawLine.trim().removePrefix("\uFEFF")
        if (line.isEmpty() || line.startsWith("#")) {
            continue
        }
        if (line.startsWith("export ")) {
            line = line.removePrefix("export ").trim()
        }
        val separator = line.indexOf('=')
        if (separator <= 0) {
            continue
        }
        val key = line.substring(0, separator).trim()
        var value = line.substring(separator + 1).trim()
        if (value.length >= 2 &&
            ((value.startsWith("\"") && value.endsWith("\"")) ||
                (value.startsWith("'") && value.endsWith("'")))
        ) {
            value = value.substring(1, value.length - 1)
        }
        values[key] = value
    }
    return values
}

fun configValue(dotenv: Map<String, String>, name: String, fallback: String): String {
    val fromEnv = System.getenv(name)?.trim().orEmpty()
    if (fromEnv.isNotEmpty()) {
        return fromEnv
    }
    val fromFile = dotenv[name]?.trim().orEmpty()
    if (fromFile.isNotEmpty()) {
        return fromFile
    }
    return fallback
}

fun jsonEscape(value: String): String {
    val escaped = StringBuilder()
    for (ch in value) {
        when (ch) {
            '\\' -> escaped.append("\\\\")
            '"' -> escaped.append("\\\"")
            '\n' -> escaped.append("\\n")
            '\r' -> escaped.append("\\r")
            '\t' -> escaped.append("\\t")
            else -> escaped.append(ch)
        }
    }
    return escaped.toString()
}

val dotenv = loadDotEnv(rootProject.file("../.env"))
val googleMapsApiKey = configValue(dotenv, "GOOGLE_MAPS_API_KEY", "")
val firebaseApiKey = configValue(dotenv, "FIREBASE_API_KEY", "MISSING_FIREBASE_API_KEY")
val googleOauthClientId = configValue(dotenv, "GOOGLE_OAUTH_CLIENT_ID", "")

val googleServicesExample = file("google-services.json.example")
if (!googleServicesExample.isFile) {
    error("Missing android/app/google-services.json.example")
}
val googleServicesTemplate = googleServicesExample.readText()
if (!googleServicesTemplate.contains("__FIREBASE_API_KEY__")) {
    error("google-services.json.example is missing the __FIREBASE_API_KEY__ placeholder")
}
val generatedGoogleServices = googleServicesTemplate.replace(
    "__FIREBASE_API_KEY__",
    jsonEscape(firebaseApiKey),
)
val googleServicesJson = file("google-services.json")
if (!googleServicesJson.isFile || googleServicesJson.readText() != generatedGoogleServices) {
    googleServicesJson.writeText(generatedGoogleServices)
}

apply(plugin = "com.google.gms.google-services") // Apply it here for Firebase

android {
    namespace = "com.example.carwaan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.carwaan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add renderer configurations for better graphics performance
        resConfigs("en", "xxhdpi")
        
        // Configure OpenGL ES version
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
        
        // Injected from .env / the process environment. See .env.example.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        manifestPlaceholders["googleClientId"] = googleOauthClientId
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Disable deferred components to avoid Play Core issues
            manifestPlaceholders["enableDeferredComponents"] = false
        }
        
        debug {
            isDebuggable = true
            // Enable hardware acceleration explicitly
            manifestPlaceholders["enableHardwareAcceleration"] = true
        }
    }
}

dependencies {
    // Core library desugaring for Java 8+ features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Add OpenGL ES support libraries
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("com.google.android.material:material:1.10.0")
    
    // Add Google Play Core dependencies to fix APK build
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")
}

flutter {
    source = "../.."
}
