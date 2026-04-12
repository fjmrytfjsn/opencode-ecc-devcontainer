# ecc-universal 設定エラー調査レポート

## 📊 調査結果サマリー

### **現状**
- **インストール済みバージョン**: v1.9.0 (2026年3月21日リリース)
- **最新npm版**: v1.9.0 (npmに公開済み)
- **最新GitHub版**: v1.10.0 (2026年4月5日リリース、npmには未公開)

### **設定形式の問題**

**現在のecc-universal (v1.9.0 & v1.10.0):**
```yaml
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
color: teal
```

**OpenCodeが期待する形式:**
```yaml
tools:
  read: true
  write: true
  edit: true
  bash: true
  grep: true
  glob: true
# colorフィールドは削除または有効な値のみ
```

### **v1.10.0 でも修正されていない**

GitHub上のv1.10.0とmainブランチを確認した結果：
- ✅ 設定形式は**変わっていない**（配列形式のまま）
- ⚠️ npmには未公開（Issue #1287で報告あり）

## 🔍 関連するGitHub Issues

### **Issue #802: [ECC 2.0] Module 8: Agent profiles (model, tools, permissions)**
- **ステータス**: Open
- **内容**: エージェントプロファイル（model, tools, permissions）の設計
- **影響**: この issue で設定形式の改善が議論される可能性

### **Issue #801: [ECC 2.0] Module 8: TOML config file support**
- **ステータス**: Open
- **内容**: TOML設定ファイルサポート
- **影響**: 将来的な設定形式の大幅な変更の可能性

### **Issue #1287: v1.10.0 npm package still missing .opencode/dist/**
- **ステータス**: Open
- **内容**: v1.10.0がnpmに公開されていない
- **影響**: 最新バージョンが利用不可

## 💡 結論と推奨事項

### **1. 上流パッケージは当面修正されない**

- ecc-universalは配列形式を使い続けている
- ECC 2.0 (Module 8) で将来的に変更予定だが時期不明
- 当面は**ローカルで自動修正する必要がある**

### **2. 推奨する対応策**

#### **A. startup.shに自動修正を組み込む（即時対応）**

```bash
# .devcontainer/startup.sh に追加
echo "🔧 OpenCode ECC設定を修正中..."
python3 /workspace/scripts/fix-ecc-agents.py /home/vscode/.opencode/agents

if [ $? -eq 0 ]; then
    echo "✅ OpenCode ECC設定修正完了"
else
    echo "⚠️ OpenCode ECC設定修正に失敗しました"
fi
```

**メリット:**
- DevContainer起動時に自動修正
- `ecc repair`後も再修正
- メンテナンス不要

**デメリット:**
- 起動時間が数秒増加

#### **B. カスタムECCプロファイルを作成（代替案）**

ecc-universalを使わず、独自の設定セットを管理：

```bash
# カスタム設定を /workspace/.opencode-custom/ に配置
ecc install --source /workspace/.opencode-custom --target opencode-home
```

**メリット:**
- 完全なコントロール
- パッケージ更新の影響を受けない

**デメリット:**
- 手動メンテナンスが必要
- 新機能の取り込みに手間

#### **C. 上流に貢献（長期的解決）**

1. GitHubリポジトリにPRを送る
2. Issue #802 のディスカッションに参加
3. OpenCodeの期待形式をドキュメント化

### **3. モニタリング計画**

以下を定期的に確認：
- [ ] ecc-universal npm版のリリース（週次）
- [ ] Issue #802, #801 の進捗（週次）
- [ ] OpenCode側の設定形式変更（月次）

## 🛠️ 実装スクリプト

すでに作成済み:
- ✅ `/workspace/scripts/fix-ecc-agents.py` - Python版自動修正
- ✅ `/workspace/scripts/fix-ecc-config.sh` - Bash版自動修正

## 📝 次のアクション

1. **即座に**: startup.shに自動修正を組み込む
2. **短期**: GitHub Issueで状況を報告・質問
3. **中期**: ECC 2.0の進捗を追跡
4. **長期**: 必要に応じて上流にPR送信

---

**調査日**: 2026年4月6日  
**リポジトリ**: https://github.com/affaan-m/everything-claude-code  
**パッケージ**: ecc-universal@1.9.0
