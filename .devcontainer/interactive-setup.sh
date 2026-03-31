#!/bin/bash
# 🚀 対話式プロジェクトセットアップ
# DevContainer初回起動時の自動プロジェクト構築

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# アスキーアート
echo -e "${CYAN}"
cat << "EOF"
  ___                   ____          _      
 / _ \ _ __   ___ _ __  / ___|___   __| | ___ 
| | | | '_ \ / _ \ '_ \| |   / _ \ / _` |/ _ \
| |_| | |_) |  __/ | | | |__| (_) | (_| |  __/
 \___/| .__/ \___|_| |_|\____\___/ \__,_|\___|
      |_|                                     
   ECC + OpenChamber + Tailscale
EOF
echo -e "${NC}"

echo -e "${GREEN}🚀 DevContainerプロジェクト初期セットアップへようこそ！${NC}"
echo ""

# セットアップ状態チェック
SETUP_COMPLETE_FILE="/workspace/.devcontainer/.setup-complete"
if [[ -f "$SETUP_COMPLETE_FILE" ]]; then
    echo -e "${YELLOW}ℹ️  このプロジェクトは既にセットアップ済みです。${NC}"
    echo -e "${CYAN}🔄 再セットアップを行いますか？ (y/N): ${NC}"
    read -r RERUN_SETUP
    if [[ ! "$RERUN_SETUP" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ セットアップをスキップします。${NC}"
        exit 0
    fi
    echo ""
fi

# 1. プロジェクト基本情報収集
echo -e "${BLUE}📝 プロジェクト基本情報を設定します${NC}"
echo ""

# プロジェクト名
echo -e "${CYAN}プロジェクト名を入力してください:${NC}"
echo -e "${YELLOW}  例: my-ai-assistant, smart-home-controller${NC}"
read -p "📁 プロジェクト名: " PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME="opencode-ecc-project"
    echo -e "${YELLOW}⚠️  デフォルト名 '$PROJECT_NAME' を使用します${NC}"
fi

# プロジェクト説明
echo ""
echo -e "${CYAN}プロジェクトの説明を入力してください:${NC}"
read -p "📖 説明: " PROJECT_DESCRIPTION
if [[ -z "$PROJECT_DESCRIPTION" ]]; then
    PROJECT_DESCRIPTION="OpenCode + ECC + OpenChamber を使用したAI開発環境"
fi

# 作者名
echo ""
echo -e "${CYAN}作者名を入力してください:${NC}"
read -p "👤 作者名: " AUTHOR_NAME
if [[ -z "$AUTHOR_NAME" ]]; then
    AUTHOR_NAME="Developer"
fi

# リポジトリURL（オプション）
echo ""
echo -e "${CYAN}GitHubリポジトリURL（オプション）:${NC}"
read -p "🔗 リポジトリURL: " REPO_URL

echo ""
echo -e "${BLUE}🔐 セキュリティ設定${NC}"

# 2. Tailscale設定
echo ""
echo -e "${CYAN}Tailscale Auth Keyを設定します${NC}"
echo -e "${YELLOW}  取得方法: https://login.tailscale.com/admin/settings/keys${NC}"
echo -e "${YELLOW}  形式: tskey-auth-xxxxxxxxxxxxxxxxx${NC}"
echo ""

# .env ファイル確認
ENV_FILE="/workspace/.env"
TAILSCALE_AUTH_KEY=""

if [[ -f "$ENV_FILE" ]]; then
    # 既存の .env ファイルから Auth Key を読み取り
    EXISTING_KEY=$(grep "^TAILSCALE_AUTH_KEY=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
    if [[ -n "$EXISTING_KEY" && "$EXISTING_KEY" != "your-tailscale-auth-key-here" ]]; then
        echo -e "${GREEN}✅ 既存のTailscale Auth Keyが見つかりました${NC}"
        echo -e "${CYAN}現在の設定を使用しますか？ (Y/n): ${NC}"
        read -r USE_EXISTING_KEY
        if [[ ! "$USE_EXISTING_KEY" =~ ^[Nn]$ ]]; then
            TAILSCALE_AUTH_KEY="$EXISTING_KEY"
        fi
    fi
fi

# Auth Key 入力
if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
    echo -e "${CYAN}Tailscale Auth Key を入力してください:${NC}"
    read -s -p "🔑 Auth Key: " TAILSCALE_AUTH_KEY
    echo ""
    
    if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
        echo -e "${RED}❌ Auth Key は必須です。後で手動で設定してください。${NC}"
        TAILSCALE_AUTH_KEY="your-tailscale-auth-key-here"
    elif [[ ! "$TAILSCALE_AUTH_KEY" =~ ^tskey-auth- ]]; then
        echo -e "${YELLOW}⚠️  Auth Key の形式が正しくない可能性があります${NC}"
    fi
fi

# Tailscaleホスト名
echo ""
echo -e "${CYAN}Tailscale ホスト名（オプション）:${NC}"
read -p "🏷️  ホスト名: " TAILSCALE_HOSTNAME
if [[ -z "$TAILSCALE_HOSTNAME" ]]; then
    TAILSCALE_HOSTNAME="${PROJECT_NAME}-dev"
fi

# 3. ECC プロファイル選択
echo ""
echo -e "${BLUE}⚙️ ECC プロファイル設定${NC}"
echo ""
echo -e "${CYAN}使用するECCプロファイルを選択してください:${NC}"
echo "  1) minimal   - 基本機能のみ（20+ スキル）"
echo "  2) developer - 開発者向け（100+ スキル）⭐ 推奨"  
echo "  3) full      - 全機能（136+ スキル）"
echo ""
read -p "選択 (1-3, デフォルト: 2): " ECC_PROFILE_CHOICE

case $ECC_PROFILE_CHOICE in
    1) ECC_PROFILE="minimal" ;;
    3) ECC_PROFILE="full" ;;
    *) ECC_PROFILE="developer" ;;
esac

echo -e "${GREEN}✅ ECCプロファイル: $ECC_PROFILE${NC}"

# 4. 設定確認
echo ""
echo -e "${PURPLE}📋 設定内容確認${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}プロジェクト名:${NC} $PROJECT_NAME"
echo -e "${CYAN}説明:${NC} $PROJECT_DESCRIPTION"  
echo -e "${CYAN}作者:${NC} $AUTHOR_NAME"
[[ -n "$REPO_URL" ]] && echo -e "${CYAN}リポジトリ:${NC} $REPO_URL"
echo -e "${CYAN}Tailscaleホスト:${NC} $TAILSCALE_HOSTNAME"
echo -e "${CYAN}ECCプロファイル:${NC} $ECC_PROFILE"
echo -e "${CYAN}Auth Key:${NC} ${TAILSCALE_AUTH_KEY:0:20}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}この設定でプロジェクトを初期化しますか？ (Y/n): ${NC}"
read -r CONFIRM_SETUP
if [[ "$CONFIRM_SETUP" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}⚠️  セットアップをキャンセルしました${NC}"
    exit 1
fi

# 5. プロジェクト初期化実行
echo ""
echo -e "${GREEN}🚀 プロジェクト初期化を開始します...${NC}"

# .env ファイル作成
echo -e "${BLUE}📝 .env ファイルを作成中...${NC}"
cat > "$ENV_FILE" << EOF
# 🔐 OpenCode ECC DevContainer 環境設定
# 生成日時: $(date)

# ============================================================================
# 🔑 必須設定
# ============================================================================

# Tailscale 認証キー（必須）
TAILSCALE_AUTH_KEY="$TAILSCALE_AUTH_KEY"

# ============================================================================  
# ⚙️ 基本設定
# ============================================================================

# プロジェクト情報
PROJECT_NAME="$PROJECT_NAME"
PROJECT_DESCRIPTION="$PROJECT_DESCRIPTION"
AUTHOR_NAME="$AUTHOR_NAME"
EOF

[[ -n "$REPO_URL" ]] && echo "REPO_URL=\"$REPO_URL\"" >> "$ENV_FILE"

cat >> "$ENV_FILE" << EOF

# Tailscale設定
TAILSCALE_HOSTNAME="$TAILSCALE_HOSTNAME"

# ECC設定  
ECC_PROFILE="$ECC_PROFILE"

# ============================================================================
# 🌐 ネットワーク設定
# ============================================================================

# OpenCode CLI
OPENCODE_HOST=0.0.0.0
OPENCODE_PORT=4095

# OpenChamber Web UI
OPENCHAMBER_HOST=0.0.0.0  
OPENCHAMBER_PORT=3000

# 開発サーバー
DEV_SERVER_PORT=8080

# ============================================================================
# 🔧 開発環境設定  
# ============================================================================

# Node.js
NODE_ENV=development

# デバッグ
DEBUG=false

# ログレベル (error, warn, info, debug)
LOG_LEVEL=info
EOF

echo -e "${GREEN}✅ .env ファイルを作成しました${NC}"

# プロジェクト専用README.md作成
echo -e "${BLUE}📖 README.md を生成中...${NC}"

cat > "/workspace/README.md" << EOF
# 🚀 $PROJECT_NAME

$PROJECT_DESCRIPTION

**作者**: $AUTHOR_NAME  
**生成日**: $(date +'%Y-%m-%d %H:%M:%S')

## 🌟 特徴

- **OpenCode CLI** - AI エージェント実行エンジン
- **Everything Claude Code (ECC)** - $ECC_PROFILE プロファイル ($(get_skill_count $ECC_PROFILE)+ スキル)
- **OpenChamber** - プレミアム Web UI（PWA対応）
- **Tailscale** - セキュアなメッシュネットワーク

## 📱 アクセス方法

### 🖥️ ローカルアクセス
- **OpenChamber UI**: http://localhost:3000
- **OpenCode CLI**: http://localhost:4095  
- **開発サーバー**: http://localhost:8080

### 🌐 リモートアクセス（Tailscale経由）
- **OpenChamber UI**: http://$TAILSCALE_HOSTNAME:3000
- **OpenCode CLI**: http://$TAILSCALE_HOSTNAME:4095
- **開発サーバー**: http://$TAILSCALE_HOSTNAME:8080

## 🚀 使い方

### 1. 開発環境起動
\`\`\`bash
# DevContainer内で実行
./scripts/start-services.sh
\`\`\`

### 2. ECC エージェント実行
\`\`\`bash
# 基本的な使い方
opencode agent list
opencode agent run my-agent

# ECC スキル実行
ecc skill list
ecc skill run code-analysis
\`\`\`

### 3. OpenChamber でAI操作
1. ブラウザでOpenChamberにアクセス
2. プロンプトでタスクを指示
3. エージェントが自動実行

## 📁 プロジェクト構造

\`\`\`
.
├── .devcontainer/          # DevContainer設定
├── .env                   # 環境変数（重要：Git管理外）
├── scripts/               # 運用スクリプト
├── src/                   # ソースコード
├── docs/                  # ドキュメント
└── README.md              # このファイル
\`\`\`

## 🔧 カスタマイズ

### ECCプロファイル変更
\`.env\` ファイルで \`ECC_PROFILE\` を変更：
- \`minimal\`: 基本機能のみ
- \`developer\`: 開発者向け  
- \`full\`: 全機能

### ポート変更
\`.env\` ファイルで各ポート番号を変更可能

## 🆘 トラブルシューティング

### Tailscale接続できない
1. Auth Keyが正しいか確認
2. Tailscaleクライアントで同じネットワークに接続
3. \`tailscale status\` でノード確認

### OpenChamberにアクセスできない  
1. \`docker-compose logs\` でログ確認
2. ポート3000が使用可能か確認
3. ファイアウォール設定確認

EOF

[[ -n "$REPO_URL" ]] && echo -e "\n## 🔗 リポジトリ\n\n$REPO_URL" >> "/workspace/README.md"

echo -e "${GREEN}✅ README.md を生成しました${NC}"

# サンプルプロジェクト構造作成
echo -e "${BLUE}📁 プロジェクト構造を初期化中...${NC}"

# src ディレクトリ
mkdir -p "/workspace/src"

# Tailscale統合ダッシュボードテンプレートからapp.js生成
if [[ -f "/workspace/.devcontainer/../templates/dashboard-with-tailscale.template.js" ]]; then
    echo -e "${BLUE}📝 Tailscale統合ダッシュボードを生成中...${NC}"
    
    # テンプレート変数置換
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{PROJECT_DESCRIPTION}}/$PROJECT_DESCRIPTION/g" \
        -e "s/{{AUTHOR_NAME}}/$AUTHOR_NAME/g" \
        -e "s/{{PROJECT_SLUG}}/$(echo $PROJECT_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')/g" \
        -e "s/{{TIMESTAMP}}/$(date)/g" \
        -e "s/{{TAILSCALE_HOSTNAME}}/$TAILSCALE_HOSTNAME/g" \
        "/workspace/.devcontainer/../templates/dashboard-with-tailscale.template.js" > "/workspace/src/app.js"
        
    echo -e "${GREEN}✅ Tailscale統合ダッシュボードを作成しました${NC}"
    echo -e "${CYAN}   🎨 http://localhost:8080 でアクセス可能${NC}"
    echo -e "${CYAN}   🔗 ダッシュボードから直接Tailscale設定可能${NC}"
    
elif [[ -f "/workspace/.devcontainer/../templates/app.template.js" ]]; then
    echo -e "${YELLOW}⚠️  Tailscale統合テンプレートが見つかりません - 基本版を作成${NC}"
    
    # テンプレート変数置換
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{PROJECT_DESCRIPTION}}/$PROJECT_DESCRIPTION/g" \
        -e "s/{{AUTHOR_NAME}}/$AUTHOR_NAME/g" \
        -e "s/{{PROJECT_SLUG}}/$(echo $PROJECT_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')/g" \
        -e "s/{{TIMESTAMP}}/$(date)/g" \
        -e "s/{{TAILSCALE_HOSTNAME}}/$TAILSCALE_HOSTNAME/g" \
        "/workspace/.devcontainer/../templates/app.template.js" > "/workspace/src/app.js"
        
else
    echo -e "${YELLOW}⚠️  テンプレートが見つかりません - 基本版を作成${NC}"
    
    # フォールバック：基本app.js
    cat > "/workspace/src/app.js" << EOF
// 🚀 $PROJECT_NAME - メインアプリケーション
// 作者: $AUTHOR_NAME
// 生成日: $(date)

const express = require('express');
const app = express();
const PORT = process.env.DEV_SERVER_PORT || 8080;

// 基本ルート
app.get('/', (req, res) => {
    res.json({
        project: "$PROJECT_NAME",
        description: "$PROJECT_DESCRIPTION",
        author: "$AUTHOR_NAME", 
        status: "🚀 運用中",
        timestamp: new Date().toISOString(),
        services: {
            opencode: "http://localhost:4095",
            openchamber: "http://localhost:3000",
            dashboard: \`http://localhost:\${PORT}\`
        }
    });
});

// ヘルスチェック
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 $PROJECT_NAME サーバーを起動しました\`);
    console.log(\`📍 http://localhost:\${PORT}\`);
});
EOF
fi

# package.json
cat > "/workspace/package.json" << EOF
{
  "name": "$(echo $PROJECT_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')",
  "version": "1.0.0",
  "description": "$PROJECT_DESCRIPTION",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "echo \\"テストを実装してください\\" && exit 1"
  },
  "author": "$AUTHOR_NAME",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "keywords": [
    "opencode",
    "ecc",
    "openchamber",
    "ai",
    "development"
  ]
}
EOF

# docs ディレクトリ
mkdir -p "/workspace/docs"
cat > "/workspace/docs/SETUP.md" << EOF
# 🛠️ $PROJECT_NAME セットアップガイド

## 📋 前提条件

- Docker & Docker Compose
- Visual Studio Code + Dev Containers 拡張機能
- Tailscaleアカウント

## 🚀 セットアップ手順

このプロジェクトは対話式セットアップで自動構築されています。

### 1. 環境確認
\`\`\`bash
# .env ファイルの確認
cat .env

# サービス状態確認  
docker-compose ps
\`\`\`

### 2. サービス起動
\`\`\`bash
./scripts/start-services.sh
\`\`\`

### 3. 動作確認
- OpenChamber: http://localhost:3000
- OpenCode CLI: http://localhost:4095
- プロジェクトApp: http://localhost:8080

## 🔧 詳細設定

設定変更は \`.env\` ファイルを編集してください。
EOF

# scripts ディレクトリの確認・作成
mkdir -p "/workspace/scripts"

# サービス起動スクリプト
cat > "/workspace/scripts/start-services.sh" << EOF
#!/bin/bash
# 🚀 $PROJECT_NAME サービス起動スクリプト

set -e

echo "🚀 $PROJECT_NAME サービスを起動しています..."

# 環境変数読み込み
if [[ -f "/workspace/.env" ]]; then
    source /workspace/.env
    echo "✅ 環境変数を読み込みました"
else
    echo "❌ .env ファイルが見つかりません"
    exit 1
fi

# Tailscale起動
echo "🔗 Tailscale接続中..."
if [[ -n "\$TAILSCALE_AUTH_KEY" && "\$TAILSCALE_AUTH_KEY" != "your-tailscale-auth-key-here" ]]; then
    sudo tailscaled --state-dir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &
    sleep 2
    sudo tailscale up --auth-key="\$TAILSCALE_AUTH_KEY" --hostname="\$TAILSCALE_HOSTNAME"
    echo "✅ Tailscale接続完了: \$TAILSCALE_HOSTNAME"
else
    echo "⚠️  Tailscale Auth Keyが設定されていません"
fi

# OpenCode CLI起動
echo "🤖 OpenCode CLI起動中..."
opencode server --host=\${OPENCODE_HOST:-0.0.0.0} --port=\${OPENCODE_PORT:-4095} &
sleep 3
echo "✅ OpenCode CLI: http://localhost:\${OPENCODE_PORT:-4095}"

# OpenChamber起動  
echo "🎨 OpenChamber起動中..."
openchamber --host=\${OPENCHAMBER_HOST:-0.0.0.0} --port=\${OPENCHAMBER_PORT:-3000} &
sleep 3
echo "✅ OpenChamber: http://localhost:\${OPENCHAMBER_PORT:-3000}"

# 開発サーバー起動
echo "⚡ 開発サーバー起動中..."
cd /workspace && npm start &
sleep 2
echo "✅ 開発サーバー: http://localhost:\${DEV_SERVER_PORT:-8080}"

echo ""
echo "🎉 全サービスの起動が完了しました！"
echo ""
echo "📱 アクセス方法:"
echo "  🎨 OpenChamber:  http://localhost:\${OPENCHAMBER_PORT:-3000}"
echo "  🤖 OpenCode CLI: http://localhost:\${OPENCODE_PORT:-4095}"  
echo "  ⚡ 開発サーバー:   http://localhost:\${DEV_SERVER_PORT:-8080}"
[[ -n "\$TAILSCALE_HOSTNAME" ]] && echo "  🌐 Tailscale:    http://\$TAILSCALE_HOSTNAME:3000"
echo ""
EOF

chmod +x "/workspace/scripts/start-services.sh"

echo -e "${GREEN}✅ プロジェクト構造を初期化しました${NC}"

# 6. セットアップ完了マーク
touch "$SETUP_COMPLETE_FILE"
echo "$(date): Interactive setup completed for project '$PROJECT_NAME'" > "$SETUP_COMPLETE_FILE"

# 最終メッセージ
echo ""
echo -e "${GREEN}🎉 プロジェクト初期化が完了しました！${NC}"
echo ""
echo -e "${PURPLE}📋 生成されたファイル:${NC}"
echo "  ✅ .env - 環境変数設定"
echo "  ✅ README.md - プロジェクト説明書" 
echo "  ✅ package.json - Node.js設定"
echo "  ✅ src/app.js - メインアプリケーション"
echo "  ✅ scripts/start-services.sh - サービス起動スクリプト"
echo "  ✅ docs/SETUP.md - セットアップガイド"
echo ""
echo -e "${CYAN}🚀 次のステップ:${NC}"
echo "  1️⃣  ./scripts/start-services.sh でサービス起動"  
echo "  2️⃣  http://localhost:3000 でOpenChamberにアクセス"
echo "  3️⃣  AIエージェントでプロジェクト開発開始！"
echo ""
echo -e "${YELLOW}💡 ヒント:${NC}"
echo "  📝 設定変更は .env ファイルを編集"
echo "  🔧 カスタマイズは package.json, src/ 以下を編集"
echo "  🆘 問題時は docs/SETUP.md を参照"
echo ""

# ヘルパー関数
function get_skill_count() {
    case $1 in
        "minimal") echo "20" ;;
        "developer") echo "100" ;;
        "full") echo "136" ;;
        *) echo "100" ;;
    esac
}