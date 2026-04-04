#!/bin/bash

echo "🔧 OpenCode ECC DevContainer エントリーポイント"

is_valid_tailscale_key() {
    local key
    key=$(echo "$1" | tr -d '"' | tr -d '[:space:]')
    [[ "$key" =~ ^tskey-auth- ]] || return 1
    [[ "$key" == "your-tailscale-auth-key-here" ]] && return 1
    [[ "$key" == "tskey-auth-xxxxxxxxxxxxxxxxx" ]] && return 1
    [[ "$key" =~ ^tskey-auth-[xX]+$ ]] && return 1
    return 0
}

# Tailscale daemon 起動
if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo "🌐 Tailscale daemon 起動中..."
    sudo tailscaled --statedir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &
fi

# メインプロセス実行
exec "$@"
