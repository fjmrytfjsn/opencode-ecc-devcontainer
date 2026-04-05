# projects ディレクトリ運用ガイド

このディレクトリは、OpenCode ECC DevContainer 基盤上で作業する
アプリ実装用リポジトリを配置するための場所です。

## 目的

- 基盤リポジトリとアプリ実装リポジトリを分離する
- DevContainer の共通環境を維持しながら、複数アプリを扱えるようにする
- 誤って基盤リポジトリにアプリ実装コードをコミットしないようにする

## 使い方

1. この配下にアプリのリポジトリを clone する
2. 実装・コミット・PR はアプリ側リポジトリで行う
3. この基盤リポジトリには、原則としてアプリ実装成果物を含めない

例:

```bash
git clone https://github.com/<your-account>/<your-app-repo>.git projects/<your-app-repo>
cd projects/<your-app-repo>
```

## Git 管理ルール

- `projects/` ディレクトリ自体は管理対象
- `projects/README.md` は管理対象
- `projects/` 配下のそれ以外は管理対象外

このルールにより、運用ガイドは共有しつつ、実装リポジトリの混入を防止できます。
