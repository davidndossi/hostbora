plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    // id("com.google.firebase.crashlytics")
}

import java.util.Properties
        import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Map each Android flavor to its Dart entry point.
val flutterTarget = run {
    val tasks = gradle.startParameter.taskNames.joinToString(" ").lowercase()
    when {
        tasks.contains("prod") -> "lib/main_prod.dart"
        tasks.contains("dev") -> "lib/main_dev.dart"
        else -> "lib/main.dart"
    }
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))


    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")


    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries

    // CameraX (camera_android_camerax) references CallbackToFutureAdapter from this artifact;
    // without it, javac can fail on :camera_android_camerax:compileReleaseJavaWithJavac.
    implementation("androidx.concurrent:concurrent-futures:1.2.0")

    // Required by flutter_local_notifications (java.time APIs on older Android).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Tuya IoT: security AAR (place security-algorithm.aar in android/app/libs/)
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
}

android {
    namespace = "tz.co.artbel.paa_yangu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tz.co.artbel.paa_yangu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            resValue("string", "app_name", "Host Bora Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Host Bora")
        }
    }
    packaging {
        jniLibs {
            pickFirsts += "lib/*/libc++_shared.so"
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
    target = flutterTarget
}
