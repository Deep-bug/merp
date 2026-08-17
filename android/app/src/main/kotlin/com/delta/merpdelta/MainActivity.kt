package com.delta.merpdelta

import android.webkit.CookieManager
import android.webkit.WebStorage
import android.webkit.WebView
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val WEB_DATA_CHANNEL = "com.delta.merpdelta/webview_data"
        private const val CLEAR_WEB_DATA_METHOD = "clearAllWebData"
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
