# ✅ セッションデータ永続化の完全修正レポート

## 📋 最終成果

### ✅ 全3つのデータディレクトリが永続化されました

| ディレクトリ | 用途 | マウント先 | サイズ |
|------------|------|-----------|--------|
| `.opencode/` | エージェント設定 | `/home/vscode/.opencode` | 308KB |
| `opencode-storage/` | **セッションデータ** | `/home/vscode/.local/share/opencode` | **1.76MB** |
| `claude/` | **ECCデータベース** | `/home/vscode/.claude` | **118KB** |

## 🔍 問題の経緯

### 初回問題（修正済み）
- **症状**: `.devcontainer/data/opencode`をマウントしたがリビルド後にセッション保持されない
- **原因**: 古いDocker volume `opencode-data`がバインドマウントを上書き
- **対応**: 古いボリュームを削除してバインドマウントを有効化

### 第2の問題（本日発見・修正）
- **症状**: DevContainerで開いてもセッション情報が読み込まれない
- **原因**: **エージェント設定とセッションデータは別の場所に保存される**
  - `.opencode/` → エージェント設定のみ（正しくマウント済み）
  - `.local/share/opencode/` → **セッションデータ**（マウントされていなかった❌）
  - `.claude/` → **ECCデータベース**（マウントされていなかった❌）

## 🛠️ 実施した修正

### 1. docker-compose.yml にマウント追加

```yaml
volumes:
  - ../:/workspace:cached
  # エージェント設定
  - ../.devcontainer/data/opencode:/home/vscode/.opencode
  # OpenCode セッションデータ（追加✅）
  - ../.devcontainer/data/opencode-storage:/home/vscode/.local/share/opencode
  # ECC データベース（追加✅）
  - ../.devcontainer/data/claude:/home/vscode/.claude
  # Tailscale
  - tailscale-state:/var/lib/tailscale
  - tailscale-run:/run/tailscale
  - /var/run/docker.sock:/var/run/docker-host.sock
```

### 2. 既存データの移行

```bash
# 現在実行中のコンテナからデータをコピー
docker cp opencode-ecc-dev:/home/vscode/.local/share/opencode/. \
  .devcontainer/data/opencode-storage/

docker cp opencode-ecc-dev:/home/vscode/.claude/. \
  .devcontainer/data/claude/

# コンテナ再起動
docker stop opencode-ecc-dev && docker rm opencode-ecc-dev
docker compose -f .devcontainer/docker-compose.yml up -d
```

## ✅ 検証結果

### マウント状態（全てbind）
```json
[
  {
    "Source": ".../data/opencode",
    "Destination": "/home/vscode/.opencode",
    "Type": "bind" ✅
  },
  {
    "Source": ".../data/opencode-storage",
    "Destination": "/home/vscode/.local/share/opencode",
    "Type": "bind" ✅
  },
  {
    "Source": ".../data/claude",
    "Destination": "/home/vscode/.claude",
    "Type": "bind" ✅
  }
]
```

### データ同期テスト
- ✅ コンテナ内でファイル作成 → ホスト側に即座に反映
- ✅ ホスト側でファイル作成 → コンテナ内で即座に確認可能
- ✅ データベースファイル（opencode.db）が正しく同期

### セッションデータの内容
- ✅ `opencode.db` (144KB) - セッション履歴、設定
- ✅ `auth.json` - 認証情報
- ✅ `storage/` - セッション差分、スナップショット
- ✅ `log/` - ログファイル
- ✅ `snapshot/` - スナップショットデータ

### ECCデータの内容
- ✅ `ecc/state.db` - ECCステータス、スキル実行履歴
- ✅ `homunculus/` - Homunculus データ

## 🎯 期待される動作

### リビルド前
1. OpenCodeでセッション作業
2. チャット履歴、エージェント実行結果が保存される
3. データは以下に保存：
   - エージェント設定: `.devcontainer/data/opencode/`
   - **セッション**: `.devcontainer/data/opencode-storage/`
   - **ECC DB**: `.devcontainer/data/claude/`

### リビルド後
1. ✅ エージェント設定が読み込まれる
2. ✅ **セッション履歴が保持される**（NEW！）
3. ✅ **チャット内容が継続**（NEW！）
4. ✅ **ECCステータスが維持される**（NEW！）
5. ✅ 作業の続きから再開可能

### バックアップ
- ホスト側でデータを直接確認・バックアップ可能
- `.devcontainer/data/` ディレクトリ全体をバックアップすれば完全保存
- Git管理対象外（.gitignore設定済み）

## 📂 ディレクトリ構造

```
.devcontainer/data/
├── opencode/              # エージェント設定
│   ├── agents/
│   ├── commands/
│   ├── AGENTS.md
│   └── ecc-install-state.json
├── opencode-storage/      # セッションデータ（NEW✅）
│   ├── opencode.db        # メインDB
│   ├── opencode.db-wal    # WALログ
│   ├── auth.json          # 認証
│   ├── storage/           # セッション差分
│   ├── snapshot/          # スナップショット
│   └── log/               # ログ
├── claude/                # ECCデータ（NEW✅）
│   ├── ecc/
│   │   └── state.db       # ECCステータス
│   └── homunculus/        # Homunculus
└── opencode-backup/       # バックアップ
```

## 🔐 .gitignore 設定

```gitignore
# DevContainer データ（個人セッション）
.devcontainer/data/opencode/*
!.devcontainer/data/opencode/.gitkeep
.devcontainer/data/opencode-storage/*
!.devcontainer/data/opencode-storage/.gitkeep
.devcontainer/data/claude/*
!.devcontainer/data/claude/.gitkeep
.devcontainer/data/opencode-backup/
```

## 📝 注意事項

### データベースファイル
- `opencode.db-wal` と `opencode.db-shm` は SQLite のWALモード用
- これらもホスト側に同期されるため、データの一貫性が保たれる
- コンテナ停止時に自動でマージされる

### 権限
- コンテナ内では `vscode:vscode` ユーザー
- ホスト側では作成したユーザー（例: `fjsn:fjsn`）
- バインドマウントなので、どちらからでも読み書き可能

### パフォーマンス
- バインドマウントは `:cached` オプション不要（設定も可能）
- データベースファイルのI/Oが多い場合は注意
- 現状のサイズ（~2MB）なら問題なし

## 🎉 まとめ

### 修正前の問題
❌ エージェント設定のみ保持（308KB）  
❌ セッション履歴が失われる  
❌ リビルドのたびに初期状態に戻る  

### 修正後の状態
✅ **全てのデータが永続化**（合計 ~2.2MB）  
✅ **セッション履歴が完全に保持**  
✅ **リビルド後も作業を継続可能**  
✅ **ホスト側でバックアップ可能**  
✅ **複数コンテナ間でデータ共有可能**（同じマウント先を使用）

---

**修正日**: 2026年4月7日  
**対象**: OpenCode + OpenChamber + ECC DevContainer  
**結果**: ✅ セッションデータ永続化の完全実装
