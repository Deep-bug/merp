// 可选协议回归：node --test test/core/bridge/bridge_script_contract_test.mjs
// 使用 Node 内置模块，不引入 npm 依赖；直接验证生产 Dart 文件内的 JS。
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const source = readFileSync(new URL('../../../lib/core/bridge/bridge_script.dart', import.meta.url), 'utf8');
const factory = source.match(/const _bridgeFactory = r'''([\s\S]*?)''';/)[1];
const origin = 'https://h5.company.test';

function page({ actualOrigin = origin, iframe = false } = {}) {
  const messages = [];
  const window = { location: { origin: actualOrigin }, dispatchEvent() {} };
  window.top = iframe ? {} : window;
  const context = {
    window,
    MerpNative: { postMessage(value) { messages.push(JSON.parse(value)); } },
    Event: class {},
    setTimeout() { return 1; },
    clearTimeout() {},
  };
  return {
    window, messages,
    inject(nonce) {
      runInNewContext(`${factory}(${JSON.stringify(nonce)}, ${JSON.stringify(origin)});`, context);
    },
  };
}

test('keeps the public API and binds messages/replies to the current document', async () => {
  const p = page();
  p.inject('nonce-a');
  const response = p.window.MERPBridge.getSession();
  const request = p.messages[0];
  assert.equal(request.action, 'auth.getSession');
  assert.equal(request.documentNonce, 'nonce-a');
  let resolved = false;
  response.then(() => { resolved = true; });
  p.window.MERPBridge._resolve(request.id, { secret: 'wrong-document' }, 'nonce-b');
  await Promise.resolve();
  assert.equal(resolved, false);
  // 同一文档重复 onPageFinished 注入，不应丢失尚未完成的 Promise。
  p.inject('nonce-a');
  p.window.MERPBridge._resolve(request.id, { authenticated: true }, 'nonce-a');
  assert.equal((await response).authenticated, true);
});

test('does not inject into another origin or a child frame', () => {
  for (const options of [{ actualOrigin: 'https://attacker.test' }, { iframe: true }]) {
    const p = page(options);
    p.inject('nonce-a');
    assert.equal(p.window.MERPBridge, undefined);
  }
});

test('new document token replaces old bridge and rejects old callbacks', async () => {
  const p = page();
  p.inject('nonce-a');
  const old = p.window.MERPBridge;
  p.inject('nonce-b');
  assert.notEqual(p.window.MERPBridge, old);
  const response = p.window.MERPBridge.call('bridge.ping', {});
  const request = p.messages[0];
  assert.equal(request.documentNonce, 'nonce-b');
  p.window.MERPBridge._reject(request.id, { code: 'TEST' }, 'nonce-b');
  await assert.rejects(response, error => error.code === 'TEST');
});
