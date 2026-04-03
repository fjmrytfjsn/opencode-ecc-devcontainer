#!/bin/bash
# Shared helpers for DevContainer scripts.

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}$*${NC}"
}

log_success() {
    echo -e "${GREEN}$*${NC}"
}

log_warn() {
    echo -e "${YELLOW}$*${NC}"
}

log_error() {
    echo -e "${RED}$*${NC}"
}

strip_quotes_spaces() {
    echo "$1" | tr -d '"' | tr -d '[:space:]'
}

resolve_env_file() {
    if [[ -f "/workspace/.env" ]]; then
        echo "/workspace/.env"
    elif [[ -f "$(pwd)/.env" ]]; then
        echo "$(pwd)/.env"
    else
        echo ".env"
    fi
}

resolve_env_template_file() {
    if [[ -f "/workspace/.env.template" ]]; then
        echo "/workspace/.env.template"
    elif [[ -f "$(pwd)/.env.template" ]]; then
        echo "$(pwd)/.env.template"
    else
        echo ".env.template"
    fi
}

load_env_file() {
    local env_file="$1"
    [[ -f "$env_file" ]] || return 1
    # shellcheck disable=SC1090
    set -a
    source "$env_file" 2>/dev/null || true
    set +a
    return 0
}

is_placeholder_tailscale_key() {
    local key
    key=$(strip_quotes_spaces "$1")
    [[ -z "$key" ]] && return 0
    [[ "$key" == "your-tailscale-auth-key-here" ]] && return 0
    [[ "$key" == "tskey-auth-xxxxxxxxxxxxxxxxx" ]] && return 0
    [[ "$key" =~ ^tskey-auth-[xX]+$ ]] && return 0
    return 1
}

is_valid_tailscale_key() {
    local key
    key=$(strip_quotes_spaces "$1")
    [[ "$key" =~ ^tskey-auth- ]] || return 1
    is_placeholder_tailscale_key "$key" && return 1
    return 0
}

upsert_env_value() {
    local env_file="$1"
    local key="$2"
    local value="$3"

    [[ -f "$env_file" ]] || touch "$env_file"
    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$env_file"
    else
        echo "${key}=\"${value}\"" >> "$env_file"
    fi
}

ensure_env_permissions() {
    local env_file="$1"
    [[ -f "$env_file" ]] || return 0
    chmod 600 "$env_file" 2>/dev/null || true
}

ensure_hosts_entry() {
    local host_name="$1"
    [[ -z "$host_name" ]] && return 0
    if ! grep -q "127.0.0.1.*$host_name" /etc/hosts 2>/dev/null; then
        sudo sh -c "echo '127.0.0.1 $host_name' >> /etc/hosts" 2>/dev/null || true
    fi
}

is_ci_mode() {
    [[ "${CI_MODE:-0}" == "1" ]] && return 0
    [[ "${CI:-false}" == "true" ]] && return 0
    [[ "${GITHUB_ACTIONS:-false}" == "true" ]] && return 0
    [[ ! -t 0 ]] && return 0
    return 1
}
