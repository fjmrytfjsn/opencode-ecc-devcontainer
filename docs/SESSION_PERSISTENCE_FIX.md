# OpenCode セッション保持問題の診断レポート

## 🔍 問題の症状

`.devcontainer/data/opencode`を`/home/vscode/.opencode`にマウントしたが、リビルド後にセッションが保持されない。

## 🎯 根本原因

**設定は正しいが、古いDocker volumeが残っていて優先されている**

### 詳細

1. **docker-compose.ymlの設定（正しい）:**
   ```yaml
   volumes:
     - ../.devcontainer/data/opencode:/home/vscode/.opencode
   ```

2. **実際のマウント状態（間違っている）:**
   ```
   Source: /var/lib/docker/volumes/opencode-data/_data
   Destination: /home/vscode/.opencode
   Type: volume (名前付きボリューム)
   ```

3. **理由:**
   - 初回起動時に`opencode-data`という名前付きボリュームが作成された
   - その後docker-compose.ymlを変更したが、既存のボリュームが優先される
   - DevContainerは既存のボリュームを自動削除しない

## ✅ 解決手順

### **ステップ1: 現在のデータをバックアップ（重要）**

```bash
# コンテナ停止
docker stop opencode-ecc-dev

# 現在のボリュームデータをバックアップ
docker run --rm -v opencode-data:/source -v $(pwd)/.devcontainer/data/opencode-backup:/backup alpine tar czf /backup/opencode-volume-backup.tar.gz -C /source .
```

### **ステップ2: 古いボリュームとコンテナを削除**

```bash
# コンテナ削除
docker rm -f opencode-ecc-dev

# 古いボリュームを削除
docker volume rm opencode-data
docker volume rm devcontainer_opencode-data
docker volume rm opencode-ecc-devcontainer_devcontainer_opencode-data
docker volume rm opencode-ecc-devcontainer-container_devcontainer_opencode-data

# 確認
docker volume ls | grep opencode
# 何も表示されなければOK
```

### **ステップ3: バインドマウント用ディレクトリの準備**

```bash
# ディレクトリが既に存在し、データがある場合はそのまま
# 空の場合は初期化が必要
ls -la .devcontainer/data/opencode/

# もし空ならバックアップから復元
# cd .devcontainer/data/opencode
# tar xzf ../opencode-backup/opencode-volume-backup.tar.gz
```

### **ステップ4: DevContainerを再ビルド**

```bash
# VS Codeで実行
# Ctrl+Shift+P -> "Dev Containers: Rebuild Container"

# または CLI で
cd /home/fjsn/github/opencode-ecc-devcontainer
devcontainer up --workspace-folder .
```

### **ステップ5: 確認**

```bash
# コンテナ内でマウント状態を確認
docker exec -it opencode-ecc-dev bash -c "mount | grep '/home/vscode/.opencode'"

# 期待される出力（bindマウント）:
# /dev/sdd on /home/vscode/.opencode type ext4 (bind,...)
# または
# /path/to/.devcontainer/data/opencode on /home/vscode/.opencode type ...

# ホスト側でデータを確認
ls -la .devcontainer/data/opencode/

# コンテナ内でデータを確認
docker exec -it opencode-ecc-dev bash -c "ls -la /home/vscode/.opencode/"

# 両方が同じ内容なら成功
```

## 🔒 予防策

### **docker-compose.ymlから名前付きボリューム定義を削除**

`opencode-data`がvolumesセクションに定義されていないことを確認：

```yaml
volumes:
  tailscale-state:
    driver: local
  tailscale-run:
    driver: local
  # opencode-data: ← これがあったら削除
```

### **.gitignoreに追加**

```gitignore
# DevContainer データ（個人セッション）
.devcontainer/data/opencode/*
!.devcontainer/data/opencode/.gitkeep
.devcontainer/data/opencode-backup/
```

### **devcontainer.jsonのmountsセクション（オプション）**

より明示的にするため、devcontainer.jsonにもマウント設定を追加可能：

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,readonly",
    "source=${localWorkspaceFolder}/.devcontainer/data/opencode,target=/home/vscode/.opencode,type=bind",
    "source=tailscale-state,target=/var/lib/tailscale,type=volume"
  ]
}
```

## 📊 検証コマンド

```bash
# マウントタイプの確認
docker inspect opencode-ecc-dev --format='{{json .Mounts}}' | jq -r '.[] | select(.Destination == "/home/vscode/.opencode") | {Source, Destination, Type}'

# Type: "bind" なら成功
# Type: "volume" ならまだ問題あり
```

## 🎯 期待される結果

- **リビルド前**: セッションデータが`.devcontainer/data/opencode/`に保存される
- **リビルド後**: 同じデータが読み込まれ、セッションが継続
- **ホスト側**: `.devcontainer/data/opencode/`でデータを確認・バックアップ可能

---

**調査日**: 2026年4月7日  
**問題**: 名前付きボリュームがバインドマウントを上書き  
**解決**: 古いボリュームを削除してコンテナ再作成
