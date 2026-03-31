#!/bin/bash
# 🚀 高速ビルド用スクリプト
# Docker Buildx を活用してマルチキャッシュ並列ビルド

set -e

echo "🚀 最適化ビルド開始..."

# Buildx 有効化
docker buildx create --use --name opencode-builder 2>/dev/null || true

# 並列ビルド実行（キャッシュ最適化）
docker buildx build \
  --target final \
  --cache-from type=local,src=/tmp/.buildx-cache \
  --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
  --load \
  --progress=plain \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -f .devcontainer/Dockerfile \
  -t opencode-ecc-devcontainer:latest \
  .

# キャッシュ更新
rm -rf /tmp/.buildx-cache
mv /tmp/.buildx-cache-new /tmp/.buildx-cache

echo "✅ 最適化ビルド完了！"