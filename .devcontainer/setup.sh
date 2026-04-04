#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
set -e

if [[ -d "/workspace/.devcontainer" ]]; then
    WORKSPACE_ROOT="/workspace"
else
    WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

echo "🚀 OpenCode ECC DevContainer 基盤セットアップ開始..."

# 1. 環境変数検証（セキュリティチェック）
echo "🔐 環境変数セキュリティチェック実行中..."
"$SCRIPT_DIR/env-validator.sh"

# 2. 基盤セットアップチェック
SETUP_COMPLETE_FILE="$WORKSPACE_ROOT/.devcontainer/.setup-complete"
if [[ ! -f "$SETUP_COMPLETE_FILE" ]]; then
    if is_ci_mode; then
        echo "ℹ️  CIモードのため対話セットアップをスキップします"
        touch "$SETUP_COMPLETE_FILE"
    else
        echo ""
        echo "🎯 初回セットアップが未完了です"
        echo "💡 Tailscale中心の基盤セットアップを実行することを推奨します"
        echo ""
        echo -e "\033[0;36m基盤セットアップを実行しますか？ (Y/n): \033[0m"
        read -r RUN_INTERACTIVE

        if [[ ! "$RUN_INTERACTIVE" =~ ^[Nn]$ ]]; then
            echo "🚀 基盤セットアップを開始します..."
            SKIP_EXISTING_KEY_UPDATE_PROMPT=1 "$SCRIPT_DIR/interactive-setup.sh"
        else
            echo "⚠️  基盤セットアップをスキップしました"
            echo "   後で手動実行する場合: .devcontainer/interactive-setup.sh"
        fi
    fi
else
    echo "✅ 基盤セットアップは既に完了済みです"
fi

# 環境変数の読み込み
if [ -f "$WORKSPACE_ROOT/.env" ]; then
    echo "📂 .env ファイルを読み込み中..."
    load_env_file "$WORKSPACE_ROOT/.env"
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

# .opencode ディレクトリ権限修正（EACCES エラー対策）
echo "   🔒 .opencode ディレクトリ権限設定中..."
mkdir -p ~/.opencode ~/.opencode/.agents ~/.opencode/.agents/skills
sudo chown -R vscode:vscode ~/.opencode 2>/dev/null || chown -R vscode:vscode ~/.opencode 2>/dev/null || true
chmod -R 755 ~/.opencode 2>/dev/null || true

# ajv 依存関係エラー修正（既知の問題）
echo "   🔧 ajv 依存関係修正中..."
ECC_PATH=$(npm list -g ecc-universal 2>/dev/null | head -n1 | awk '{print $1}' || echo "")
if [[ -n "$ECC_PATH" ]] && [[ -d "$ECC_PATH/node_modules/ecc-universal" ]]; then
    cd "$ECC_PATH/node_modules/ecc-universal"
    echo "     ECCディレクトリ: $(pwd)"
    npm install ajv 2>/dev/null || echo "     ajv インストール試行"
    cd - > /dev/null
fi

# ECC設定適用（ajv修正後）
ecc install --target opencode --profile ${ECC_PROFILE:-developer} || {
    echo "   ⚠️  ECC初回インストール失敗 - 依存関係修正後再試行"
    # グローバル ajv インストール（フォールバック）
    npm install -g ajv 2>/dev/null || true
    # 再試行
    ecc install --target opencode --profile ${ECC_PROFILE:-developer} || echo "   ℹ️  ECCは後で手動設定できます"
}

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

echo "✅ セットアップ完了！"
echo ""
echo "📱 次のステップ:"
echo "1. 必要なら .devcontainer/interactive-setup.sh でTailscale設定" 
echo "2. http://localhost:3000 でOpenChamberにアクセス"
echo "3. OpenCode API: http://localhost:4095"
