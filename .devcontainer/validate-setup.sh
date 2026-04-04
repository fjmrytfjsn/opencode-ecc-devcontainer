#!/bin/bash
# 🧪 DevContainer セットアップ検証・テストスクリプト
# 全機能の動作確認とトラブルシューティング

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 DevContainer 統合テスト開始${NC}"
echo ""

# テスト結果カウンター
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# テストヘルパー関数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${CYAN}🔍 [$TESTS_TOTAL] $test_name${NC}"
    
    if eval "$test_command" &>/dev/null; then
        local result=0
    else
        local result=1
    fi
    
    if [[ $result -eq $expected_result ]]; then
        echo -e "${GREEN}   ✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}   ❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 環境変数テスト
echo -e "${BLUE}📋 環境変数テスト${NC}"
run_test ".env ファイル存在確認" "test -f /workspace/.env"
run_test ".env.template ファイル存在確認" "test -f /workspace/.env.template"

if [[ -f "/workspace/.env" ]]; then
    source /workspace/.env 2>/dev/null || true
    if [[ -n "$TAILSCALE_AUTH_KEY" && "$TAILSCALE_AUTH_KEY" != "your-tailscale-auth-key-here" && "$TAILSCALE_AUTH_KEY" != "tskey-auth-xxxxxxxxxxxxxxxxx" ]]; then
        run_test "TAILSCALE_AUTH_KEY 設定確認" "test -n '$TAILSCALE_AUTH_KEY'"
    else
        echo -e "${YELLOW}🔍 [${TESTS_TOTAL}+1] TAILSCALE_AUTH_KEY 設定確認 (オプション)${NC}"
        echo -e "${YELLOW}   ⚠️  SKIP（ローカルモード許容）${NC}"
    fi
    run_test "ECC_PROFILE 設定確認" "test -n '$ECC_PROFILE'"
fi

# システム依存関係テスト
echo ""
echo -e "${BLUE}🔧 システム依存関係テスト${NC}"
run_test "Node.js インストール確認" "command -v node"
run_test "npm インストール確認" "command -v npm"
run_test "curl インストール確認" "command -v curl"
run_test "git インストール確認" "command -v git"
run_test "Tailscale インストール確認" "command -v tailscale"

# Node.js エコシステムテスト
echo ""
echo -e "${BLUE}📦 Node.js エコシステムテスト${NC}"
run_test "OpenCode CLI インストール確認" "command -v opencode"
run_test "OpenChamber インストール確認" "command -v openchamber"
run_test "ECC インストール確認" "command -v ecc"

# OpenCode 設定テスト
echo ""
echo -e "${BLUE}🤖 OpenCode 設定テスト${NC}"
run_test "OpenCode設定ディレクトリ確認" "test -d ~/.opencode"
run_test "OpenCode設定ファイル確認" "test -f ~/.opencode/opencode.json"

if command -v opencode &>/dev/null; then
    run_test "OpenCode バージョン確認" "opencode --version"
fi

# ECC 設定テスト
echo ""
echo -e "${BLUE}🎯 ECC 設定テスト${NC}"
if command -v ecc &>/dev/null; then
    run_test "ECC バージョン確認" "ecc --version"
    run_test "ECC スキルリスト取得" "timeout 10 ecc skills list"
fi

# 基盤構造テスト
echo ""
echo -e "${BLUE}📁 基盤構造テスト${NC}"
run_test "README.md 存在確認" "test -f /workspace/README.md"
run_test "scripts ディレクトリ確認" "test -d /workspace/scripts"
run_test "src ディレクトリ確認" "test -d /workspace/src"
run_test "docs ディレクトリ確認" "test -d /workspace/docs"

# スクリプト実行権限テスト
echo ""
echo -e "${BLUE}🔒 スクリプト権限テスト${NC}"
run_test "setup.sh 実行権限" "test -x /workspace/.devcontainer/setup.sh"
run_test "startup.sh 実行権限" "test -x /workspace/.devcontainer/startup.sh"
run_test "interactive-setup.sh 実行権限" "test -x /workspace/.devcontainer/interactive-setup.sh"
run_test "env-validator.sh 実行権限" "test -x /workspace/.devcontainer/env-validator.sh"

if [[ -f "/workspace/scripts/start-services.sh" ]]; then
    run_test "start-services.sh 実行権限" "test -x /workspace/scripts/start-services.sh"
fi

# ポートテスト
echo ""
echo -e "${BLUE}🌐 ポート利用可能性テスト${NC}"

check_port() {
    local port="$1"
    ! netstat -tuln 2>/dev/null | grep ":$port " &>/dev/null
}

