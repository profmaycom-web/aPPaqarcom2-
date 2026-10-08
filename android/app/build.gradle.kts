import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    // Kotlin is provided by Flutter's Built-in Kotlin (android.builtInKotlin=true).
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ebroker.wrteam"
    compileSdk = 36
    ndkVersion = "29.0.14033849"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.ebroker.wrteam"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString()?.takeIf { it.isNotBlank() }
            keyPassword = keystoreProperties["keyPassword"]?.toString()?.takeIf { it.isNotBlank() }
            storeFile = keystoreProperties["storeFile"]?.toString()?.takeIf { it.isNotBlank() }?.let { file(it) }
            storePassword = keystoreProperties["storePassword"]?.toString()?.takeIf { it.isNotBlank() }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        disable += setOf("InvalidPackage", "deprecation", "unchecked")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.android.support:multidex:1.0.3")
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("com.google.android.gms:play-services-ads:24.1.0")
    implementation("androidx.browser:browser:1.7.0")
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.play:integrity:1.3.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
