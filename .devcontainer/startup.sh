#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
set -e

echo "🌟 OpenCode ECC DevContainer 起動中..."

fix_hostname() {
    local current_host
    current_host=$(hostname)
    echo "🔧 ホスト名解決問題を修正中..."
    ensure_hosts_entry "$current_host"
    echo "✅ ホスト名解決修正完了: $current_host"
}

fix_hostname

if [ -f "/workspace/.env" ]; then
    echo "📂 .env ファイルから環境変数読み込み..."
    load_env_file "/workspace/.env"
fi

sanitize_opencode_agents() {
    local agents_dir="/home/vscode/.opencode/.agents"
    if [ ! -d "$agents_dir" ] && [ -d "/home/vscode/.opencode/agents" ]; then
        agents_dir="/home/vscode/.opencode/agents"
    fi
    [ -d "$agents_dir" ] || return 0

    local changed=0
    for f in "$agents_dir"/*.md; do
        [ -f "$f" ] || continue

        local line tools_raw tools_obj
        line=$(grep -m1 '^tools:\s*\[' "$f" || true)
        if [ -n "$line" ]; then
            tools_raw=$(echo "$line" | sed -E 's/^tools:\s*\[(.*)\]\s*$/\1/')
            tools_obj=""

            IFS=',' read -r -a arr <<< "$tools_raw"
            for t in "${arr[@]}"; do
                t=$(echo "$t" | sed -E 's/^\s*"(.*)"\s*$/\1/' | sed -E 's/^\s+|\s+$//g')
                [ -n "$t" ] || continue
                if [ -n "$tools_obj" ]; then
                    tools_obj="$tools_obj, "
                fi
                tools_obj="$tools_obj\"$t\": true"
            done

            if [ -n "$tools_obj" ]; then
                sed -i -E "s|^tools:\s*\[.*\]\s*$|tools: {$tools_obj}|" "$f"
                changed=$((changed + 1))
            fi
        fi

        local color_line color_value color_norm color_enum
        color_line=$(grep -m1 '^color:\s*' "$f" || true)
        if [ -n "$color_line" ]; then
            color_value=$(echo "$color_line" | sed -E 's/^color:\s*//')
            color_norm=$(echo "$color_value" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

            if ! echo "$color_norm" | grep -Eq '^(primary|secondary|accent|success|warning|error|info)$'; then
                case "$color_norm" in
                    teal) color_enum="info" ;;
                    orange) color_enum="warning" ;;
                    red) color_enum="error" ;;
                    green) color_enum="success" ;;
                    blue|primary) color_enum="primary" ;;
                    purple|accent) color_enum="accent" ;;
                    secondary) color_enum="secondary" ;;
                    success) color_enum="success" ;;
                    warning) color_enum="warning" ;;
                    error) color_enum="error" ;;
                    info) color_enum="info" ;;
                    *) color_enum="info" ;;
                esac

                sed -i -E "s|^color:\s*.*$|color: $color_enum|" "$f"
                changed=$((changed + 1))
            fi
        fi
    done

    if [ "$changed" -gt 0 ]; then
        echo "🛠️ opencode エージェント設定を自動修正しました: ${changed}件"
    fi
}

sanitize_opencode_agents

OPENCODE_PORT=${OPENCODE_PORT:-4095}
OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-3000}
OPENCODE_HOST=${OPENCODE_HOST:-0.0.0.0}
OPENCHAMBER_HOST=${OPENCHAMBER_HOST:-0.0.0.0}
OPENCHAMBER_DEFAULT_PROJECT_DIR=${OPENCHAMBER_DEFAULT_PROJECT_DIR:-/workspace/projects}

if [ ! -d "$OPENCHAMBER_DEFAULT_PROJECT_DIR" ]; then
    OPENCHAMBER_DEFAULT_PROJECT_DIR="/workspace"
fi

REMOTE_ACCESS_MODE=false
TAILSCALE_IP=""

