# QUICK START

## 目的

このリポジトリを OpenCode / OpenChamber / Tailscale の基盤環境として起動します。

## 手順

1. リポジトリをクローン

```bash
git clone https://github.com/<your-account>/opencode-ecc-devcontainer.git
cd opencode-ecc-devcontainer
```

2. `.env` を作成

```bash
cp .env.template .env
```

3. 必要なら Tailscale 情報を設定

- `TAILSCALE_AUTH_KEY`
- `TAILSCALE_HOSTNAME`

4. DevContainer を起動

- VS Code: `Dev Containers: Reopen in Container`

5. 任意で対話セットアップ

```bash
./.devcontainer/interactive-setup.sh
```

## 確認

- OpenChamber: `http://localhost:3000`
- OpenCode CLI Server: `http://localhost:4095`

## 注意

このリポジトリは基盤です。アプリ開発は別リポジトリで行ってください。
