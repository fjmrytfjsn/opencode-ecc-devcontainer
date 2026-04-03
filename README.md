# OpenCode ECC DevContainer (Infrastructure Mode)

OpenCode + OpenChamber + Tailscale を動かすための基盤リポジトリです。
このリポジトリはアプリ開発用の成果物リポジトリではありません。

## 方針

- このリポジトリはローカル基盤として利用する
- 開発対象は各プロジェクトの独立リポジトリで管理する
- セットアップ項目は Tailscale を中心に最小化する

## 含まれるサービス

- OpenChamber: `http://localhost:3000`
- OpenCode CLI Server: `http://localhost:4095`

## セットアップ

### 1. クローン

```bash
git clone https://github.com/<your-account>/opencode-ecc-devcontainer.git
cd opencode-ecc-devcontainer
```

### 2. `.env` を準備

```bash
cp .env.template .env
```

必要なら次を設定します。

- `TAILSCALE_AUTH_KEY`
- `TAILSCALE_HOSTNAME`
- `ECC_PROFILE` (optional: `minimal` / `developer` / `full`)

### 3. DevContainer 起動

VS Code で `Dev Containers: Reopen in Container` を実行します。

### 4. 任意: 対話セットアップ

```bash
./.devcontainer/interactive-setup.sh
```

このセットアップは Tailscale 関連設定のみを扱います。

## 運用

- 各開発プロジェクトは別リポジトリとして clone し、そちらでコミット/PR を行ってください。
- この基盤リポジトリには、原則として開発成果物を置きません。

## トラブルシュート

- 設定検証: `./.devcontainer/validate-setup.sh`
- Tailscale 後付け設定: `./scripts/setup-tailscale.sh`
- 診断: `./scripts/diagnose-devcontainer.sh`
