#!/bin/bash
# .opencode ディレクトリ権限修正スクリプト

set -euo pipefail

echo "🔒 .opencode ディレクトリ権限修正ツール"
echo "================================================"
echo ""

# 色設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 問題: EACCES permission denied エラー${NC}"
echo -e "${BLUE}📋 対象: /home/vscode/.opencode/.agents/skills/*${NC}"
echo ""

# 現在の権限確認
echo -e "${YELLOW}🔍 現在の権限状況確認...${NC}"
echo "ユーザー: $(whoami)"
echo "ホームディレクトリ: $(echo $HOME)"

if [[ -d "$HOME/.opencode" ]]; then
    echo -e "${BLUE}📁 .opencode ディレクトリ存在確認:${NC}"
    ls -la "$HOME/.opencode" | head -5
else
    echo -e "${RED}❌ .opencode ディレクトリが存在しません${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 権限修正実行中...${NC}"

# 1. 必要ディレクトリ作成
echo "   📁 ディレクトリ構造作成中..."
mkdir -p "$HOME/.opencode"
mkdir -p "$HOME/.opencode/.agents"
mkdir -p "$HOME/.opencode/.agents/skills"
mkdir -p "$HOME/.opencode/config"

# 2. 所有権修正
echo "   🔑 所有権設定中..."
if command -v sudo >/dev/null 2>&1; then
    sudo chown -R vscode:vscode "$HOME/.opencode" 2>/dev/null || chown -R vscode:vscode "$HOME/.opencode" 2>/dev/null || true
else
    chown -R vscode:vscode "$HOME/.opencode" 2>/dev/null || true
fi

# 3. パーミッション設定
echo "   📊 パーミッション設定中..."
chmod -R 755 "$HOME/.opencode" 2>/dev/null || true
chmod -R u+w "$HOME/.opencode" 2>/dev/null || true

# 4. 結果確認
echo ""
echo -e "${BLUE}🧪 修正結果確認:${NC}"

if [[ -w "$HOME/.opencode" ]]; then
    echo -e "${GREEN}✅ .opencode 書き込み可能${NC}"
else
    echo -e "${RED}❌ .opencode 書き込み不可${NC}"
fi

if [[ -w "$HOME/.opencode/.agents" ]]; then
    echo -e "${GREEN}✅ .agents 書き込み可能${NC}"
else
    echo -e "${RED}❌ .agents 書き込み不可${NC}"
fi

if [[ -w "$HOME/.opencode/.agents/skills" ]]; then
    echo -e "${GREEN}✅ skills 書き込み可能${NC}"
else
    echo -e "${RED}❌ skills 書き込み不可${NC}"
fi

# 5. テスト書き込み
echo ""
echo -e "${BLUE}📝 書き込みテスト実行:${NC}"
TEST_FILE="$HOME/.opencode/.agents/skills/test-write.tmp"

if touch "$TEST_FILE" 2>/dev/null && rm "$TEST_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ 権限修正成功！書き込みテスト通過${NC}"
else
    echo -e "${RED}❌ 権限修正失敗${NC}"
    echo ""
    echo -e "${YELLOW}📋 手動修正手順:${NC}"
    echo "   1. sudo chown -R vscode:vscode $HOME"
    echo "   2. chmod -R 755 $HOME/.opencode"
    echo "   3. chmod -R u+w $HOME/.opencode"
fi

echo ""
echo -e "${BLUE}🎯 修正完了後の推奨アクション:${NC}"
echo "   💡 ECC再実行: ecc install --target opencode --profile developer"
echo "   📖 権限確認: ls -la ~/.opencode/"
echo "   🧪 動作テスト: ecc --version"
echo ""
echo "================================================"