#!/usr/bin/env bash
# 从 static/ 打包出 frontend.zip（先压缩生成 .min 文件，再打 zip）
set -e
cd "$(dirname "$0")/.."
STATIC=static
OUT=frontend.zip

echo "==> 1. 生成 .min 文件 (Node 脚本)..."
node scripts/minify.js \
  tokens.html proxies.html logs.html config.html api.html build_key.html \
  shared.js shared-styles.css

echo "==> 2. 打包为 $OUT ..."
rm -f "$OUT"
if command -v zip >/dev/null 2>&1; then
  (cd "$STATIC" && zip -q ../"$OUT" \
    route_registry.json \
    tokens.min.html proxies.min.html logs.min.html config.min.html api.min.html build_key.min.html \
    shared.min.js shared-styles.min.css)
else
  node scripts/build-zip.js
fi

echo "==> 完成: $OUT"
ls -la "$OUT"
