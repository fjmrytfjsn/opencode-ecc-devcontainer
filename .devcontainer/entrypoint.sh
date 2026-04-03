#!/bin/bash

echo "🔧 OpenCode ECC DevContainer エントリーポイント"

# Tailscale daemon 起動
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🌐 Tailscale daemon 起動中..."
    sudo tailscaled --statedir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &
fi

# メインプロセス実行
exec "$@"
