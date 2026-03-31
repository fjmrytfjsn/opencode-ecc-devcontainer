#!/bin/bash
set -e

echo "🌟 OpenCode ECC DevContainer 起動中..."

# 環境変数の読み込み
if [ -f "/workspace/.env" ]; then
    echo "📂 .env ファイルから環境変数読み込み..."
    export $(grep -v '^#' /workspace/.env | xargs) 2>/dev/null || true
fi

# ネットワーク情報の自動検出
detect_network_info() {
    # Docker内部IP取得
    CONTAINER_IP=$(hostname -i 2>/dev/null | awk '{print $1}' || echo "未検出")
    
    # ホストのLAN IP推測（eth0から）
    HOST_LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+' || echo "未検出")
    
    # 利用可能ポート確認
    OPENCODE_PORT=${OPENCODE_PORT:-4095}
    OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-3000}
    SAMPLE_PORT=8080
    
    echo "🌐 ネットワーク情報自動検出完了"
    echo "   コンテナIP: $CONTAINER_IP"
    echo "   ホストLAN IP: $HOST_LAN_IP"
}

detect_network_info

# Tailscale設定状況の確認と分岐
AUTH_KEY_VALID=false
if [ -n "$TAILSCALE_AUTH_KEY" ] && [ "$TAILSCALE_AUTH_KEY" != "tskey-auth-xxxxxxxxxxxxxxxxx" ] && [ "$TAILSCALE_AUTH_KEY" != "your-tailscale-auth-key-here" ]; then
    AUTH_KEY_VALID=true
fi

if [ "$AUTH_KEY_VALID" = "true" ]; then
    echo "🔗 Tailscale設定検出 - リモートアクセス有効モードで起動"
    
    # Tailscale 認証・起動
    echo "   Tailscaled サービス開始..."
    sudo tailscaled --state-dir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &
    sleep 3
    
    echo "   Tailscale認証中..."
    if sudo tailscale up --auth-key="$TAILSCALE_AUTH_KEY" --hostname="${TAILSCALE_HOSTNAME:-opencode-dev}" --accept-routes; then
        TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "IP取得中...")
        echo "   ✅ Tailscale接続完了"
        echo "   📱 Tailscale IP: $TAILSCALE_IP"
        REMOTE_ACCESS_MODE=true
    else
        echo "   ❌ Tailscale接続失敗 - ローカルモードに切り替え"
        REMOTE_ACCESS_MODE=false
    fi
else
    echo "🏠 ローカル開発モードで起動（Tailscale無し）"
    echo "   💡 後でTailscaleを有効にする場合："
    echo "     1. .env ファイルを編集してTAILSCALE_AUTH_KEYを設定"
    echo "     2. ./scripts/setup-tailscale.sh を実行"
    REMOTE_ACCESS_MODE=false
fi

echo ""
echo "🚀 サービス起動中..."

# OpenCode CLI サーバー起動
echo "📍 OpenCode CLI サーバー起動..."
cd /workspace
opencode serve --port $OPENCODE_PORT --host ${OPENCODE_HOST:-0.0.0.0} &
OPENCODE_PID=$!

# 起動待機
sleep 3

# OpenChamber 起動
echo "📍 OpenChamber Web UI 起動..."
OPENCODE_HOST=http://localhost:$OPENCODE_PORT \
OPENCODE_SKIP_START=true \
openchamber \
    --port $OPENCHAMBER_PORT \
    --host ${OPENCHAMBER_HOST:-0.0.0.0} &
OPENCHAMBER_PID=$!

# プロジェクトアプリ起動（package.jsonがある場合）
if [ -f "/workspace/package.json" ]; then
    echo "📍 プロジェクトアプリ起動..."
    cd /workspace
    # 依存関係が未インストールの場合はインストール
    if [ ! -d "node_modules" ]; then
        echo "   依存関係インストール中..."
        npm install --silent
    fi
    npm start &
    PROJECT_PID=$!
