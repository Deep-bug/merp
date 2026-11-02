import java.io.FileInputStream
import java.util.Properties
import java.util.Base64
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Installation identity is independent of APP_ENV (the backend environment).
val buildProfiles = JsonSlurper().parse(rootProject.file("../config/build_profiles.json")) as Map<*, *>
val dartDefines = (project.findProperty("dart-defines") as? String).orEmpty()
    .split(',').filter { it.isNotBlank() }.associate {
        val decoded = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
        decoded.substringBefore('=') to decoded.substringAfter('=', "")
    }
// Reuse exactly the same AK as Dart. Never independently read a different local file.
val androidMapAk = dartDefines["BAIDU_MAP_ANDROID_AK"].orEmpty()
val signingFiles = mapOf("qas" to "key-qas.properties", "prd" to "key.properties")
val signingProperties = signingFiles.mapValues { (_, path) ->
    Properties().apply {
        val signingFile = rootProject.file(path)
        if (signingFile.isFile) FileInputStream(signingFile).use { load(it) }
    }
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
        // namespace stays stable; each flavor supplies its installation identity.
        applicationId = "com.delta.merpdelta"
        // 明确锁定 API 24，即 Android 7.0。不要跟随 Flutter 默认值静默上升。
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["BAIDU_MAP_ANDROID_AK"] = androidMapAk
    }

    signingConfigs {
        signingProperties.forEach { (profile, properties) ->
            if (properties.isNotEmpty()) create(profile) {
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = properties.getProperty("storeFile")?.let { file(it) }
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        buildProfiles.forEach { (name, rawProfile) ->
            val profile = name as String
            val values = rawProfile as Map<*, *>
            create(profile) {
                dimension = "environment"
                applicationId = values["androidApplicationId"] as String
                manifestPlaceholders["appName"] = values["displayName"] as String
                signingConfig = signingConfigs.findByName(if (profile == "dev") "debug" else profile)
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

androidComponents {
    // Enterprise identities are distribution-only; use dev for debug/profile runs.
    beforeVariants(selector().all()) { variant ->
        if (variant.productFlavors.any { it.second != "dev" } && variant.buildType != "release") {
            variant.enable = false
        }
    }
    onVariants(selector().withBuildType("release")) { variant ->
        // Flutter 插件会在 NDK 过滤之后合并第三方 AAR 的原生库，因此还要在
        // Release 最终包装阶段排除非 ARM64 目录。该规则同时覆盖 APK 和 AAB。
        variant.packaging.jniLibs.excludes.addAll(
            setOf(
                "**/armeabi-v7a/**",
                "**/x86/**",
                "**/x86_64/**",
            ),
        )
    }
}

gradle.taskGraph.whenReady {
    signingFiles.forEach { (profile, path) ->
        val buildsProfile = allTasks.any {
            it.project == project && it.name.contains("${profile}Release", ignoreCase = true)
        }
        if (buildsProfile) {
            val properties = signingProperties.getValue(profile)
            require(listOf("keyAlias", "keyPassword", "storeFile", "storePassword").all {
                !properties.getProperty(it).isNullOrBlank()
            }) { "Configure android/$path for $profile distribution; dev is for personal debugging." }
            require(file(properties.getProperty("storeFile")).isFile) { "Keystore file does not exist for $profile." }
            require(dartDefines["MERP_BUILD_PROFILE"] == profile && dartDefines["APP_ENV"] == profile) {
                "Build identity/API configuration mismatch. Use ./tool/app build $profile android."
            }
            require(androidMapAk.isNotBlank()) { "Missing $profile Baidu Android AK." }
        }
    }
}

flutter {
    source = "../.."
}
