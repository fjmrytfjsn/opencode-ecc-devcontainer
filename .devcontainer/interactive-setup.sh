#!/bin/bash
# DevContainer infrastructure setup (Tailscale-focused)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
set -e

SETUP_COMPLETE_FILE="/workspace/.devcontainer/.setup-complete"
ENV_FILE=$(resolve_env_file)

log_success "🚀 基盤セットアップへようこそ"
log_info "このセットアップは Tailscale 関連設定のみを扱います。"
echo ""

if [[ -f "$SETUP_COMPLETE_FILE" ]]; then
    log_warn "ℹ️  既にセットアップ済みです。再設定しますか？ (y/N): "
    read -r RERUN_SETUP
    if [[ ! "$RERUN_SETUP" =~ ^[Yy]$ ]]; then
        log_success "✅ セットアップをスキップしました"
        exit 0
    fi
    echo ""
fi

TAILSCALE_AUTH_KEY=""
TAILSCALE_HOSTNAME="opencode-dev"

if [[ -f "$ENV_FILE" ]]; then
    load_env_file "$ENV_FILE"
    existing_key="$TAILSCALE_AUTH_KEY"
    existing_host="$TAILSCALE_HOSTNAME"

    if is_valid_tailscale_key "$existing_key"; then
        log_success "✅ 既存の Tailscale Auth Key を検出しました"
        TAILSCALE_AUTH_KEY="$existing_key"
        if [[ "${SKIP_EXISTING_KEY_UPDATE_PROMPT:-0}" == "1" ]]; then
            log_info "既存の Auth Key をそのまま使用します"
        else
            log_info "Auth Key を更新する場合のみ入力してください（Enterで既存キーを維持）:"
            read -s -p "🔑 新しい Auth Key: " NEW_AUTH_KEY
            echo ""

            if [[ -n "$NEW_AUTH_KEY" ]]; then
                if is_valid_tailscale_key "$NEW_AUTH_KEY"; then
                    TAILSCALE_AUTH_KEY="$NEW_AUTH_KEY"
                else
                    log_warn "⚠️  入力されたキー形式が不正なため既存キーを維持します"
                fi
            fi
        fi
    fi

    if [[ -n "$existing_host" ]]; then
        TAILSCALE_HOSTNAME="$existing_host"
    fi
fi

if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
    log_info "Tailscale Auth Key を入力してください（未入力可）:"
    log_warn "  形式: tskey-auth-xxxxxxxxxxxxxxxxx"
    read -s -p "🔑 Auth Key: " TAILSCALE_AUTH_KEY
    echo ""

    if [[ -n "$TAILSCALE_AUTH_KEY" ]] && ! is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
        log_warn "⚠️  形式が不正のためプレースホルダーに戻します"
        TAILSCALE_AUTH_KEY="your-tailscale-auth-key-here"
    fi
fi

if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
    TAILSCALE_AUTH_KEY="your-tailscale-auth-key-here"
fi

echo ""
log_info "Tailscale ホスト名（オプション）:"
log_warn "  デフォルト: ${TAILSCALE_HOSTNAME}"
read -r -p "🏷️  ホスト名: " INPUT_HOSTNAME
if [[ -n "$INPUT_HOSTNAME" ]]; then
    TAILSCALE_HOSTNAME="$INPUT_HOSTNAME"
fi

echo ""
log_info "📋 設定確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if is_valid_tailscale_key "$TAILSCALE_AUTH_KEY"; then
    echo "Tailscale Auth Key: 設定済み"
else
    echo "Tailscale Auth Key: 未設定（プレースホルダー）"
fi
echo "Tailscale ホスト名: $TAILSCALE_HOSTNAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "この設定を保存しますか？ (Y/n): "
read -r CONFIRM_SETUP
if [[ "$CONFIRM_SETUP" =~ ^[Nn]$ ]]; then
    log_warn "⚠️  セットアップをキャンセルしました"
    exit 1
fi

cat > "$ENV_FILE" << EOF
# OpenCode ECC DevContainer 基盤設定
# 生成日時: $(date)

# Tailscale
TAILSCALE_AUTH_KEY="$TAILSCALE_AUTH_KEY"
TAILSCALE_HOSTNAME="$TAILSCALE_HOSTNAME"

# ECC
ECC_PROFILE="${ECC_PROFILE:-developer}"

# Service ports
OPENCODE_HOST=0.0.0.0
OPENCODE_PORT=4095
OPENCHAMBER_HOST=0.0.0.0
OPENCHAMBER_PORT=3000

# Runtime
NODE_ENV=development
DEBUG=false
LOG_LEVEL=info
EOF

chmod 600 "$ENV_FILE"
touch "$SETUP_COMPLETE_FILE"
echo "$(date): Infrastructure setup completed" > "$SETUP_COMPLETE_FILE"

echo ""
log_success "✅ 基盤セットアップが完了しました"
log_info "次のステップ:"
echo "  1) .devcontainer/startup.sh の起動ログを確認"
echo "  2) OpenChamber: http://localhost:3000"
echo "  3) OpenCode: http://localhost:4095"
