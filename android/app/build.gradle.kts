plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

configurations.configureEach {
    // 百度地图 Flutter 插件 4.0.1+1 的 Android 工程仍传递依赖旧版
    // android.arch.lifecycle:extensions:1.1.1，但插件源码已经使用 AndroidX。
    // 精确排除该过时依赖，避免与 androidx.core 产生重复类；升级插件后应复查并删除。
    exclude(group = "android.arch.lifecycle", module = "extensions")
}

android {
    namespace = "com.example.merp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 发布前替换为公司正式 applicationId，并与签名、推送和地图平台保持一致。
        applicationId = "com.example.merp"
        // 明确锁定 API 24，即 Android 7.0。不要跟随 Flutter 默认值静默上升。
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Demo 暂用 debug 签名；生产流水线必须改用受控的 release signingConfig。
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