start_tailscaled_daemon() {
    local tailscaled_bin
    tailscaled_bin=$(command -v tailscaled 2>/dev/null || true)
    if [ -z "$tailscaled_bin" ]; then
        echo "⚠️  tailscaled バイナリが見つかりません。Tailscaleはスキップします。"
        return 1
    fi

    sudo mkdir -p /var/lib/tailscale /run/tailscale
    sudo pkill -f tailscaled || true
    sleep 1

    # Start daemon in background and capture logs for troubleshooting.
    sudo nohup "$tailscaled_bin" \
        --statedir=/var/lib/tailscale \
        --socket=/run/tailscale/tailscaled.sock \
        --tun=userspace-networking \
        --socks5-server=localhost:1055 >/tmp/tailscaled.log 2>&1 < /dev/null &

    for i in {1..15}; do
        if sudo tailscale --socket=/run/tailscale/tailscaled.sock status >/dev/null 2>&1; then
            return 0
        fi
        echo "   ⏳ tailscaled 起動待機中... ($i/15)"
        sleep 1
    done

    echo "⚠️  tailscaled の起動確認に失敗しました。"
    [ -f /tmp/tailscaled.log ] && tail -n 30 /tmp/tailscaled.log || true
    return 1
}

if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo "🔗 Tailscale 設定を検出。接続を試行します..."
    if start_tailscaled_daemon; then
        if sudo tailscale --socket=/run/tailscale/tailscaled.sock up --auth-key="$TAILSCALE_AUTH_KEY" --hostname="${TAILSCALE_HOSTNAME:-opencode-dev}" --accept-routes; then
            TAILSCALE_IP=$(sudo tailscale --socket=/run/tailscale/tailscaled.sock ip -4 2>/dev/null || true)
            REMOTE_ACCESS_MODE=true
            echo "✅ Tailscale 接続完了: ${TAILSCALE_IP:-IP未取得}"
        else
            echo "⚠️  tailscale up が失敗しました。ローカルモードで継続します。"
            sudo tailscale --socket=/run/tailscale/tailscaled.sock status 2>/dev/null || true
        fi
    else
        echo "⚠️  tailscaled の起動に失敗しました。ローカルモードで継続します。"
    fi
else
    echo "ℹ️  有効な TAILSCALE_AUTH_KEY が未設定です。ローカルモードで起動します。"
    echo "   後で設定する場合は .devcontainer/interactive-setup.sh を実行してください。"
fi

echo ""
echo "🚀 基盤サービス起動中..."

OPENCODE_LOG=/tmp/opencode-serve.log
OPENCHAMBER_LOG=/tmp/openchamber.log

nohup opencode serve --port "$OPENCODE_PORT" --hostname "$OPENCODE_HOST" > "$OPENCODE_LOG" 2>&1 < /dev/null &
OPENCODE_PID=$!

sleep 2

OPENCODE_HOST=http://localhost:$OPENCODE_PORT \
OPENCODE_SKIP_START=true \
nohup openchamber --port "$OPENCHAMBER_PORT" --host "$OPENCHAMBER_HOST" > "$OPENCHAMBER_LOG" 2>&1 < /dev/null &
OPENCHAMBER_PID=$!

sleep 2

set_default_project_directory() {
    local target_dir="$1"
    [ -d "$target_dir" ] || return 0

    local payload
    payload=$(printf '{"path":"%s"}' "$target_dir")

    for i in {1..10}; do
        if curl -fsS -X POST "http://localhost:$OPENCHAMBER_PORT/api/opencode/directory" \
            -H "Content-Type: application/json" \
            -d "$payload" >/tmp/openchamber-default-dir.json 2>/tmp/openchamber-default-dir.err; then
            echo "✅ OpenChamber の初期プロジェクトパスを設定: $target_dir"
            return 0
        fi
        sleep 1
    done

    echo "⚠️  OpenChamber の初期プロジェクトパス設定に失敗しました（起動継続）"
}

