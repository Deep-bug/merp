import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/bridge/merp_native_bridge.dart';

class BridgeTestPage extends StatefulWidget {
  const BridgeTestPage({super.key});

  @override
  State<BridgeTestPage> createState() => _BridgeTestPageState();
}

class _BridgeTestPageState extends State<BridgeTestPage> {
  WebViewController? _controller;
  MerpNativeBridge? _bridge;
  var _progress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _createController();
    }
  }

  void _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageFinished: (_) => _bridge?.inject(),
        ),
      );

    final bridge = MerpNativeBridge(context: context, controller: controller);
    controller
      ..addJavaScriptChannel(
        MerpNativeBridge.channelName,
        onMessageReceived: (message) => bridge.handleMessage(message.message),
      )
      ..loadHtmlString(_bridgeTestHtml);

    _bridge = bridge;
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.chevron_left),
        ),
        title: const Text('WebView Bridge 测试'),
        centerTitle: true,
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                WebViewWidget(controller: controller),
                if (_progress < 100)
                  LinearProgressIndicator(value: _progress / 100),
              ],
            ),
    );
  }
}

const _bridgeTestHtml = r'''
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <title>MERP Bridge Test</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f5f7fb;
      color: #263241;
    }
    .header {
      padding: 22px 18px 16px;
      background: linear-gradient(135deg, #5e93e5, #23a6d5);
      color: #fff;
    }
    .header h1 { margin: 0; font-size: 22px; }
    .header p { margin: 8px 0 0; opacity: .88; line-height: 1.5; }
    .panel {
      margin: 14px;
      padding: 14px;
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 8px 24px rgba(41, 67, 92, .10);
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
    }
    button {
      border: 0;
      border-radius: 8px;
      padding: 12px 10px;
      background: #5e93e5;
      color: white;
      font-size: 14px;
      font-weight: 700;
    }
    button.secondary { background: #eef4ff; color: #315fa8; }
    button.danger { background: #fff0f0; color: #b3261e; }
    pre {
      margin: 10px 0 0;
      padding: 12px;
      min-height: 180px;
      overflow: auto;
      white-space: pre-wrap;
      word-break: break-word;
      background: #111827;
      color: #d1fae5;
      border-radius: 8px;
      font-size: 12px;
      line-height: 1.45;
    }
    .status {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 10px;
      border-radius: 999px;
      background: #eef4ff;
      color: #315fa8;
      font-size: 12px;
      font-weight: 700;
    }
    .dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #a3aab7;
    }
    .dot.ok { background: #00a884; }
    img {
      display: block;
      max-width: 100%;
      border-radius: 8px;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>MERP Vue Bridge 测试页</h1>
    <p>该页面运行在 Flutter WebView 中，用于验证 Vue2/H5 通过 window.MERPBridge 调用手机端能力。</p>
  </div>

  <div class="panel">
    <span class="status"><span id="dot" class="dot"></span><span id="statusText">等待 Bridge 注入</span></span>
    <pre id="log">页面已加载，等待 Flutter 注入 window.MERPBridge...</pre>
  </div>

  <div class="panel">
    <div class="grid">
      <button onclick="ping()">Ping Flutter</button>
      <button onclick="getSession()">读取登录态</button>
      <button onclick="getManifest()">读取资源清单</button>
      <button onclick="showToast()">调用 Toast</button>
      <button class="secondary" onclick="takePhoto(false)">拍照-仅路径</button>
      <button class="secondary" onclick="takePhoto(true)">拍照-base64预览</button>
      <button class="danger" onclick="badAction()">异常测试</button>
      <button class="secondary" onclick="clearLog()">清空日志</button>
    </div>
    <img id="preview" alt="" />
  </div>

  <script>
    function pretty(value) {
      return JSON.stringify(value, null, 2);
    }

    function write(title, value) {
      document.getElementById('log').textContent =
        '[' + new Date().toLocaleTimeString() + '] ' + title + '\n' + pretty(value);
    }

    function writeError(title, error) {
      document.getElementById('log').textContent =
        '[' + new Date().toLocaleTimeString() + '] ' + title + '\n' + pretty(error);
    }

    function markReady() {
      var ready = !!window.MERPBridge;
      document.getElementById('dot').className = ready ? 'dot ok' : 'dot';
      document.getElementById('statusText').textContent =
        ready ? 'Bridge 已注入：' + window.MERPBridge.version : '等待 Bridge 注入';
      if (ready) {
        write('Bridge ready', { version: window.MERPBridge.version });
      }
    }

    function ensureBridge() {
      if (!window.MERPBridge) {
        throw { code: 'WEB_BRIDGE_NOT_READY', message: 'window.MERPBridge 尚未注入' };
      }
      return window.MERPBridge;
    }

    async function ping() {
      try {
        write('bridge.ping 请求中...', {});
        write('bridge.ping 成功', await ensureBridge().ping());
      } catch (error) {
        writeError('bridge.ping 失败', error);
      }
    }

    async function getSession() {
      try {
        write('auth.getSession 请求中...', {});
        write('auth.getSession 成功', await ensureBridge().getSession());
      } catch (error) {
        writeError('auth.getSession 失败', error);
      }
    }

    async function getManifest() {
      try {
        write('resource.getManifest 请求中...', {});
        write('resource.getManifest 成功', await ensureBridge().getResourceManifest());
      } catch (error) {
        writeError('resource.getManifest 失败', error);
      }
    }

    async function showToast() {
      try {
        write('app.showToast 请求中...', {});
        write('app.showToast 成功', await ensureBridge().showToast('Vue 页面调用 Flutter Toast 成功'));
      } catch (error) {
        writeError('app.showToast 失败', error);
      }
    }

    async function takePhoto(includeBase64) {
      try {
        write('camera.takePhoto 请求中...', { includeBase64: includeBase64 });
        var result = await ensureBridge().takePhoto({
          includeBase64: includeBase64,
          imageQuality: 80,
          maxWidth: 1280
        });
        write('camera.takePhoto 成功', result);
        if (result.dataUrl) {
          document.getElementById('preview').src = result.dataUrl;
        }
      } catch (error) {
        writeError('camera.takePhoto 失败', error);
      }
    }

    async function badAction() {
      try {
        write('unsupported.action 请求中...', {});
        write('unsupported.action 成功', await ensureBridge().call('unsupported.action', {}));
      } catch (error) {
        writeError('unsupported.action 按预期失败', error);
      }
    }

    function clearLog() {
      document.getElementById('log').textContent = '';
      document.getElementById('preview').removeAttribute('src');
    }

    window.addEventListener('MERPBridgeReady', markReady);
    setTimeout(markReady, 300);
    setTimeout(markReady, 1000);
  </script>
</body>
</html>
''';
