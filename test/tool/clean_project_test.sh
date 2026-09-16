#!/usr/bin/env bash
# 使用独立临时项目验证删除边界，绝不清理真实开发目录。
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FIXTURE_DIR="$(mktemp -d -t merp-clean-test)"
trap 'rm -rf -- "$FIXTURE_DIR"' EXIT
PROJECT="$FIXTURE_DIR/project with spaces"
mkdir -p "$PROJECT/tool" "$PROJECT/build/app/outputs/apk/qas/release" \
  "$PROJECT/build/app/outputs/apk/qas/debug" \
  "$PROJECT/build/app/outputs/bundle/prdRelease" \
  "$PROJECT/build/app/outputs/flutter-apk" \
  "$PROJECT/build/app/outputs/mapping/qasRelease" \
  "$PROJECT/build/app/outputs/native-debug-symbols/qasRelease" \
  "$PROJECT/build/ios/ipa" "$PROJECT/.dart_tool/flutter_build" \
  "$PROJECT/android/.gradle" "$PROJECT/android/build" "$PROJECT/ios/Pods"
cp "$SOURCE_DIR/tool/app" "$SOURCE_DIR/tool/versions" \
  "$SOURCE_DIR/tool/clean_project" "$PROJECT/tool/"
printf 'name: merp\n' > "$PROJECT/pubspec.yaml"
printf 'release apk\n' > "$PROJECT/build/app/outputs/apk/qas/release/app-qas-arm64-v8a-release.apk"
printf 'release aab\n' > "$PROJECT/build/app/outputs/bundle/prdRelease/app-prd-release.aab"
printf 'flutter release apk\n' > "$PROJECT/build/app/outputs/flutter-apk/app-qas-release.apk"
printf 'mapping\n' > "$PROJECT/build/app/outputs/mapping/qasRelease/mapping.txt"
printf 'symbols\n' > "$PROJECT/build/app/outputs/native-debug-symbols/qasRelease/native-debug-symbols.zip"
printf 'debug\n' > "$PROJECT/build/app/outputs/apk/qas/debug/app-qas-debug.apk"
printf 'ipa\n' > "$PROJECT/build/ios/ipa/merp.ipa"
printf 'keep\n' > "$PROJECT/.dart_tool/package_config.json"
printf 'keep\n' > "$PROJECT/ios/Pods/keep.txt"
printf 'keep\n' > "$PROJECT/android/key.properties"

bash "$PROJECT/tool/app" clean --dry-run
[[ -d "$PROJECT/build" && ! -e "$PROJECT/.artifacts" ]]

# 备份失败必须中止，不能进入删除阶段。
mkdir -p "$FIXTURE_DIR/failing-bin"
printf '#!/bin/sh\nexit 1\n' > "$FIXTURE_DIR/failing-bin/cp"
chmod +x "$FIXTURE_DIR/failing-bin/cp"
if PATH="$FIXTURE_DIR/failing-bin:$PATH" bash "$PROJECT/tool/app" clean --yes; then
  printf 'FAIL: 备份失败后仍返回成功\n' >&2; exit 1
fi
[[ -d "$PROJECT/build" && -d "$PROJECT/.dart_tool/flutter_build" ]]

bash "$PROJECT/tool/app" clean --yes
[[ ! -e "$PROJECT/build" && ! -e "$PROJECT/.dart_tool/flutter_build" ]]
[[ ! -e "$PROJECT/android/.gradle" && ! -e "$PROJECT/android/build" ]]
[[ -f "$PROJECT/.dart_tool/package_config.json" && -f "$PROJECT/ios/Pods/keep.txt" ]]
[[ -f "$PROJECT/android/key.properties" ]]
[[ "$(find "$PROJECT/.artifacts" -type f | wc -l | tr -d ' ')" == 5 ]]
[[ "$(find "$PROJECT/.artifacts" -name 'app-qas-arm64-v8a-release.apk' -exec cat {} \;)" == 'release apk' ]]
[[ "$(find "$PROJECT/.artifacts" -name 'app-qas-release.apk' -exec cat {} \;)" == 'flutter release apk' ]]
[[ "$(find "$PROJECT/.artifacts" -name '*.aab' -exec cat {} \;)" == 'release aab' ]]
[[ -z "$(find "$PROJECT/.artifacts" -name '*.ipa' -o -name '*debug*.apk')" ]]

# 重复清理和空产物目录在 Bash 3.2 / set -u 下也必须成功。
bash "$PROJECT/tool/app" clean --yes
ln -s "$PROJECT/ios/Pods" "$PROJECT/build"
if bash "$PROJECT/tool/app" clean --yes; then
  printf 'FAIL: 未拒绝符号链接目标\n' >&2; exit 1
fi
[[ -f "$PROJECT/ios/Pods/keep.txt" ]]
if bash "$PROJECT/tool/app" clean --unknown; then
  printf 'FAIL: 未拒绝未知参数\n' >&2; exit 1
fi
printf 'PASS: 预览、备份失败、归档校验、保留边界、重复清理、符号链接和参数检查。\n'
