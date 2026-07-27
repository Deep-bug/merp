import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun readLocalBaiduMapAk(): String {
    val file = rootProject.file("../config/baidu_map.local.json")
    if (!file.exists()) {
        return ""
    }
    val match = Regex("\"BAIDU_MAP_ANDROID_AK\"\\s*:\\s*\"([^\"]*)\"")
        .find(file.readText())
    return match?.groupValues?.get(1).orEmpty()
}

val releaseSigningProperties = Properties()
val releaseSigningFile = rootProject.file("key.properties")
val hasReleaseSigning = releaseSigningFile.exists()
if (hasReleaseSigning) {
    FileInputStream(releaseSigningFile).use(releaseSigningProperties::load)
}

configurations.configureEach {
    // 百度地图 Flutter 插件 4.0.1+1 的 Android 工程仍传递依赖旧版
    // android.arch.lifecycle:extensions:1.1.1，但插件源码已经使用 AndroidX。
    // 精确排除该过时依赖，避免与 androidx.core 产生重复类；升级插件后应复查并删除。
    exclude(group = "android.arch.lifecycle", module = "extensions")
}

android {
    namespace = "com.delta.merpdelta"
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
        // 现有包标识作为 PRD Application ID 保留；QAS 在 flavor 中追加后缀。
        applicationId = "com.delta.merpdelta"
        // 明确锁定 API 24，即 Android 7.0。不要跟随 Flutter 默认值静默上升。
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["BAIDU_MAP_ANDROID_AK"] = readLocalBaiduMapAk()
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
                storeFile = file(releaseSigningProperties.getProperty("storeFile"))
                storePassword = releaseSigningProperties.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("qas") {
            dimension = "environment"
            applicationIdSuffix = ".qas"
            manifestPlaceholders["appName"] = "MERP QAS"
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prd") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "MERP"
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsPrdRelease = gradle.startParameter.taskNames.any {
        it.contains("PrdRelease", ignoreCase = true)
    }
    if (buildsPrdRelease && !hasReleaseSigning) {
        throw GradleException(
            "PRD release signing is not configured. Create android/key.properties " +
                "and reference a protected production keystore. Debug signing is never used for PRD.",
        )
    }
}

flutter {
    source = "../.."
}
