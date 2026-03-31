# 📋 プロジェクトテンプレート管理

このディレクトリには、対話式セットアップで使用する各種テンプレートが含まれています。

## 📁 構造

```
templates/
├── README.template.md          # プロジェクトREADME テンプレート
├── package.template.json       # package.json テンプレート
├── app.template.js            # メインアプリケーション テンプレート
├── env.template              # .env ファイル テンプレート
└── docker-compose.override.yml # カスタム docker-compose 設定
```

## 🔧 カスタマイズ方法

### 1. README テンプレート編集
`README.template.md` を編集して、生成されるプロジェクトREADME をカスタマイズ

### 2. パッケージ設定編集  
`package.template.json` でデフォルトの依存関係やスクリプトを定義

### 3. アプリケーションテンプレート編集
`app.template.js` でデフォルトのアプリケーション構造を定義

## 🎯 変数置換

テンプレート内で使用可能な変数：
- `{{PROJECT_NAME}}` - プロジェクト名
- `{{PROJECT_DESCRIPTION}}` - プロジェクト説明  
- `{{AUTHOR_NAME}}` - 作者名
- `{{REPO_URL}}` - リポジトリURL
- `{{TIMESTAMP}}` - タイムスタンプ
- `{{ECC_PROFILE}}` - ECC プロファイル

変数は対話式セットアップ時に自動置換されます。