run_test "ポート 3000 (OpenChamber) 利用可能" "check_port 3000"
run_test "ポート 4095 (OpenCode CLI) 利用可能" "check_port 4095"  

# ネットワーク接続テスト
echo ""
echo -e "${BLUE}🔗 ネットワーク接続テスト${NC}"
run_test "インターネット接続確認" "timeout 5 curl -s https://google.com"
run_test "npm レジストリ接続確認" "timeout 5 curl -s https://registry.npmjs.org"
run_test "Tailscale API 接続確認" "timeout 5 curl -s https://api.tailscale.com"

# ファイル権限テスト
echo ""
echo -e "${BLUE}🔐 セキュリティテスト${NC}"
if [[ -f "/workspace/.env" ]]; then
    ENV_PERMS=$(stat -c "%a" /workspace/.env 2>/dev/null || echo "000")
    run_test ".env ファイル権限 (600)" "test '$ENV_PERMS' = '600'"
fi

run_test ".gitignore に .env 除外設定" "grep -q '\.env' /workspace/.gitignore"

# Docker 関連テスト
echo ""
echo -e "${BLUE}🐳 Docker 環境テスト${NC}"
run_test "Docker ソケット確認" "test -S /var/run/docker-host.sock"
run_test "vscode ユーザー確認" "id vscode"
run_test "sudo 権限確認" "sudo -n true"

# パフォーマンステスト
echo ""
echo -e "${BLUE}⚡ パフォーマンステスト${NC}"
run_test "メモリ使用量チェック (< 80%)" "test $(free | grep '^Mem:' | awk '{printf \"%.0f\", $3/$2*100}') -lt 80"

# ディスク容量チェック  
DISK_USAGE=$(df /workspace | tail -1 | awk '{print $5}' | sed 's/%//')
run_test "ディスク使用量チェック (< 90%)" "test $DISK_USAGE -lt 90"

# 統合テスト（簡易）
echo ""
echo -e "${BLUE}🔄 統合テスト（簡易）${NC}"

if [[ -n "$TAILSCALE_AUTH_KEY" && "$TAILSCALE_AUTH_KEY" != "your-tailscale-auth-key-here" ]]; then
    run_test "Tailscale 認証テスト" "timeout 10 tailscale --socket=/run/tailscale/tailscaled.sock up --auth-key='$TAILSCALE_AUTH_KEY' --reset"
fi

# テスト結果サマリー
echo ""
echo -e "${PURPLE}📊 テスト結果サマリー${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ 成功: $TESTS_PASSED/${TESTS_TOTAL} テスト${NC}"
echo -e "${RED}❌ 失敗: $TESTS_FAILED/${TESTS_TOTAL} テスト${NC}"

SUCCESS_RATE=$(echo "scale=1; $TESTS_PASSED*100/$TESTS_TOTAL" | bc -l 2>/dev/null || echo "0")
echo -e "${CYAN}📈 成功率: ${SUCCESS_RATE}%${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 評価とアドバイス
if [[ $SUCCESS_RATE -gt 90 ]]; then
    echo -e "${GREEN}🎉 優秀！DevContainerは正常に設定されています${NC}"
elif [[ $SUCCESS_RATE -gt 75 ]]; then
    echo -e "${YELLOW}⚠️  良好：いくつかの問題がありますが、基本的には動作します${NC}"
else
    echo -e "${RED}❌ 要注意：重要な問題があります。設定を見直してください${NC}"
fi

# 失敗した場合のトラブルシューティング
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}🔧 トラブルシューティング推奨事項:${NC}"
    echo ""
    
    if [[ -z "$TAILSCALE_AUTH_KEY" || "$TAILSCALE_AUTH_KEY" == "your-tailscale-auth-key-here" ]]; then
        echo -e "${CYAN}🔑 Tailscale Auth Key:${NC}"
        echo "   1. https://login.tailscale.com/admin/settings/keys でキー生成"
        echo "   2. .env ファイルに TAILSCALE_AUTH_KEY を設定"
        echo ""
    fi
    
    if ! command -v opencode &>/dev/null; then
        echo -e "${CYAN}🤖 OpenCode CLI:${NC}"
        echo "   npm install -g @opencode-ai/cli"
        echo ""
    fi
    
    echo -e "${CYAN}🆘 さらなるサポート:${NC}"
    echo "   - README.md の詳細手順を確認"
    echo "   - docs/SETUP.md のトラブルシューティング参照"
    echo "   - GitHub Issues で問題を報告"
fi

echo ""
echo -e "${BLUE}🏁 テスト完了${NC}"

# 終了コード
if [[ $TESTS_FAILED -eq 0 ]]; then
    exit 0
else
    exit 1
fi
