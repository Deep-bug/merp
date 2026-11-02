pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            if (localPropertiesFile.isFile) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }

            val configuredFlutterSdk =
                properties
                    .getProperty("flutter.sdk")
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                    ?.let { file(it) }
            val projectFvmFlutterSdk = file("../.fvm/flutter_sdk")
            val flutterGradlePluginPath = "packages/flutter_tools/gradle"
            val flutterSdkDirectory =
                listOfNotNull(configuredFlutterSdk, projectFvmFlutterSdk).firstOrNull {
                    it.resolve(flutterGradlePluginPath).isDirectory
                }

            requireNotNull(flutterSdkDirectory) {
                "Flutter SDK not found. Run ./tool/bootstrap (macOS) from the project root, " +
                    "or configure flutter.sdk in android/local.properties."
            }

            var localPropertiesChanged = false
            if (configuredFlutterSdk?.absolutePath != flutterSdkDirectory.absolutePath) {
                properties.setProperty("flutter.sdk", flutterSdkDirectory.absolutePath)
                localPropertiesChanged = true
            }

            val configuredAndroidSdk =
                properties
                    .getProperty("sdk.dir")
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                    ?.let { file(it) }
                    ?.takeIf { it.isDirectory }
            if (configuredAndroidSdk == null) {
                val androidSdkDirectory =
                    listOfNotNull(
                        System.getenv("ANDROID_SDK_ROOT"),
                        System.getenv("ANDROID_HOME"),
                        "${System.getProperty("user.home")}/Library/Android/sdk",
                    ).asSequence()
                        .map { file(it) }
                        .firstOrNull { it.isDirectory }
                if (androidSdkDirectory != null) {
                    properties.setProperty("sdk.dir", androidSdkDirectory.absolutePath)
                    localPropertiesChanged = true
                }
            }

            if (localPropertiesChanged || !localPropertiesFile.exists()) {
                localPropertiesFile.outputStream().use {
                    properties.store(it, "Generated locally by MERP Android configuration")
                }
            }

            flutterSdkDirectory.absolutePath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // 备选国内镜像，防止 VPN 波动
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