elif [ -f "/workspace/sample-project/package.json" ]; then
    echo "📍 サンプルアプリ起動..."
    cd /workspace/sample-project
    if [ ! -d "node_modules" ]; then
        echo "   依存関係インストール中..."
        npm install --silent
    fi
    npm start &
    PROJECT_PID=$!
fi

# 起動完了の確認
echo "⏳ サービス起動確認中..."
sleep 5

# 起動確認
check_service() {
    local port=$1
    local name=$2
    if curl -s "http://localhost:$port" > /dev/null 2>&1 || netstat -tuln | grep ":$port " > /dev/null 2>&1; then
        echo "✅ $name: 起動完了"
        return 0
    else
        echo "⚠️  $name: 起動中 (ポート $port)"
        return 1
    fi
}

check_service $OPENCODE_PORT "OpenCode CLI"
check_service $OPENCHAMBER_PORT "OpenChamber"
if [ -n "$PROJECT_PID" ]; then
    check_service $SAMPLE_PORT "プロジェクトアプリ"
fi

echo ""
echo "🎉 DevContainer 起動完了！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# アクセス方法の表示
echo "📱 アクセス方法:"
echo ""
echo "🏠 ローカル環境から:"
echo "   🎨 OpenChamber:     http://localhost:$OPENCHAMBER_PORT"
echo "   🤖 OpenCode CLI:    http://localhost:$OPENCODE_PORT"
echo "   🚀 プロジェクト:     http://localhost:$SAMPLE_PORT"
echo ""

if [ "$HOST_LAN_IP" != "未検出" ]; then
    echo "🌐 LAN内の他デバイスから:"
    echo "   🎨 OpenChamber:     http://$HOST_LAN_IP:$OPENCHAMBER_PORT"
    echo "   🤖 OpenCode CLI:    http://$HOST_LAN_IP:$OPENCODE_PORT"  
    echo "   🚀 プロジェクト:     http://$HOST_LAN_IP:$SAMPLE_PORT"
    echo ""
fi

if [ "$REMOTE_ACCESS_MODE" = "true" ] && [ -n "$TAILSCALE_IP" ]; then
    echo "📱 スマートフォン（Tailscale）から:"
    echo "   🎨 OpenChamber:     http://$TAILSCALE_IP:$OPENCHAMBER_PORT"
    echo "   🤖 OpenCode CLI:    http://$TAILSCALE_IP:$OPENCODE_PORT"
    echo "   🚀 プロジェクト:     http://$TAILSCALE_IP:$SAMPLE_PORT"
    echo ""
fi

if [ "$AUTH_KEY_VALID" = "false" ]; then
    echo "💡 スマートフォンアクセスを有効にするには:"
    echo "   1. https://login.tailscale.com/admin/settings/keys"
    echo "   2. Auth Key 生成（Reusable + Ephemeral）"
    echo "   3. .env ファイルに TAILSCALE_AUTH_KEY を設定"
    echo "   4. ./scripts/setup-tailscale.sh を実行"
    echo ""
fi

echo "🎯 次のステップ:"
echo "   1. ブラウザで OpenChamber にアクセス"
echo "   2. プロンプトで 'AI開発をサポートして' と入力"
echo "   3. ECC エージェントが自動で開発支援開始！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# プロセス監視とクリーンアップ
cleanup() {
    echo ""
    echo "🛑 サービス停止中..."
    kill $OPENCODE_PID $OPENCHAMBER_PID $PROJECT_PID 2>/dev/null || true
    if [ "$REMOTE_ACCESS_MODE" = "true" ]; then
        sudo tailscale down 2>/dev/null || true
    fi
    echo "✅ クリーンアップ完了"
    exit 0
}

trap cleanup SIGTERM SIGINT

# フォアグラウンドで実行継続
echo "🔄 サービス監視中... (Ctrl+C で停止)"
wait