set_default_project_directory "$OPENCHAMBER_DEFAULT_PROJECT_DIR"

check_service() {
    local port=$1
    local name=$2
    if curl -s "http://localhost:$port" >/dev/null 2>&1 || netstat -tuln | grep ":$port " >/dev/null 2>&1; then
        echo "✅ $name: 起動完了"
    else
        echo "⚠️  $name: 起動確認できません（ログ確認: /tmp）"
    fi
}

check_service "$OPENCODE_PORT" "OpenCode CLI"
check_service "$OPENCHAMBER_PORT" "OpenChamber"

WATCHDOG_SCRIPT=/tmp/opencode-ecc-watchdog.sh
WATCHDOG_PIDFILE=/tmp/opencode-ecc-watchdog.pid
cat > "$WATCHDOG_SCRIPT" <<'EOF'
#!/bin/bash
set +e

OPENCODE_PORT=${OPENCODE_PORT:-4095}
OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-3000}
OPENCODE_HOST=${OPENCODE_HOST:-0.0.0.0}
OPENCHAMBER_HOST=${OPENCHAMBER_HOST:-0.0.0.0}

is_port_open() {
    ss -ltn 2>/dev/null | grep -q ":$1\\b"
}

while true; do
    if ! is_port_open "$OPENCODE_PORT"; then
        cd /workspace || true
        nohup opencode serve --port "$OPENCODE_PORT" --hostname "$OPENCODE_HOST" >> /tmp/opencode-serve.log 2>&1 < /dev/null &
    fi

    if ! is_port_open "$OPENCHAMBER_PORT"; then
        cd /workspace || true
        OPENCODE_HOST=http://localhost:$OPENCODE_PORT OPENCODE_SKIP_START=true nohup openchamber --port "$OPENCHAMBER_PORT" --host "$OPENCHAMBER_HOST" >> /tmp/openchamber.log 2>&1 < /dev/null &
    fi

    sleep 10
done
EOF
chmod +x "$WATCHDOG_SCRIPT"

if [ -f "$WATCHDOG_PIDFILE" ] && ps -p "$(cat "$WATCHDOG_PIDFILE" 2>/dev/null)" >/dev/null 2>&1; then
    echo "🔄 監視プロセスは既に稼働中です (PID: $(cat "$WATCHDOG_PIDFILE"))"
else
    rm -f "$WATCHDOG_PIDFILE"
    nohup "$WATCHDOG_SCRIPT" > /tmp/opencode-ecc-watchdog.log 2>&1 < /dev/null &
    echo $! > "$WATCHDOG_PIDFILE"
    echo "🛡️ 監視プロセスを開始しました (PID: $(cat "$WATCHDOG_PIDFILE"))"
fi

echo ""
echo "🎉 DevContainer 起動完了！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 アクセス方法:"
echo "   🎨 OpenChamber:     http://localhost:$OPENCHAMBER_PORT"
echo "   🤖 OpenCode CLI:    http://localhost:$OPENCODE_PORT"
if [ "$REMOTE_ACCESS_MODE" = "true" ] && [ -n "$TAILSCALE_IP" ]; then
    echo "   📱 Tailscale OpenChamber: http://$TAILSCALE_IP:$OPENCHAMBER_PORT"
    echo "   📱 Tailscale OpenCode:    http://$TAILSCALE_IP:$OPENCODE_PORT"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🔄 サービス監視中... (Ctrl+C で停止)"

cleanup() {
    echo ""
    echo "🛑 サービス停止中..."
    kill "$OPENCODE_PID" "$OPENCHAMBER_PID" 2>/dev/null || true
    echo "✅ クリーンアップ完了"
    exit 0
}

if [ "${STARTUP_MONITOR:-0}" = "1" ]; then
    trap cleanup SIGTERM SIGINT
    wait
fi
