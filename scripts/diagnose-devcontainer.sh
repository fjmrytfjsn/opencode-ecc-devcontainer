#!/bin/bash

# DevContainer diagnostic tool
# DevContainer診断ツール

echo "🔍 DevContainer 環境診断開始..."
echo ""

# System info
echo "📊 システム情報:"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
echo "  Hostname: $(hostname)"
echo "  User: $(whoami)"
echo "  PWD: $(pwd)"
echo ""

# Check hostname resolution
echo "🔧 ホスト名解決チェック:"
HOSTNAME=$(hostname)
if grep -q "127.0.0.1.*$HOSTNAME" /etc/hosts 2>/dev/null; then
    echo "  ✅ /etc/hosts に $HOSTNAME が登録済み"
else
    echo "  ❌ /etc/hosts に $HOSTNAME が未登録"
    echo "     修正コマンド: echo '127.0.0.1 $HOSTNAME' | sudo tee -a /etc/hosts"
fi
echo ""

# Check Tailscale installation
echo "🦎 Tailscale インストールチェック:"
if command -v tailscale >/dev/null 2>&1; then
    echo "  ✅ Tailscale インストール済み"
    echo "     バージョン: $(tailscale version --short 2>/dev/null || echo 'バージョン取得失敗')"
    
    # Check tailscaled daemon
    if pgrep -x tailscaled >/dev/null; then
        echo "  ✅ tailscaled デーモン動作中"
        echo "     PID: $(pgrep -x tailscaled)"
    else
        echo "  ❌ tailscaled デーモン停止中"
        echo "     起動コマンド: sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &"
    fi
    
    # Check Tailscale status
    if sudo tailscale --socket=/run/tailscale/tailscaled.sock status >/dev/null 2>&1; then
        echo "  ✅ Tailscale 接続確認済み"
        sudo tailscale --socket=/run/tailscale/tailscaled.sock status | head -3 | sed 's/^/     /'
    else
        echo "  ⚠️  Tailscale 未接続または未認証"
        echo "     認証コマンド: sudo tailscale --socket=/run/tailscale/tailscaled.sock up --auth-key=YOUR_KEY"
    fi
else
    echo "  ❌ Tailscale 未インストール"
    echo "     インストールコマンド: curl -fsSL https://tailscale.com/install.sh | sh"
fi
echo ""

# Check environment file
echo "🔧 環境設定チェック:"
if [ -f ".env" ]; then
    echo "  ✅ .env ファイル存在"
    source .env 2>/dev/null || true
    
    if [ -n "$TAILSCALE_AUTH_KEY" ] && [ "$TAILSCALE_AUTH_KEY" != "your-auth-key-here" ] && [ "$TAILSCALE_AUTH_KEY" != "tskey-auth-xxxxxxxxxxxxxxxxx" ]; then
        echo "  ✅ TAILSCALE_AUTH_KEY 設定済み"
        echo "     キー: ${TAILSCALE_AUTH_KEY:0:15}..."
    else
        echo "  ⚠️  TAILSCALE_AUTH_KEY 未設定またはテンプレート値"
        echo "     設定コマンド: ./scripts/setup-tailscale.sh"
    fi
else
    echo "  ❌ .env ファイル不在"
    if [ -f ".env.template" ]; then
        echo "     作成コマンド: cp .env.template .env"
    fi
fi
echo ""

# Check services
echo "🚀 サービス状態チェック:"

# OpenCode CLI
if pgrep -f "opencode start" >/dev/null; then
    echo "  ✅ OpenCode CLI 動作中"
    echo "     PID: $(pgrep -f 'opencode start')"
else
    echo "  ❌ OpenCode CLI 停止中"
    echo "     起動コマンド: opencode start"
fi

# OpenChamber
if pgrep -f "openchamber" >/dev/null; then
    echo "  ✅ OpenChamber 動作中"
    echo "     PID: $(pgrep -f 'openchamber')"
else
    echo "  ❌ OpenChamber 停止中"
    echo "     起動コマンド: npm run openchamber"
fi
echo ""

# Network connectivity test
echo "🌐 ネットワーク接続テスト:"
if curl -s --max-time 3 http://localhost:4095/health >/dev/null 2>&1; then
    echo "  ✅ OpenCode CLI (localhost:4095) 応答あり"
else
    echo "  ❌ OpenCode CLI (localhost:4095) 応答なし"
fi

if curl -s --max-time 3 http://localhost:3000 >/dev/null 2>&1; then
    echo "  ✅ OpenChamber (localhost:3000) 応答あり"
else
    echo "  ❌ OpenChamber (localhost:3000) 応答なし"
fi
echo ""

# Recommendations
echo "💡 推奨アクション:"
if ! grep -q "127.0.0.1.*$(hostname)" /etc/hosts 2>/dev/null; then
    echo "  1. ホスト名解決修正: echo '127.0.0.1 $(hostname)' | sudo tee -a /etc/hosts"
fi

if ! pgrep -x tailscaled >/dev/null && command -v tailscale >/dev/null 2>&1; then
    echo "  2. Tailscaled 起動: sudo tailscaled --statedir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock --tun=userspace-networking --socks5-server=localhost:1055 &"
fi

if [ ! -f ".env" ]; then
    echo "  3. 環境ファイル作成: cp .env.template .env"
fi

if [ -f ".env" ] && source .env 2>/dev/null && ([ -z "$TAILSCALE_AUTH_KEY" ] || [ "$TAILSCALE_AUTH_KEY" = "your-auth-key-here" ]); then
    echo "  4. Tailscale設定: ./scripts/setup-tailscale.sh"
fi

echo ""
echo "🔍 診断完了 - 上記の推奨アクションを実行してください"
