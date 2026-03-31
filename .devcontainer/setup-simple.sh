#!/bin/bash

# OpenCode ECC DevContainer セットアップスクリプト
# DevContainer 作成時に一度だけ実行される（ai-harness-template ベース）

set -e

echo "🚀 OpenCode ECC + OpenChamber 環境をセットアップ中..."
echo "=============================================="

# 基本パッケージの確認・インストール
echo "📦 基本パッケージ確認中..."
sudo apt-get update -y
sudo apt-get install -y curl wget unzip build-essential

# Tailscale をインストール
if ! command -v tailscale >/dev/null 2>&1; then
    echo "📦 Tailscale をインストール中..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# uv (Python パッケージマネージャー) をインストール
if ! command -v uv >/dev/null 2>&1; then
    echo "📦 uv (Python パッケージマネージャー) をインストール中..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Node.js とnpmのバージョン確認
echo "📦 Node.js: $(node --version)"
echo "📦 npm: $(npm --version)"  
echo "📦 Python: $(python --version)"

# OpenCode AI をグローバルインストール
echo "⬇️  OpenCode AI をインストール中..."
OPENCODE_VERSION="${OPENCODE_VERSION:-1.3.9}"
if npm install -g "opencode-ai@${OPENCODE_VERSION}"; then
    echo "✅ OpenCode AI インストール完了"
else
    echo "⚠️  OpenCode AI インストール失敗（継続します）"
fi

# OpenChamber をグローバルインストール
echo "⬇️  OpenChamber をインストール中..."
if npm install -g @openchamber/web; then
    echo "✅ OpenChamber インストール完了"
else
    echo "⚠️  OpenChamber インストール失敗（継続します）"
fi

# ECC (everything-claude-code) をインストール
echo "⬇️  ECC をインストール中..."
if npm install -g ecc-universal; then
    echo "✅ ECC インストール完了"
    
    # ECC の依存関係修正（ajv問題対策）
    echo "🔧 ECC 依存関係修正中..."
    ECC_DIR=$(npm list -g ecc-universal 2>/dev/null | head -n1 | awk '{print $1}')/node_modules/ecc-universal
    if [ -d "$ECC_DIR" ]; then
        cd "$ECC_DIR"
        npm install ajv 2>/dev/null || true
        npm install 2>/dev/null || true
        cd - >/dev/null
        echo "✅ ECC 依存関係修正完了"
    fi
else
    echo "⚠️  ECC インストール失敗（継続します）"
fi

# .opencode ディレクトリの権限設定（権限問題対策）
echo "🔧 .opencode ディレクトリ権限設定中..."
mkdir -p /home/vscode/.opencode
sudo chown -R vscode:vscode /home/vscode/.opencode
chmod -R 755 /home/vscode/.opencode
chmod -R u+w /home/vscode/.opencode
echo "✅ .opencode 権限設定完了"

# プロジェクト用のディレクトリ作成
mkdir -p .opencode-logs
mkdir -p .temp

# 権限設定
chmod +x scripts/* 2>/dev/null || true

# .env ファイル作成
if [ ! -f ".env" ] && [ -f ".env.template" ]; then
    cp .env.template .env
    echo "✅ .env ファイルを作成しました"
fi

echo ""
echo "✅ 全セットアップ完了!"
echo ""
echo "🎯 利用可能なサービス:"
echo "   - OpenChamber Web UI: ポート 3000"
echo "   - OpenCode CLI Server: ポート 4095"
echo "   - Development Server: ポート 8080"
echo ""
echo "📝 すぐに始められます:"
echo "   1. VS Code の 'PORTS' タブから各サービスにアクセス"
echo "   2. OpenChamber でAIコーディングを開始!"
echo "   3. Tailscale設定が必要な場合は .env を編集"
echo ""