#!/bin/bash
# 🔗 Tailscale後付けセットアップスクリプト
# DevContainer起動後にTailscaleを有効化

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔗 Tailscale後付けセットアップ${NC}"
echo ""

# 現在の状態確認
if pgrep -f tailscaled > /dev/null; then
    echo -e "${GREEN}✅ Tailscale は既に実行中です${NC}"
    
    # Tailscale状態確認
    if sudo tailscale status > /dev/null 2>&1; then
        CURRENT_IP=$(sudo tailscale ip -4 2>/dev/null || echo "未接続")
        echo -e "${GREEN}   現在のTailscale IP: $CURRENT_IP${NC}"
        echo ""
        echo -e "${CYAN}Tailscaleを再設定しますか？ (y/N): ${NC}"
        read -r RECONFIGURE
        if [[ ! "$RECONFIGURE" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}⚠️  セットアップをキャンセルしました${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}🔄 Tailscaleを停止中...${NC}"
        sudo tailscale down || true
        sleep 2
    fi
else
    echo -e "${YELLOW}📡 Tailscaleが未実行です - セットアップを開始します${NC}"
fi

# Auth Key の取得
echo -e "${BLUE}🔑 Tailscale Auth Key セットアップ${NC}"
echo ""
echo -e "${CYAN}Auth Key取得手順:${NC}"
echo "  1. https://login.tailscale.com/admin/settings/keys を開く"
echo "  2. 'Generate auth key' をクリック"
echo "  3. 'Reusable' と 'Ephemeral' をチェック ✅"
echo "  4. 'Generate key' をクリック"
echo "  5. 生成されたキーをコピー"
echo ""

# 既存の.envファイルから現在の設定を確認
ENV_FILE="/workspace/.env"
if [[ -f "$ENV_FILE" ]]; then
    EXISTING_KEY=$(grep "^TAILSCALE_AUTH_KEY=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
    if [[ -n "$EXISTING_KEY" && "$EXISTING_KEY" != "tskey-auth-xxxxxxxxxxxxxxxxx" && "$EXISTING_KEY" != "your-tailscale-auth-key-here" ]]; then
        echo -e "${GREEN}✅ .env ファイルに有効なAuth Keyが見つかりました${NC}"
        echo -e "${CYAN}既存のAuth Keyを使用しますか？ (Y/n): ${NC}"
        read -r USE_EXISTING
        if [[ ! "$USE_EXISTING" =~ ^[Nn]$ ]]; then
            AUTH_KEY="$EXISTING_KEY"
        fi
    fi
fi

# 新しいAuth Key入力
if [[ -z "$AUTH_KEY" ]]; then
    echo -e "${CYAN}Tailscale Auth Key を入力してください:${NC}"
    read -s -p "🔑 Auth Key: " AUTH_KEY
    echo ""
    
    if [[ -z "$AUTH_KEY" ]]; then
        echo -e "${RED}❌ Auth Keyは必須です${NC}"
        exit 1
    fi
    
    # Auth Key 形式確認
    if [[ ! "$AUTH_KEY" =~ ^tskey-auth- ]]; then
        echo -e "${YELLOW}⚠️  Auth Keyの形式が正しくない可能性があります${NC}"
        echo -e "${CYAN}続行しますか？ (y/N): ${NC}"
        read -r CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ セットアップを中断しました${NC}"
            exit 1
        fi
    fi
fi

# ホスト名設定
echo ""
echo -e "${CYAN}Tailscale ホスト名を入力してください（オプション）:${NC}"
read -p "🏷️  ホスト名（デフォルト: opencode-dev）: " HOSTNAME
HOSTNAME=${HOSTNAME:-opencode-dev}

# .env ファイル更新
echo -e "${BLUE}📝 .env ファイルを更新中...${NC}"

if [[ -f "$ENV_FILE" ]]; then
    # 既存のAuth Key行を更新
    if grep -q "^TAILSCALE_AUTH_KEY=" "$ENV_FILE"; then
        sed -i "s/^TAILSCALE_AUTH_KEY=.*/TAILSCALE_AUTH_KEY=\"$AUTH_KEY\"/" "$ENV_FILE"
    else
        echo "TAILSCALE_AUTH_KEY=\"$AUTH_KEY\"" >> "$ENV_FILE"
    fi
    
    # ホスト名更新
    if grep -q "^TAILSCALE_HOSTNAME=" "$ENV_FILE"; then
        sed -i "s/^TAILSCALE_HOSTNAME=.*/TAILSCALE_HOSTNAME=\"$HOSTNAME\"/" "$ENV_FILE"
    else
        echo "TAILSCALE_HOSTNAME=\"$HOSTNAME\"" >> "$ENV_FILE"
    fi
else
    echo -e "${RED}❌ .env ファイルが見つかりません${NC}"
    exit 1
fi

echo -e "${GREEN}✅ .env ファイルを更新しました${NC}"

# Tailscale起動
echo ""
echo -e "${BLUE}🔗 Tailscale接続中...${NC}"

# Tailscaled デーモン起動
if ! pgrep -f tailscaled > /dev/null; then
    echo "   Tailscaledデーモン開始..."
    sudo tailscaled --state-dir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &
    sleep 3
fi

# Tailscale認証
echo "   Auth Key で認証中..."
if sudo tailscale up --auth-key="$AUTH_KEY" --hostname="$HOSTNAME" --accept-routes; then
    echo -e "${GREEN}✅ Tailscale接続成功！${NC}"
    
    # IP取得
    sleep 2
    TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "IP取得中...")
    echo -e "${GREEN}   📱 Tailscale IP: $TAILSCALE_IP${NC}"
    
    # 接続状態確認
    echo ""
    echo -e "${BLUE}🌐 接続状態確認:${NC}"
    sudo tailscale status | head -5
    
else
    echo -e "${RED}❌ Tailscale接続に失敗しました${NC}"
    echo ""
    echo -e "${YELLOW}トラブルシューティング:${NC}"
    echo "  1. Auth Keyが正しいか確認"
    echo "  2. Auth Keyが期限切れでないか確認"  
    echo "  3. Tailscaleアカウントが有効か確認"
    echo "  4. 再度 ./scripts/setup-tailscale.sh を実行"
    exit 1
fi

# サービス情報表示
echo ""
echo -e "${GREEN}🎉 Tailscaleセットアップ完了！${NC}"
echo ""
echo -e "${BLUE}📱 スマートフォンからアクセス可能なURL:${NC}"

# 環境変数から現在のポート取得
source "$ENV_FILE" 2>/dev/null || true
OPENCODE_PORT=${OPENCODE_PORT:-4095}
OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-3000}

echo "   🎨 OpenChamber:     http://$TAILSCALE_IP:$OPENCHAMBER_PORT"
echo "   🤖 OpenCode CLI:    http://$TAILSCALE_IP:$OPENCODE_PORT"
echo "   🚀 プロジェクト:     http://$TAILSCALE_IP:8080"
echo ""

echo -e "${CYAN}💡 使い方:${NC}"
echo "  1. スマートフォンでTailscaleアプリを起動"
echo "  2. 同じアカウントでログイン"
echo "  3. 上記URLでOpenChamberにアクセス"
echo "  4. AIエージェントと開発開始！"
echo ""

echo -e "${YELLOW}⚠️  注意:${NC}"
echo "  - Auth Keyは一度のみ使用可能（Ephemeral設定時）"
echo "  - 再接続が必要な場合は新しいAuth Keyを生成"
echo "  - .env ファイルには機密情報が含まれるため共有注意"
echo ""

echo -e "${GREEN}✅ セットアップ完了 - モバイル開発環境の準備ができました！${NC}"