#!/bin/bash

echo "🔧 OpenCode ECC DevContainer エントリーポイント"

# tailscaled startup is centrally handled by .devcontainer/startup.sh
# to keep daemon flags and lifecycle behavior consistent.

# メインプロセス実行
exec "$@"
