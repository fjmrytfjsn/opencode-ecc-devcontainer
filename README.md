# 🚀 OpenCode ECC DevContainer Template

[![Open in DevContainer](https://img.shields.io/static/v1?label=DevContainer&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/YOUR_USERNAME/opencode-ecc-devcontainer)

**完全統合開発環境**: OpenCode + Everything Claude Code + OpenChamber + Tailscale

スマートフォンからAIエージェントを操作可能な、次世代開発環境テンプレートです。

## 🌟 特徴

### 🔧 含まれるツール

- **OpenCode CLI** - AI エージェント実行エンジン
- **Everything Claude Code (ECC)** - 136スキル + 30エージェント
- **OpenChamber** - プレミアム Web UI（PWA対応）
- **Tailscale** - セキュアなメッシュネットワーク

### 📱 スマートフォン対応

- Tailscale経由でどこからでもアクセス
- PWA でネイティブアプリライク体験
- タッチ操作最適化UI
- オフライン対応

### 🔐 セキュリティ

- Tailscale によるゼロトラスト接続
- DevContainer による完全隔離
- 認証キー管理

## 🚀 クイックスタート

### 1. Tailscale Auth Key の取得

1. [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys) にアクセス
2. **Generate auth key** をクリック
3. **Reusable** と **Ephemeral** をチェック
4. Auth Key をコピー（`tskey-auth-xxxxxxxxxx` の形式）

### 2. DevContainer で起動

```bash
# 1. リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/opencode-ecc-devcontainer.git
cd opencode-ecc-devcontainer

# 2. 🚀 最適化ビルド（初回時推奨）
./scripts/build-optimized.sh

# 3. DevContainer起動
code .
# → Command Palette (Ctrl+Shift+P)
# → "Dev Containers: Reopen in Container"
```

### ⚡ **対話式プロジェクト初期化**

DevContainer起動後、ターミナルで対話式セットアップを実行してください：

```bash
# 🎯 対話式プロジェクト初期化実行
./.devcontainer/interactive-setup.sh

# または
bash .devcontainer/interactive-setup.sh
```

**セットアップフロー**:

```bash
# 🎯 プロジェクト情報入力
プロジェクト名: my-ai-assistant
説明: AIアシスタント開発プロジェクト
作者名: Developer

# 🔐 セキュリティ設定（オプション）
Tailscale Auth Key: tskey-auth-xxxxxxxxxx
ホスト名: my-ai-assistant-dev

# ⚙️ ECC プロファイル選択
1) minimal   - 基本機能のみ（20+ スキル）
2) developer - 開発者向け（100+ スキル）⭐ 推奨
3) full      - 全機能（136+ スキル）
```

**自動生成されるファイル**:

- ✅ `.env` - 環境変数設定
- ✅ `README.md` - プロジェクト専用説明書
- ✅ `package.json` - Node.js設定
- ✅ `src/app.js` - メインアプリケーション
- ✅ `scripts/start-services.sh` - サービス起動スクリプト
- ✅ `docs/SETUP.md` - セットアップガイド

### 🔧 **手動セットアップ（対話式スキップ時）**

```bash
# 1. 環境変数設定ファイルを作成
cp .env.template .env

# 2. .env ファイルを編集してTailscale Auth Keyを設定
nano .env
# TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxx に変更

# 3. 対話式セットアップを手動実行
./.devcontainer/interactive-setup.sh
```

### ⚡ **最適化ビルド機能**

```bash
# 🚀 高速ビルド（50%高速化）
./scripts/build-optimized.sh

# 📊 ビルド時間比較
# 従来版: ~8-12分
# 最適化版: ~4-6分  ⚡
```

**最適化内容**:

- ✅ マルチステージビルド
- ✅ レイヤーキャッシュ最適化
- ✅ 並列インストール
- ✅ APTキャッシュマウント
- ✅ 重複排除

### 🧪 **セットアップ検証**

```bash
# 🔍 全機能テスト（35+ チェック項目）
./.devcontainer/validate-setup.sh

# 📊 テスト結果例
✅ 成功: 32/35 テスト
❌ 失敗: 3/35 テスト
📈 成功率: 91.4%
🎉 優秀！DevContainerは正常に設定されています
```

## 🎨 **Tailscale統合ダッシュボード**

### 📊 **統合管理機能**

対話式セットアップで生成されるダッシュボードから全ての操作が可能：

```bash
# アクセス方法
🎨 ダッシュボード: http://localhost:8080

# 主要機能
✅ Tailscale設定・起動・監視
✅ サービス状態リアルタイム監視
✅ ネットワーク情報自動検出
✅ QRコード生成
✅ ワンクリックアクセス
```

#### **🔗 Tailscale統合機能**

| **状態**   | **ダッシュボード表示**   | **可能な操作**         |
| ---------- | ------------------------ | ---------------------- |
| **未設定** | ❌ 未接続 + 設定フォーム | Auth Key入力→接続開始  |
| **接続中** | ✅ 接続済み + IP表示     | 再接続・停止・QRコード |
| **エラー** | ⚠️ 接続失敗 + エラー表示 | 再試行・設定確認       |

#### **💡 ワンクリック操作**

```
🔗 Tailscale制御パネル
┌─────────────────────────────────┐
│ ✅ 接続中                        │
│ 📍 IP: 100.64.0.50              │
│ 🏷️ ホスト: my-project-dev       │
│ 📱 接続デバイス: 3台             │
├─────────────────────────────────┤
│ [🔄 再接続] [⏹️ 停止] [📱 QR]    │
└─────────────────────────────────┘
```

### 🌐 **リアルタイム監視**

- **30秒自動更新**: サービス状態・Tailscale接続を自動監視
- **ステータス表示**: 緑●=動作中、赤●=停止
- **IP自動検出**: ローカル・LAN・Tailscale IPを自動表示
- **ワンクリックアクセス**: 全サービスへの直接リンク

## 📱 **Auth Key無しでも完全動作**

### 🏠 **ローカル開発モード**

Tailscale Auth Key未設定でもフル機能で動作：

```bash
# 1. クローンして即座に起動
git clone https://github.com/YOUR_USERNAME/opencode-ecc-devcontainer.git
code opencode-ecc-devcontainer
# → DevContainer起動 → 対話式セットアップ（Auth Keyスキップ可能）

# 2. ローカルでアクセス
🎨 OpenChamber:    http://localhost:3000
🤖 OpenCode CLI:   http://localhost:4095
🚀 ダッシュボード:  http://localhost:8080
```

### 📶 **LAN内アクセス**

同じWiFi/ネットワーク内のデバイスからアクセス：

```bash
# ネットワーク情報とQRコード表示
./scripts/show-network-info.sh

# 例：スマートフォンでアクセス
🎨 OpenChamber: http://192.168.1.100:3000
📱 QRコード付きで簡単アクセス
```

### 📱 **後からTailscale有効化**

```bash
# いつでもTailscaleを有効にできる
./scripts/setup-tailscale.sh

# 🔑 Auth Key 入力 → 世界中からアクセス可能
🌍 Tailscale: http://tailscale-ip:3000
```

## 🎯 **使用パターン**

| **用途**         | **設定**     | **アクセス方法**    |
| ---------------- | ------------ | ------------------- |
| **ローカル開発** | Auth Key不要 | `localhost:3000`    |
| **LAN内共有**    | Auth Key不要 | `192.168.x.x:3000`  |
| **モバイル開発** | Auth Key設定 | `tailscale-ip:3000` |
| **リモート作業** | Auth Key設定 | 世界中どこからでも  |

# オプション: カスタム設定

TAILSCALE_HOSTNAME=my-opencode-dev
ECC_PROFILE=developer

````

**VS Code Command Palette** (Ctrl+Shift+P) から:

- **"Dev Containers: Reopen in Container"** を実行

### 3. スマートフォンでアクセス

1. **Tailscale アプリ** で同じアカウントにログイン
2. **OpenChamber** にアクセス: `http://[container-ip]:3000`
3. **PWA インストール**: ホーム画面に追加
4. **/init** でセッション初期化
5. 🎉 **AIエージェントと対話開始**

## 📋 サービス一覧

| サービス         | ポート | 説明                 |
| ---------------- | ------ | -------------------- |
| **OpenChamber**  | 3000   | プレミアム Web UI    |
| **OpenCode CLI** | 4095   | AI エージェント API  |
| **Sample App**   | 8080   | 開発用テストサーバー |

## 🛠️ 開発コマンド

```bash
# OpenCode エージェント起動
opencode

# OpenChamber Web UI 起動
openchamber

# ECC スキル一覧
ecc skills list

# サンプルアプリ起動
cd sample-project
npm run dev
````

## 🎯 使用例

### 📱 緊急バグ修正（スマートフォンから）

```
🚨 深夜の緊急アラート
📱 Tailscale 経由で OpenChamber アクセス
🤖 「このエラーログを解析して修正して」
🔧 AIエージェントが自動修正・テスト・デプロイ
✅ スマートフォンから問題解決完了
```

### 👥 チーム開発

```
👨‍💻 メンバーA: コード作成
👩‍💻 メンバーB: OpenChamber でレビュー
🤖 AIエージェント: 最適化提案
📱 全員スマートフォンから確認可能
```

## 🔧 カスタマイズ

### 環境変数

ローカルで `.env` ファイルを作成（`.env.template` からコピー）:

```bash
# 必須設定
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxxxxxxxxx

# オプション設定
TAILSCALE_HOSTNAME=my-opencode-dev        # デフォルト: opencode-dev
ECC_PROFILE=developer                     # minimal/developer/full
OPENCODE_PORT=4095                        # デフォルト: 4095
OPENCHAMBER_PORT=3000                     # デフォルト: 3000
NODE_ENV=development                      # デフォルト: development
```

### ECC プロファイル

| プロファイル  | 説明         | スキル数 |
| ------------- | ------------ | -------- |
| **minimal**   | 基本機能のみ | 20+      |
| **developer** | 開発者向け   | 100+     |
| **full**      | 全機能       | 136+     |

## 📁 ディレクトリ構造

```
.
├── .devcontainer/
│   ├── devcontainer.json    # DevContainer設定
│   ├── docker-compose.yml   # Docker Compose
│   ├── Dockerfile           # カスタムイメージ
│   ├── setup.sh            # 初期セットアップ
│   ├── startup.sh          # サービス起動
│   └── entrypoint.sh       # エントリーポイント
├── sample-project/         # サンプルプロジェクト
│   ├── package.json
│   ├── index.js
│   └── README.md
├── docs/                   # ドキュメント
├── .env.template          # 環境変数テンプレート
└── README.md              # このファイル
```

## 🌐 ネットワーク構成

```
📱 Smartphone (Tailscale)
    ↓
☁️  Tailscale Mesh Network
    ↓
🖥️  DevContainer (Ubuntu 24.04)
    ├── 🤖 OpenCode CLI (Port 4095)
    ├── 🌐 OpenChamber (Port 3000)
    └── 🚀 Sample App (Port 8080)
```

## 🔒 セキュリティ機能

- **🔐 Tailscale ゼロトラスト**: 認証されたデバイスのみアクセス
- **🏠 DevContainer 分離**: ホストシステムから完全隔離
- **🔑 Auth Key 管理**: 一時的・再利用可能キー
- **📱 デバイス認証**: Tailscale デバイス承認制御

## 🎛️ 高度な設定

### Cloudflare Tunnel との併用

```bash
# 内部チーム: Tailscale
# 外部ゲスト: Cloudflare Tunnel
openchamber tunnel start --provider cloudflare --mode quick
```

### VS Code Extensions

DevContainer に自動インストールされる拡張機能:

- GitHub Copilot
- OpenCode Extension (将来追加予定)
- Docker Extension
- Tailscale Extension (将来追加予定)

## 🐛 トラブルシューティング

### ❌ **ECC ajv エラー**

```log
Error: Cannot find module 'ajv'
```

**原因**: ECCパッケージングの依存関係問題  
**解決方法**:

```bash
# 🔧 自動修正スクリプト実行
./scripts/fix-ecc-ajv.sh

# または手動修正
ECC_DIR=$(npm list -g ecc-universal | head -n1 | awk '{print $1}')/node_modules/ecc-universal
cd "$ECC_DIR"
npm install ajv
npm install  # 全依存関係再インストール
```

### ❌ **DevContainer ビルド失敗**

```
useradd: user 'vscode' already exists
```

**解決済み**: 最新テンプレートで修正済み

### ❌ **DevContainer起動時停止**

```
Run in container: /bin/sh -c .devcontainer/interactive-setup.sh
```

**解決済み**: 手動実行方式に変更済み

### Tailscale 接続問題

```bash
# コンテナ内で確認
sudo tailscale status
sudo tailscale ip -4

# Auth Key 再設定
export TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxx
```

### OpenChamber アクセス問題

```bash
# ポート確認
curl http://localhost:3000/health

# ログ確認
docker logs opencode-ecc-dev
```

## 📚 関連リソース

- [OpenCode 公式ドキュメント](https://opencode.ai/docs)
- [Everything Claude Code GitHub](https://github.com/affaan-m/everything-claude-code)
- [OpenChamber GitHub](https://github.com/openchamber/openchamber)
- [Tailscale ドキュメント](https://tailscale.com/kb)

## 🤝 コントリビューション

1. Fork this repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

---

**🎉 Happy Coding with AI Agents!**

Made with ❤️ for the OpenCode Community
