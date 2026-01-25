# Gemini CLI 作業方針

## 目的

このドキュメントは、Gemini CLI がこのリポジトリで作業を行う際のコンテキストと作業方針を定義します。

## 出力スタイル

- **言語**: 日本語
- **トーン**: 専門的かつ簡潔
- **形式**: マークダウン形式で構造化された情報を提供

## 共通ルール

- 会話は日本語で行う。
- PR とコミットは Conventional Commits に従う。`<description>` は日本語で記載する。
  - 例: `feat: Reusable Workflow にテストステップを追加`
- 日本語と英数字の間には半角スペースを入れる。

## プロジェクト概要

**book000/templates** は、GitHub 上の複数プロジェクトで再利用可能なテンプレートリポジトリです。

- **目的**: GitHub Actions Reusable Workflows、Dockerfile テンプレート、Renovate 設定を一元管理し、複数プロジェクト間で再利用可能なテンプレートを提供する
- **主な機能**:
  - GitHub Actions Reusable Workflows の提供（Node.js、Maven、Docker、Actionlint、Hadolint など 7 種類）
  - Docker コンテナ化のための Dockerfile テンプレート（Node.js、Python、PHP、Puppeteer など 7 種類）
  - Renovate 設定ファイルのベーステンプレート
  - CI/CD パイプラインの標準化と自動テスト
  - README.md の自動生成

## コーディング規約

- **フォーマット**: GitHub Actions YAML は 2 スペースインデント
- **命名規則**:
  - Reusable Workflows: `reusable-*.yml`
  - Dockerfile テンプレート: `*-app.Dockerfile` または `*-pnpm.Dockerfile`
- **コメント言語**: 日本語
- **エラーメッセージ**: 英語

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

## 注意事項

- GitHub Secrets や認証情報は `.env` ファイルやコミットに含めない。
- ログに個人情報や認証情報を出力しない。
- Reusable Workflow で使用する Secrets は、呼び出し側のリポジトリで管理する。
- プロジェクトの既存のコーディング規約、フォーマットルールを優先する。
- 既知の制約:
  - このリポジトリは `package.json` を持たない（テンプレート提供が目的）
  - README.md は自動生成されるため、手動編集は禁止

## リポジトリ固有

- このリポジトリは **テンプレートの提供** が目的であり、実行可能なアプリケーションではない。
- Reusable Workflows は `workflows/` ディレクトリに配置し、`.github/workflows/reusable-*.yml` でラップして公開する。
- README.md は自動生成されるため、手動で編集してはならない。変更は `.github/templates.md` で行う。
- actionlint バイナリは Linux 64-bit ELF 形式であり、CI 環境で実行される。
- Renovate 設定は `renovate/` ディレクトリに配置し、`base.json`、`public.json`、`private.json` で分類する。
- Docker テンプレートは Alpine ベースイメージを使用し、タイムゾーンは `Asia/Tokyo` に設定する。
- `test-scenarios/` のテストシナリオは、GitHub Actions で定期的に実行され、テンプレートの品質を保証する。

## Gemini CLI の役割

Gemini CLI は、以下の観点で Claude Code をサポートします：

- **SaaS 仕様の確認**: GitHub Actions、Docker、Renovate などの最新仕様の調査
- **言語・ランタイムのバージョン差**: Node.js、Python、PHP などのバージョン差異の確認
- **料金・制限・クォータ**: GitHub Actions の制限、Docker Hub の制限などの確認
- **外部一次情報の確認**: 公式ドキュメント、リリースノートなどの最新情報の調査
- **外部前提条件の検証**: 依存パッケージのバージョン互換性、セキュリティパッチの確認
