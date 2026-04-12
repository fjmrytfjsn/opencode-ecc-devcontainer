#!/bin/bash
# OpenCode ECC設定修正スクリプト
# tools配列形式をオブジェクト形式に変換し、colorフィールドを削除

set -e

TARGET_DIR="${1:-$HOME/.opencode/agents}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ エラー: ディレクトリが見つかりません: $TARGET_DIR"
    exit 1
fi

echo "🔧 OpenCode ECC設定ファイルを修正中..."
echo "📂 対象ディレクトリ: $TARGET_DIR"

cd "$TARGET_DIR"
count=0

for file in *.md; do
    [ -f "$file" ] || continue
    
    # ファイルのバックアップ
    cp "$file" "${file}.bak"
    
    # tools配列 -> オブジェクト形式に変換（様々なパターンに対応）
    sed -i 's/tools: \[\s*\"\?Read\"\?,\?\s*\"\?Write\"\?,\?\s*\"\?Edit\"\?,\?\s*\"\?Bash\"\?,\?\s*\"\?Grep\"\?,\?\s*\"\?Glob\"\?\s*\]/tools:\n  read: true\n  write: true\n  edit: true\n  bash: true\n  grep: true\n  glob: true/' "$file"
    sed -i 's/tools: \[\"Read\", \"Grep\", \"Glob\"\]/tools:\n  read: true\n  grep: true\n  glob: true/' "$file"
    sed -i 's/tools: \[\"Read\", \"Grep\", \"Glob\", \"Bash\"\]/tools:\n  read: true\n  grep: true\n  glob: true\n  bash: true/' "$file"
    sed -i 's/tools: \[\"Read\", \"Grep\", \"Glob\", \"Bash\", \"Edit\"\]/tools:\n  read: true\n  grep: true\n  glob: true\n  bash: true\n  edit: true/' "$file"
    sed -i 's/tools: \[\"Read\", \"Write\", \"Edit\", \"Bash\", \"Grep\"\]/tools:\n  read: true\n  write: true\n  edit: true\n  bash: true\n  grep: true/' "$file"
    sed -i 's/tools: \[\"Read\", \"Bash\"\]/tools:\n  read: true\n  bash: true/' "$file"
    
    # colorフィールドを削除（teal, orange等の名前ベースの色は無効）
    sed -i '/^color:/d' "$file"
    
    # バックアップと比較して変更があったかチェック
    if ! cmp -s "$file" "${file}.bak"; then
        ((count++))
    fi
    
    # バックアップファイル削除
    rm -f "${file}.bak"
done

echo "✅ 完了: ${count}個のファイルを修正しました"
ls *.md 2>/dev/null | wc -l | xargs echo "📊 総ファイル数:"
