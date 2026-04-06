# QUICK START

## 目的

このリポジトリを OpenCode / OpenChamber / Tailscale の基盤環境として起動します。

## 手順

1. リポジトリをクローン

```bash
git clone https://github.com/<your-account>/opencode-ecc-devcontainer.git
cd opencode-ecc-devcontainer
```

1. `.env` を作成

```bash
cp .env.template .env
```

1. 必要なら Tailscale 情報を設定

- `TAILSCALE_AUTH_KEY`
- `TAILSCALE_HOSTNAME`

1. DevContainer を起動

- VS Code: `Dev Containers: Reopen in Container`

1. （WSL利用時）SSH認証情報の確認

DevContainer は WSL の `~/.ssh` と `SSH_AUTH_SOCK` を利用できます。
WSL 側で次を確認してください。

```bash
if [ -d ~/.ssh/agent.sock ]; then rm -rf ~/.ssh/agent.sock; else rm -f ~/.ssh/agent.sock; fi
eval "$(ssh-agent -a ~/.ssh/agent.sock -s)"
export SSH_AUTH_SOCK=~/.ssh/agent.sock

chmod 700 ~/.ssh
chmod 600 ~/.ssh/<your_key>
chmod 644 ~/.ssh/<your_key>.pub
ssh-add ~/.ssh/<your_key>

echo "$SSH_AUTH_SOCK"
ls -l /home/vscode/.ssh/agent.sock
ssh-add -l
```

`ssh-agent` を単体実行するだけでは現在のシェルに反映されないため、`eval "$(ssh-agent -a ~/.ssh/agent.sock -s)"` を使ってください。
`ssh-add` は公開鍵 (`.pub`) ではなく秘密鍵ファイルを指定してください。

1. 任意で対話セットアップ

```bash
./.devcontainer/interactive-setup.sh
```

## 確認

- OpenChamber: `http://localhost:3000`
- OpenCode CLI Server: `http://localhost:4095`

## 注意

このリポジトリは基盤です。アプリ開発は別リポジトリで行ってください。
