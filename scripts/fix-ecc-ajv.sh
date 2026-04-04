#!/bin/bash
# ECC ajv 依存関係エラー修正スクリプト

set -euo pipefail

echo "🔧 ECC ajv 依存関係エラー修正ツール"
echo "================================================"
echo ""

# 色設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 問題: ecc コマンド実行時に 'Cannot find module ajv' エラー${NC}"
echo -e "${BLUE}📋 原因: ECC パッケージングの依存関係問題${NC}"
echo ""

# 1. ECCディレクトリ特定
echo -e "${YELLOW}🔍 ECC インストールディレクトリ特定中...${NC}"
ECC_GLOBAL_DIR=$(npm list -g ecc-universal 2>/dev/null | head -n1 | awk '{print $1}' || echo "")

if [[ -z "$ECC_GLOBAL_DIR" ]]; then
    echo -e "${RED}❌ ECC がグローバルインストールされていません${NC}"
    echo "   インストール: npm install -g ecc-universal"
    exit 1
fi

ECC_MODULE_DIR="$ECC_GLOBAL_DIR/node_modules/ecc-universal"
echo -e "${GREEN}✅ ECC ディレクトリ: $ECC_MODULE_DIR${NC}"

# 2. ajv インストール確認・実行
if [[ -d "$ECC_MODULE_DIR" ]]; then
    echo ""
    echo -e "${YELLOW}🔧 ECC ディレクトリで ajv インストール中...${NC}"
    
    cd "$ECC_MODULE_DIR"
    echo "   現在のディレクトリ: $(pwd)"
    
    # ajv インストール
    if npm install ajv; then
        echo -e "${GREEN}✅ ajv インストール成功${NC}"
    else
        echo -e "${YELLOW}⚠️  ECC内 ajv インストール失敗 - グローバル方式を試行${NC}"
    fi
    
    cd - > /dev/null
else
    echo -e "${RED}❌ ECC モジュールディレクトリが見つかりません: $ECC_MODULE_DIR${NC}"
fi

# 3. グローバル ajv インストール（フォールバック）
echo ""
echo -e "${YELLOW}🔧 グローバル ajv インストール（フォールバック）...${NC}"
if npm install -g ajv; then
    echo -e "${GREEN}✅ グローバル ajv インストール成功${NC}"
else
    echo -e "${YELLOW}⚠️  グローバル ajv インストール失敗${NC}"
fi

# 4. テスト
echo ""
echo -e "${BLUE}🧪 修正テスト実行中...${NC}"
if ecc --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ECC が正常に動作しています！${NC}"
    echo -e "${GREEN}   バージョン: $(ecc --version)${NC}"
    
    # ECC プロファイル情報表示
    echo ""
    echo -e "${BLUE}📊 利用可能な ECC プロファイル:${NC}"
    ecc info profiles 2>/dev/null || echo "   プロファイル情報取得中..."
    
else
    echo -e "${RED}❌ ECC が まだ動作しません${NC}"
    echo ""
    echo -e "${YELLOW}📋 手動修正手順:${NC}"
    echo "   1. cd $ECC_MODULE_DIR"
    echo "   2. npm install"  
    echo "   3. npm install ajv"
    echo "   4. ecc --version で確認"
fi

echo ""
echo -e "${BLUE}🎯 修正完了後の推奨アクション:${NC}"
echo "   💡 ECC設定適用: ecc install --target opencode --profile developer"
echo "   📖 設定確認: cat ~/.opencode/opencode.json"
echo "   🚀 OpenCode起動: opencode"
echo ""
echo "================================================"
