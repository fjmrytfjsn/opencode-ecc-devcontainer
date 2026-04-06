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

### 3.1 WSLのSSH認証情報を使う（Git SSH用）

このリポジトリの DevContainer は、WSL 側の `~/.ssh` と `SSH_AUTH_SOCK` をコンテナへマウントします。

WSL 側で以下を確認してから `Rebuild and Reopen in Container` を実行してください。

```bash
# WSL 側で実行
# 固定ソケットでssh-agentを起動（DevContainer連携用）
if [ -d ~/.ssh/agent.sock ]; then rm -rf ~/.ssh/agent.sock; else rm -f ~/.ssh/agent.sock; fi
eval "$(ssh-agent -a ~/.ssh/agent.sock -s)"
export SSH_AUTH_SOCK=~/.ssh/agent.sock

chmod 700 ~/.ssh
chmod 600 ~/.ssh/<your_key>
chmod 644 ~/.ssh/<your_key>.pub
ssh-add ~/.ssh/<your_key>

echo "$SSH_AUTH_SOCK"
ssh-add -l
```

- `ssh-agent` を単体実行するだけでは現在のシェルに反映されないため、`eval "$(ssh-agent -a ~/.ssh/agent.sock -s)"` を使ってください。
- `ssh-add` は公開鍵 (`.pub`) ではなく秘密鍵ファイルを指定してください。
- `ssh-add -l` で鍵が出ない場合は、`chmod 700 ~/.ssh && chmod 600 ~/.ssh/<your_key>` の後に `ssh-add ~/.ssh/<your_key>` を実行してください。

起動後、DevContainer 内で次を確認できます。

```bash
echo "$SSH_AUTH_SOCK"
ls -l /home/vscode/.ssh/agent.sock
ssh-add -l
ssh -T git@github.com
```

`echo "$SSH_AUTH_SOCK"` が空の場合は、次を確認してください。

```bash
# WSL 側
if [ -d ~/.ssh/agent.sock ]; then rm -rf ~/.ssh/agent.sock; else rm -f ~/.ssh/agent.sock; fi
eval "$(ssh-agent -a ~/.ssh/agent.sock -s)"
export SSH_AUTH_SOCK=~/.ssh/agent.sock
ssh-add ~/.ssh/<your_key>
echo "$SSH_AUTH_SOCK"

# 同じ WSL シェルから VS Code を起動
code .
```

その後、`Dev Containers: Rebuild and Reopen in Container` を実行してください。

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
