# 🚀 OpenCode ECC DevContainer - セットアップガイド

## 📋 前提条件

- Docker Desktop インストール済み
- VS Code + Dev Containers 拡張機能
- Tailscale アカウント

## 🔧 ステップ・バイ・ステップ セットアップ

### Step 1: リポジトリのクローン

```bash
git clone https://github.com/YOUR_USERNAME/opencode-ecc-devcontainer.git
cd opencode-ecc-devcontainer
```

### Step 2: Tailscale Auth Key の取得

1. **Tailscale Admin Console** にアクセス:  
   https://login.tailscale.com/admin/settings/keys

2. **「Generate auth key」** をクリック

3. **設定をチェック**:
   - ✅ **Reusable** (再利用可能)
   - ✅ **Ephemeral** (一時的)
   - ⏰ **Expiry**: 90日 (推奨)

4. **「Generate key」** をクリック

5. **Auth Key をコピー**（例: `tskey-auth-k123456789abcdef...`）

### Step 3: 環境設定ファイル作成

```bash
# テンプレートをコピー
cp .env.template .env

# .env ファイルを編集
nano .env
```

**⚠️ 重要**: この手順を忘れるとTailscale接続できません！

**最小限の設定:**
```bash
TAILSCALE_AUTH_KEY=tskey-auth-k123456789abcdef
```

### Step 4: DevContainer 起動

1. **VS Code でプロジェクトを開く:** `code .`

2. **Command Palette:** `Ctrl+Shift+P`

3. **コマンド実行:** `Dev Containers: Reopen in Container`

4. **初回ビルド待機:** 5-10分

### Step 5: スマートフォン接続

1. **Tailscale アプリ** で同じアカウントにログイン

2. **Container IP確認:**
   ```bash
   sudo tailscale ip -4
   ```

3. **ブラウザでアクセス:**
   ```
   http://[container-tailscale-ip]:3000
   ```

## 🐛 よくある問題

### `.env ファイル未作成`
```bash
cp .env.template .env
nano .env  # TAILSCALE_AUTH_KEY を設定
```

### `DevContainer ビルドエラー`
```bash
# Command Palette → "Dev Containers: Rebuild Container"
```

---

**詳細は [完全セットアップガイド](SETUP_GUIDE.md) を参照**