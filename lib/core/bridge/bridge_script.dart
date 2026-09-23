import 'dart:convert';

/// JS 协议独立于原生 action 分发；nonce 只存在于当前文档脚本闭包中。
String buildBridgeScript({required String nonce, required String origin}) =>
    '$_bridgeFactory(${jsonEncode(nonce)}, ${jsonEncode(origin)});';

const _bridgeFactory = r'''
(function (documentNonce, expectedOrigin) {
  if (window.top !== window || window.location.origin !== expectedOrigin) return;
  if (window.MERPBridge && window.MERPBridge._isDocument && window.MERPBridge._isDocument(documentNonce)) {
    window.dispatchEvent(new Event('MERPBridgeReady'));
    return;
  }

  var pending = {};

  function createId() {
    return Date.now().toString(36) + '_' + Math.random().toString(36).slice(2);
  }

  window.MERPBridge = {
    version: '2.4.0',
    _isDocument: function (nonce) { return nonce === documentNonce; },

    call: function (action, payload) {
      var id = createId();
      return new Promise(function (resolve, reject) {
        var timer = setTimeout(function () {
          if (!pending[id]) {
            return;
          }
          delete pending[id];
          reject({
            code: 'BRIDGE_TIMEOUT',
            message: '原生能力调用超时',
            details: { action: action }
          });
        }, 90000);
        pending[id] = { resolve: resolve, reject: reject, timer: timer };
        MerpNative.postMessage(JSON.stringify({
          id: id,
          documentNonce: documentNonce,
          action: action,
          payload: payload || {}
        }));
      });
    },

    ping: function () {
      return this.call('bridge.ping', {});
    },

    getSession: function () {
      return this.call('auth.getSession', {});
    },

    logout: function () {
      return this.call('auth.logout', {});
    },

    closePage: function (options) {
      return this.call('navigation.closePage', options || {});
    },

    getResourceManifest: function () {
      return this.call('resource.getManifest', {});
    },

    getLocale: function () {
      return this.call('app.getLocale', {});
    },

    showToast: function (message) {
      return this.call('app.showToast', { message: message });
    },

    takePhoto: function (options) {
      return this.call('camera.takePhoto', options || {});
    },

    pickFiles: function (options) {
      return this.call('file.pick', options || {});
    },

    getDeviceInfo: function () {
      return this.call('device.getInfo', {});
    },

    getCurrentPosition: function (options) {
      return this.call('location.getCurrentPosition', options || {});
    },

    scanCode: function (options) {
      return this.call('scanner.scanCode', options || {});
    },

    showSystemMessage: function (options) {
      return this.call('system.showMessage', options || {});
    },

    confirm: function (options) {
      return this.call('system.confirm', options || {});
    },

    openAppSettings: function () {
      return this.call('device.openAppSettings', {});
    },

    _resolve: function (id, data, nonce) {
      if (nonce !== documentNonce) return;
      if (!pending[id]) {
        return;
      }
      clearTimeout(pending[id].timer);
      pending[id].resolve(data);
      delete pending[id];
    },

    _reject: function (id, error, nonce) {
      if (nonce !== documentNonce) return;
      if (!pending[id]) {
        return;
      }
      clearTimeout(pending[id].timer);
      pending[id].reject(error);
      delete pending[id];
    }
  };

  window.dispatchEvent(new Event('MERPBridgeReady'));
})
''';
