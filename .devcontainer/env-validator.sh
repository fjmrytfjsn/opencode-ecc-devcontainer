#!/bin/bash
# 🔐 環境変数検証・注入スクリプト
# Tailscale Auth Key 等のセキュア設定管理

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 設定ファイルパス検出
ENV_FILE=$(resolve_env_file)
ENV_TEMPLATE=$(resolve_env_template_file)

echo -e "${BLUE}🔐 環境変数セキュリティチェック開始${NC}"

# .env ファイル存在チェック
if [[ ! -f "$ENV_FILE" ]]; then
    if [[ -f "$ENV_TEMPLATE" ]]; then
        echo -e "${YELLOW}⚠️  .env ファイルが見つかりません。テンプレートからコピーします...${NC}"
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        echo -e "${GREEN}✅ .env.template から .env を作成しました${NC}"
    else
        echo -e "${RED}❌ .env.template も見つかりません${NC}"
        exit 1
    fi
fi

# 必須環境変数チェック
echo -e "${CYAN}🔍 必須環境変数をチェック中...${NC}"

load_env_file "$ENV_FILE"

# Tailscale Auth Key 検証
if ! is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo -e "${YELLOW}⚠️  TAILSCALE_AUTH_KEY が未設定です（ローカルモードで利用可能）${NC}"
    echo ""
    echo -e "${YELLOW}📝 Tailscale Auth Key 設定手順:${NC}"
    echo "  1. https://login.tailscale.com/admin/settings/keys にアクセス"
    echo "  2. 'Generate auth key' をクリック"
    echo "  3. 'Reusable' と 'Ephemeral' をチェック"
    echo "  4. 生成されたキーを .env ファイルに設定"
    echo ""
    echo -e "${CYAN}今すぐ設定しますか？ (y/N): ${NC}"
    read -r SET_AUTH_KEY
    
    if [[ "$SET_AUTH_KEY" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Tailscale Auth Key を入力してください:${NC}"
        read -s -p "🔑 Auth Key: " NEW_AUTH_KEY
        echo ""
        
        if is_valid_tailscale_key "$NEW_AUTH_KEY"; then
            # .env ファイル更新
            upsert_env_value "$ENV_FILE" "TAILSCALE_AUTH_KEY" "$NEW_AUTH_KEY"
            echo -e "${GREEN}✅ Tailscale Auth Key を設定しました${NC}"
            TAILSCALE_AUTH_KEY="$NEW_AUTH_KEY"
        else
            echo -e "${YELLOW}⚠️  無効なAuth Keyです。後で手動で設定してください${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  後で手動で設定してください${NC}"
    fi
fi

# Auth Key 形式チェック
if [[ -n "$TAILSCALE_AUTH_KEY" ]]; then
    if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
        echo -e "${GREEN}✅ Tailscale Auth Key: 正常${NC}"
    elif ! is_placeholder_tailscale_key "$TAILSCALE_AUTH_KEY"; then
        echo -e "${YELLOW}⚠️  Auth Key の形式が正しくない可能性があります${NC}"
    fi
fi

# ECC プロファイル検証
VALID_PROFILES=("minimal" "developer" "full")
if [[ -n "$ECC_PROFILE" ]]; then
    if [[ " ${VALID_PROFILES[@]} " =~ " $ECC_PROFILE " ]]; then
        echo -e "${GREEN}✅ ECC Profile: $ECC_PROFILE${NC}"
    else
        echo -e "${YELLOW}⚠️  無効なECCプロファイル: $ECC_PROFILE${NC}"
        echo -e "${CYAN}有効なプロファイル: ${VALID_PROFILES[*]}${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ECC_PROFILE が未設定（デフォルト: developer）${NC}"
fi

# ポート競合チェック
PORTS=("$OPENCODE_PORT" "$OPENCHAMBER_PORT")
DEFAULT_PORTS=("4095" "3000")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]:-${DEFAULT_PORTS[$i]}}
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep ":$PORT " &> /dev/null; then
            echo -e "${YELLOW}⚠️  ポート $PORT は既に使用されています${NC}"
        else
            echo -e "${GREEN}✅ ポート $PORT: 使用可能${NC}"
        fi
    fi
done

# ファイル権限チェック
echo -e "${CYAN}🔒 ファイル権限をチェック中...${NC}"

# .env ファイルの権限を制限（機密情報保護）
ensure_env_permissions "$ENV_FILE"
echo -e "${GREEN}✅ .env ファイル権限: 600 (所有者のみ読み書き)${NC}"

# スクリプトファイルの実行権限
SCRIPTS_DIR="/workspace/scripts"
if [[ -d "$SCRIPTS_DIR" ]]; then
    find "$SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \;
    echo -e "${GREEN}✅ スクリプト実行権限を設定しました${NC}"
fi

# Git セキュリティチェック
if [[ -f "/workspace/.gitignore" ]]; then
    if grep -q "\.env" "/workspace/.gitignore"; then
        echo -e "${GREEN}✅ .env ファイルがGit管理対象外に設定済み${NC}"
    else
        echo -e "${YELLOW}⚠️  .env ファイルをGit管理対象外に追加します${NC}"
        echo ".env" >> "/workspace/.gitignore"
        echo -e "${GREEN}✅ .gitignore に .env を追加しました${NC}"
    fi
fi

# セキュリティサマリー
echo ""
echo -e "${BLUE}🔐 セキュリティチェック完了${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Auth Key 状態
if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo -e "${GREEN}🔑 Tailscale Auth Key: 設定済み${NC}"
else
    echo -e "${RED}🔑 Tailscale Auth Key: 未設定${NC}"
fi

# 運用モード
echo -e "${GREEN}🏗️ 基盤モード: 有効${NC}"

# ファイル保護
echo -e "${GREEN}🔒 ファイル保護: 有効${NC}"
echo -e "${GREEN}🚫 Git除外設定: 有効${NC}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 最終確認
if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo -e "${GREEN}✅ セキュリティ設定完了 - 安全に使用できます${NC}"
else
    echo -e "${YELLOW}✅ セキュリティ設定完了 - Tailscale未設定のためローカルモードです${NC}"
fi
