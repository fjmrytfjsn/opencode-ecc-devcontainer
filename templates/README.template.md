# 🚀 {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

**作者**: {{AUTHOR_NAME}}  
**生成日**: {{TIMESTAMP}}

## 🌟 特徴

- **OpenCode CLI** - AI エージェント実行エンジン
- **Everything Claude Code (ECC)** - {{ECC_PROFILE}} プロファイル
- **OpenChamber** - プレミアム Web UI（PWA対応）
- **Tailscale** - セキュアなメッシュネットワーク

## 📱 アクセス方法

### 🖥️ ローカルアクセス
- **OpenChamber UI**: http://localhost:3000
- **OpenCode CLI**: http://localhost:4095  
- **開発サーバー**: http://localhost:8080

### 🌐 リモートアクセス（Tailscale経由）
- **OpenChamber UI**: http://{{TAILSCALE_HOSTNAME}}:3000
- **OpenCode CLI**: http://{{TAILSCALE_HOSTNAME}}:4095
- **開発サーバー**: http://{{TAILSCALE_HOSTNAME}}:8080

## 🚀 使い方

### 1. 開発環境起動
```bash
# DevContainer内で実行
./scripts/start-services.sh
```

### 2. ECC エージェント実行
```bash
# 基本的な使い方
opencode agent list
opencode agent run my-agent

# ECC スキル実行
ecc skill list
ecc skill run code-analysis
```

### 3. OpenChamber でAI操作
1. ブラウザでOpenChamberにアクセス
2. プロンプトでタスクを指示
3. エージェントが自動実行

## 📁 プロジェクト構造

```
.
├── .devcontainer/          # DevContainer設定
├── .env                   # 環境変数（重要：Git管理外）
├── scripts/               # 運用スクリプト
├── src/                   # ソースコード
├── docs/                  # ドキュメント
└── README.md              # このファイル
```

## 🔧 カスタマイズ

### ECCプロファイル変更
`.env` ファイルで `ECC_PROFILE` を変更：
- `minimal`: 基本機能のみ
- `developer`: 開発者向け  
- `full`: 全機能

### ポート変更
`.env` ファイルで各ポート番号を変更可能

## 🆘 トラブルシューティング

### Tailscale接続できない
1. Auth Keyが正しいか確認
2. Tailscaleクライアントで同じネットワークに接続
3. `tailscale status` でノード確認

### OpenChamberにアクセスできない  
1. `docker-compose logs` でログ確認
2. ポート3000が使用可能か確認
3. ファイアウォール設定確認

{{#if REPO_URL}}
## 🔗 リポジトリ

{{REPO_URL}}
{{/if}}