#!/bin/bash
# 编译 SwiftUI 应用并打包成【真机 iPhone】可安装的 IPA（app 名称：1，Bundle ID：cn.juhua.app1）
# 产物：dist/1.ipa（结构 Payload/1.app）。Windows 端用 Sideloadly 以 Apple ID 重签名后装机。
# 用法：bash build_device.sh
set -e
cd "$(dirname "$0")"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
TARGET="arm64-apple-ios16.0"
export SDKROOT="$SDK"
mkdir -p build dist

echo "== 真机编译 (sdk=iphoneos, target=$TARGET)"
xcrun swiftc -parse-as-library \
  -sdk "$SDK" -target "$TARGET" -O \
  Sources/App.swift \
  -o build/1

APP=build/1.app
rm -rf "$APP"
mkdir -p "$APP"
cp build/1 "$APP/1"
cp Info.plist "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"

# 临时 ad-hoc 签名；Sideloadly 在 Windows 端会用用户的 Apple ID 身份重新签名覆盖
codesign --force --sign - "$APP" || true

echo "== 校验 Mach-O 平台（应为 ios / 非 simulator）"
file build/1 || true
otool -l build/1 2>/dev/null | grep -A3 "LC_BUILD_MACH-O" | head -8 || true

rm -rf dist/Payload dist/1.ipa
mkdir -p dist/Payload
cp -r "$APP" dist/Payload/1.app
( cd dist && zip -qr 1.ipa Payload )

echo "== 打包完成: dist/1.ipa"
ls -la dist/1.ipa
unzip -l dist/1.ipa | sed -n '1,20p'
