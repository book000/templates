# GitHub Copilot Instructions

## プロジェクト概要

- **目的**: GitHub Actions Reusable Workflows、Dockerfile テンプレート、Renovate 設定を一元管理し、複数プロジェクト間で再利用可能なテンプレートを提供する
- **主な機能**:
  - GitHub Actions Reusable Workflows の提供（Node.js、Maven、Docker、Actionlint、Hadolint など 7 種類）
  - Docker コンテナ化のための Dockerfile テンプレート（Node.js、Python、PHP、Puppeteer など 7 種類）
  - Renovate 設定ファイルのベーステンプレート
  - CI/CD パイプラインの標準化と自動テスト
- **対象ユーザー**: 開発者（複数プロジェクトで CI/CD とコンテナ化を統一したい開発チーム）

## 共通ルール

- 会話は日本語で行う。
- PR とコミットは Conventional Commits に従う。`<description>` は日本語で記載する。
  - 例: `feat: Reusable Workflow にテストステップを追加`
- 日本語と英数字の間には半角スペースを入れる。

## 技術スタック

- **言語**: YAML、Dockerfile、JavaScript (Node.js)、Shell
- **CI/CD**: GitHub Actions (Reusable Workflows)
- **コンテナ**: Docker (Alpine ベースイメージ)
- **パッケージマネージャー**: pnpm、yarn、Maven、pip
- **品質チェックツール**: actionlint、Hadolint
- **依存管理**: Renovate

## コーディング規約

- **フォーマット**: GitHub Actions YAML は 2 スペースインデント
- **Dockerfile**: Hadolint のベストプラクティスに従う
- **命名規則**:
  - Reusable Workflows: `reusable-*.yml`
  - Dockerfile テンプレート: `*-app.Dockerfile` または `*-pnpm.Dockerfile`
- **Lint/Format ルール**: actionlint、Hadolint の警告・エラーを解消する

## 開発コマンド

```bash
# README.md の自動生成
node scripts/generate-readme.js

# actionlint の実行（ワークフローの検証）
./actionlint

# Hadolint の実行（Dockerfile の検証）
docker run --rm -i hadolint/hadolint < dockerfiles/node-app-pnpm.Dockerfile

# テストシナリオの実行（GitHub Actions 上で自動実行）
# .github/workflows/test-reusable-workflows.yml を参照
```

## テスト方針

- **テストフレームワーク**: GitHub Actions ワークフロー（`.github/workflows/test-reusable-workflows.yml`）
- **テスト対象**: 全 Reusable Workflows と Dockerfile テンプレート
- **テスト追加の方針**:
  - 新しい Reusable Workflow を追加した場合は、`test-scenarios/` にテストシナリオを追加する
  - Dockerfile を追加した場合は、`dockerfiles/tests/` にテストアプリケーションを追加する

## セキュリティ / 機密情報

- GitHub Secrets や認証情報は `.env` ファイルやコミットに含めない。
- ログに個人情報や認証情報を出力しない。
- Reusable Workflow で使用する Secrets は、呼び出し側のリポジトリで管理する。

## ドキュメント更新

- 以下のドキュメントは変更時に更新が必要：
  - `README.md`: 自動生成されるため、手動編集せず `scripts/generate-readme.js` を実行する
  - `.github/templates.md`: README のテンプレート（手動編集）
  - `docs/`: 各種ドキュメント（手動編集）

## リポジトリ固有

- このリポジトリは **テンプレートの提供** が目的であり、実行可能なアプリケーションではない。
- Reusable Workflows は `workflows/` ディレクトリに配置し、`.github/workflows/reusable-*.yml` でラップして公開する。
- README.md は自動生成されるため、手動で編集してはならない。変更は `.github/templates.md` で行う。
- actionlint バイナリは Linux 64-bit ELF 形式であり、CI 環境で実行される。
- Renovate 設定は `renovate/` ディレクトリに配置し、`base.json`、`public.json`、`private.json` で分類する。
- Docker テンプレートは Alpine ベースイメージを使用し、タイムゾーンは `Asia/Tokyo` に設定する。
- `test-scenarios/` のテストシナリオは、GitHub Actions で定期的に実行され、テンプレートの品質を保証する。
