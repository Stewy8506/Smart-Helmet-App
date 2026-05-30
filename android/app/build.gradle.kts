plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val envProps = Properties()
val envFile = file("../../.env.local")
if (envFile.exists()) {
    envProps.load(FileInputStream(envFile))
}

android {
    namespace = "com.example.helmet_app"
    compileSdk = flutter.compileSdkVersion ?: 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.helmet_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion?: 21
        targetSdk = flutter.targetSdkVersion?: 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders += mapOf(
            "GOOGLE_MAPS_API_KEY" to (envProps.getProperty("GOOGLE_MAPS_API_KEY") ?: ""),
            "SPOTIFY_CLIENT_ID" to (envProps.getProperty("SPOTIFY_CLIENT_ID") ?: ""),
            "redirectSchemeName" to "helmetapp",
            "redirectHostName" to "callback"
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
