#!/bin/bash

# OpenCode ECC サービス起動スクリプト  
# DevContainer 接続時に毎回実行される（ai-harness-template ベース）

set -e

LOCK_FILE="/tmp/opencode-ecc-start-services.lock"
exec 9>"$LOCK_FILE"
if ! flock -w 120 9; then
    echo "❌ start-services.sh の排他ロック取得に失敗しました"
    echo "   既存の起動処理が長時間実行中の可能性があります"
    exit 1
fi

# ワークスペースディレクトリの確認
WORKSPACE_DIR="${containerWorkspaceFolder:-$(pwd)}"
cd "$WORKSPACE_DIR"

# .env がなければテンプレートから作成
if [ ! -f ".env" ] && [ -f ".env.template" ]; then
    cp .env.template .env
fi

# .env があれば読み込んで環境変数として展開
if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

# 実行時に必要なディレクトリを保証
mkdir -p .opencode-logs
mkdir -p .temp

# デフォルトURL
OPENCODE_CLI_URL="http://localhost:4095"
OPENCHAMBER_URL="http://localhost:3000"
DASHBOARD_URL="http://localhost:8080"

# 環境変数設定
OPENCODE_VERSION="${OPENCODE_VERSION:-1.3.9}"
OPENCODE_STARTUP_TIMEOUT_SECONDS="${OPENCODE_STARTUP_TIMEOUT_SECONDS:-60}"
OPENCODE_START_RETRIES="${OPENCODE_START_RETRIES:-3}"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-opencode-dev}"

get_pid_by_port() {
    local port="$1"
    ss -ltnp 2>/dev/null | grep -E ":${port}[[:space:]]" | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n 1
}

wait_for_port() {
    local port="$1"
    local retries="${2:-10}"
    local delay="${3:-1}"
    local i
    for i in $(seq 1 "$retries"); do
        if ss -ltn 2>/dev/null | grep -qE ":${port}[[:space:]]"; then
            return 0
        fi
        sleep "$delay"
    done
    return 1
}

is_pid_alive() {
    local pid="$1"
    [ -n "$pid" ] && ps -p "$pid" >/dev/null 2>&1
}

start_opencode_cli() {
    local host_arg="--host 0.0.0.0"
    if command -v opencode >/dev/null 2>&1; then
        nohup setsid opencode start --port 4095 $host_arg > .opencode-logs/opencode-cli.log 2>&1 &
    else
        nohup setsid npx --yes "opencode-ai@${OPENCODE_VERSION}" start --port 4095 $host_arg > .opencode-logs/opencode-cli.log 2>&1 &
    fi
}

start_openchamber() {
    if command -v openchamber >/dev/null 2>&1; then
        nohup setsid openchamber --port 3000 --host 0.0.0.0 > .opencode-logs/openchamber.log 2>&1 &
    else
        nohup setsid npx --yes @openchamber/web --port 3000 --host 0.0.0.0 > .opencode-logs/openchamber.log 2>&1 &
    fi
}

echo "🚀 OpenCode ECC サービスを起動中..."

# Tailscale の起動（AuthKey があれば自動で参加）
if command -v tailscaled >/dev/null 2>&1; then
    mkdir -p /var/lib/tailscale

    if ! pgrep -x tailscaled >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            nohup setsid sudo -n tailscaled --state=/var/lib/tailscale/tailscaled.state --tun=userspace-networking > .opencode-logs/tailscaled.log 2>&1 &
            sleep 2
        else
            echo "⚠️  sudo が使えないため tailscaled の起動をスキップします"
        fi
    fi

    if [ -n "${TAILSCALE_AUTH_KEY:-}" ] && [ "${TAILSCALE_AUTH_KEY}" != "your-auth-key-here" ]; then
        if ! sudo -n tailscale up --authkey "$TAILSCALE_AUTH_KEY" --hostname "$TAILSCALE_HOSTNAME" --accept-dns=false 2>/dev/null; then
            echo "⚠️  Tailscale のセットアップに失敗しました"
        else
            echo "✅ Tailscale 接続完了"
        fi
    else
        echo "⚠️  TAILSCALE_AUTH_KEY が未設定のため Tailscale 参加をスキップします"
    fi
fi

# OpenCode CLI の起動
echo "⬇️  OpenCode CLI を起動中..."
EXISTING_CLI_PID="$(get_pid_by_port 4095)"
if [ -n "$EXISTING_CLI_PID" ] && is_pid_alive "$EXISTING_CLI_PID"; then
    echo "✅ OpenCode CLI は既に起動済みです (PID: $EXISTING_CLI_PID)"
else
    start_opencode_cli
    if wait_for_port 4095 "$OPENCODE_STARTUP_TIMEOUT_SECONDS" 1; then
        ACTIVE_CLI_PID="$(get_pid_by_port 4095)"
        echo "✅ OpenCode CLI 起動完了 (PID: $ACTIVE_CLI_PID)"
    else
        echo "❌ OpenCode CLI の起動に失敗しました"
        echo "   ログ: .opencode-logs/opencode-cli.log"
    fi
fi

# OpenChamber の起動
echo "⬇️  OpenChamber を起動中..."
EXISTING_CHAMBER_PID="$(get_pid_by_port 3000)"
if [ -n "$EXISTING_CHAMBER_PID" ] && is_pid_alive "$EXISTING_CHAMBER_PID"; then
    echo "✅ OpenChamber は既に起動済みです (PID: $EXISTING_CHAMBER_PID)"
else
    start_openchamber
    if wait_for_port 3000 15 1; then
        ACTIVE_CHAMBER_PID="$(get_pid_by_port 3000)"
        echo "✅ OpenChamber 起動完了 (PID: $ACTIVE_CHAMBER_PID)"
    else
        echo "❌ OpenChamber の起動に失敗しました"
        echo "   ログ: .opencode-logs/openchamber.log"
    fi
fi

# バックグラウンドプロセスがロックを継承しないようにする
exec 9>&-

# 起動完了メッセージ
echo ""
echo "=============================================="
echo "🤖 OpenCode ECC 環境 起動完了!"
echo ""
echo "📱 利用可能なサービス:"
echo "   🎨 OpenChamber Web UI: $OPENCHAMBER_URL"
echo "   🤖 OpenCode CLI Server: $OPENCODE_CLI_URL"
echo "   📊 Development Server: $DASHBOARD_URL"
echo ""
echo "🎯 クイックスタート:"
echo "   1. VS Code 'PORTS' タブから各サービスにアクセス"
echo "   2. OpenChamber: AIプロバイダー設定後、コーディング開始"
echo "   3. OpenCode CLI: APIサーバーとして利用可能"
echo ""
echo "📚 ドキュメント: README.md | QUICK_START.md"
echo "=============================================="
echo ""