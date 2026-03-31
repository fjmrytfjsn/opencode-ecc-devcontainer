#!/bin/bash
set -e

echo "🚀 OpenCode ECC DevContainer セットアップ開始..."

# 1. 環境変数検証（セキュリティチェック）
echo "🔐 環境変数セキュリティチェック実行中..."
/workspace/.devcontainer/env-validator.sh

# 2. 対話式セットアップチェック
SETUP_COMPLETE_FILE="/workspace/.devcontainer/.setup-complete"
if [[ ! -f "$SETUP_COMPLETE_FILE" ]]; then
    echo ""
    echo "🎯 初回セットアップが未完了です"
    echo "💡 対話式セットアップを実行して、プロジェクトを初期化することを推奨します"
    echo ""
    echo -e "\033[0;36m対話式セットアップを実行しますか？ (Y/n): \033[0m"
    read -r RUN_INTERACTIVE
    
    if [[ ! "$RUN_INTERACTIVE" =~ ^[Nn]$ ]]; then
        echo "🚀 対話式セットアップを開始します..."
        /workspace/.devcontainer/interactive-setup.sh
    else
        echo "⚠️  対話式セットアップをスキップしました"
        echo "   後で手動実行する場合: .devcontainer/interactive-setup.sh"
    fi
else
    echo "✅ プロジェクトは既に初期化済みです"
fi

# 環境変数の読み込み
if [ -f "/workspace/.env" ]; then
    echo "📂 .env ファイルを読み込み中..."
    export $(grep -v '^#' /workspace/.env | xargs) 2>/dev/null || true
fi

# OpenCode CLI の確認・インストール
echo "🛠️  OpenCode CLI セットアップ..."
if ! command -v opencode &> /dev/null; then
    echo "   OpenCode CLI をインストール中..."
    npm install -g @opencode-ai/cli
else
    echo "   ✅ OpenCode CLI 既にインストール済み: $(opencode --version)"
fi

# OpenChamber の確認・インストール
echo "🌐 OpenChamber セットアップ..."
if ! command -v openchamber &> /dev/null; then
    echo "   OpenChamber をインストール中..."
    npm install -g @openchamber/web
else
    echo "   ✅ OpenChamber 既にインストール済み"
fi

# ECC の確認・インストール・設定
echo "🎯 ECC (Everything Claude Code) セットアップ..."
if ! command -v ecc &> /dev/null; then
    echo "   ECC をインストール中..."
    npm install -g ecc-universal
fi

# ECC の設定適用
echo "   ECC設定を適用中..."
mkdir -p ~/.opencode
ecc install --target opencode --profile ${ECC_PROFILE:-developer} || true

# OpenCode設定ファイルの作成
echo "📝 OpenCode設定ファイル作成..."
cat > ~/.opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5", 
  "default_agent": "build",
  "plugin": [
    "./plugins"
  ]
}
EOF

# npm依存関係インストール（プロジェクトがpackage.jsonを持つ場合）
if [[ -f "/workspace/package.json" ]]; then
    echo "📦 プロジェクト依存関係をインストール中..."
    cd /workspace
    npm install
    echo "✅ 依存関係のインストール完了"
fi

echo "✅ セットアップ完了！"
echo ""
echo "📱 次のステップ:"
echo "1. ./scripts/start-services.sh でサービス起動" 
echo "2. http://localhost:3000 でOpenChamberにアクセス"
echo "3. AIエージェントでプロジェクト開発開始！"
