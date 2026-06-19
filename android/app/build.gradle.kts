plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.horria_t"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.horria_t"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
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
    implementation(files("../libs/lepu-blepro-1.3.1.aar"))
    implementation("com.guolindev.permissionx:permissionx:1.8.1")
    implementation("io.github.jeremyliao:live-event-bus-x:1.8.0")
    implementation("no.nordicsemi.android:ble:2.11.0")
    
    // Lifecycle dependencies often needed by LiveEventBus and Lepu SDK
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.8.7")

    // Missing dependencies for Lepu SDK
    implementation("io.getstream:stream-log:1.1.4")
    implementation("io.getstream:stream-log-android:1.1.4")
    implementation("io.getstream:stream-log-file:1.1.4")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("io.getstream:stream-log-android:1.1.4")
    implementation("io.getstream:stream-log-android-file:1.1.4")
}
