
import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
if (flutterVersionCode == null) {
    throw GradleException("versionCode not found. Define flutter.versionCode in the local.properties file.")
}

val flutterVersionName = localProperties.getProperty("flutter.versionName")
if (flutterVersionName == null) {
    throw GradleException("versionName not found. Define flutter.versionName in the local.properties file.")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.pos_mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.pos_mobile"
        // Min SDK 28 (Android 9 Pie) - Modern devices
        minSdk = 28
        // Target SDK 34 (Android 14) - Latest stable
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        
        // Enable multidex for larger apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Product Flavors for different environments
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Machos POS (Dev)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Machos POS")
        }
    }


    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            if (variant.buildType.name == "release") {
                val flavorName = variant.flavorName.replaceFirstChar { it.uppercase() }
                output.outputFileName = "Macho's POS ${flavorName} v${variant.versionName}.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}
