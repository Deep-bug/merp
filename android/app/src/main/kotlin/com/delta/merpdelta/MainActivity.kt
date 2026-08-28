package com.delta.merpdelta

import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import android.webkit.CookieManager
import android.webkit.WebStorage
import android.webkit.WebView
import java.io.File
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val WEB_DATA_CHANNEL = "com.delta.merpdelta/webview_data"
        private const val CLEAR_WEB_DATA_METHOD = "clearAllWebData"
        private const val APP_UPDATE_CHANNEL = "com.delta.merpdelta/app_update"
        private const val INSTALL_APK_METHOD = "installApk"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEB_DATA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    CLEAR_WEB_DATA_METHOD -> clearAllWebData(result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    INSTALL_APK_METHOD -> installApk(call.argument("filePath"), result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * APK 必须位于当前应用 cacheDir 下，FileProvider 只向系统安装器临时授权读取。
     * Android 8+ 未授予“安装未知应用”时，先打开当前应用的系统授权页。
     */
    private fun installApk(filePath: String?, result: MethodChannel.Result) {
        if (filePath.isNullOrBlank()) {
            result.error("APK_PATH_MISSING", "升级包路径为空", null)
            return
        }
        try {
            val apkFile = File(filePath).canonicalFile
            val cacheRoot = cacheDir.canonicalFile
            if (!apkFile.path.startsWith(cacheRoot.path + File.separator) || !apkFile.isFile) {
                result.error("APK_PATH_INVALID", "升级包不在允许的缓存目录或文件不存在", null)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !packageManager.canRequestPackageInstalls()
            ) {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        android.net.Uri.parse("package:$packageName"),
                    ),
                )
                result.success("permissionOpened")
                return
            }

            val apkUri = FileProvider.getUriForFile(
                this,
                "$packageName.update_file_provider",
                apkFile,
            )
            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(installIntent)
            result.success("installerOpened")
        } catch (error: Exception) {
            result.error("APK_INSTALL_FAILED", error.message, null)
        }
    }

    /**
     * 清理的仅是 Android System WebView 维护的网站数据。
     *
     * 不会访问 FlutterSecureStorage、SharedPreferences 或 App 文件目录，因此不会
     * 删除 MERP 的 Token、收藏、语言、服务器和解锁设置。
     */
    private fun clearAllWebData(result: MethodChannel.Result) {
        try {
            // clearCache(true) 是 WebView 级别的全局资源缓存；临时创建实例不会展示页面。
            WebView(this).apply {
                clearCache(true)
                clearHistory()
                clearFormData()
                destroy()
            }

            // 删除 Vue/H5 可能保存的 LocalStorage、IndexedDB 与离线站点数据。
            WebStorage.getInstance().deleteAllData()

            // Cookie 删除是异步 API，完成后再向 Flutter 回传成功，避免用户立即重开页面
            // 时仍读取到旧的网页登录态。
            val cookieManager = CookieManager.getInstance()
            cookieManager.removeAllCookies {
                cookieManager.flush()
                result.success(true)
            }
        } catch (error: Exception) {
            result.error("WEB_DATA_CLEAR_FAILED", error.message, null)
        }
    }
}
