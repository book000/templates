# AI エージェント共通作業方針

## 目的

このドキュメントは、一般的な AI エージェントがこのリポジトリで作業を行う際の共通方針を定義します。

## 基本方針

- **会話言語**: 日本語
- **コード内コメント**: 日本語
- **エラーメッセージ**: 英語
- **コミット規約**: Conventional Commits に従う
  - `<type>(<scope>): <description>` 形式
  - `<description>` は日本語で記載
  - 例: `feat: Reusable Workflow にテストステップを追加`
- **日本語と英数字の間**: 半角スペースを挿入

## 判断記録のルール

判断は必ずレビュー可能な形で記録すること：

1. **判断内容**: 何を決定したのかを明確に記載する
2. **代替案**: 他にどのような選択肢があったのかを列挙する
3. **採用理由**: なぜその選択肢を選んだのかを説明する
4. **前提条件**: 判断の前提となる条件を明示する
5. **不確実性**: 不確実な要素を明示する

前提・仮定・不確実性を明示し、仮定を事実のように扱わない。

## プロジェクト概要

**book000/templates** は、GitHub 上の複数プロジェクトで再利用可能なテンプレートリポジトリです。

- **目的**: GitHub Actions Reusable Workflows、Dockerfile テンプレート、Renovate 設定を一元管理
- **主な機能**:
  - GitHub Actions Reusable Workflows の提供（Node.js、Maven、Docker、Actionlint、Hadolint など 8 種類）
  - Docker コンテナ化のための Dockerfile テンプレート（Node.js、Python、PHP、Puppeteer など 8 種類）
  - Renovate 設定ファイルのベーステンプレート
  - CI/CD パイプラインの標準化と自動テスト

## 開発手順（概要）

1. **プロジェクト理解**: リポジトリの構造と目的を理解する
2. **依存関係インストール**: このリポジトリには `package.json` が存在しないため、該当しない
3. **変更実装**: Reusable Workflow、Dockerfile、Renovate 設定などを追加・変更する
4. **テストと Lint/Format 実行**:
   - actionlint の実行: `./actionlint`
   - Hadolint の実行: `docker run --rm -i hadolint/hadolint < dockerfiles/node-app-pnpm.Dockerfile`
   - README.md の生成: `node scripts/generate-readme.js`

## 技術スタック

- **言語**: YAML、Dockerfile、JavaScript (Node.js)、Shell
- **CI/CD**: GitHub Actions (Reusable Workflows)
- **コンテナ**: Docker (Alpine ベースイメージ)
- **パッケージマネージャー**: pnpm、yarn、Maven、pip
- **品質チェックツール**: actionlint、Hadolint
- **依存管理**: Renovate

## セキュリティ / 機密情報

- GitHub Secrets や認証情報は `.env` ファイルやコミットに含めない。
- ログに個人情報や認証情報を出力しない。
- Reusable Workflow で使用する Secrets は、呼び出し側のリポジトリで管理する。

## リポジトリ固有

- このリポジトリは **テンプレートの提供** が目的であり、実行可能なアプリケーションではない。
- Reusable Workflows は `workflows/` ディレクトリに配置し、`.github/workflows/reusable-*.yml` でラップして公開する。
- README.md は自動生成されるため、手動で編集してはならない。変更は `.github/templates.md` で行う。
- actionlint バイナリは Linux 64-bit ELF 形式であり、CI 環境で実行される。
- Renovate 設定は `renovate/` ディレクトリに配置し、`base.json`、`public.json`、`private.json` で分類する。
- Docker テンプレートは Alpine ベースイメージを使用し、タイムゾーンは `Asia/Tokyo` に設定する。
- `test-scenarios/` のテストシナリオは、GitHub Actions で定期的に実行され、テンプレートの品質を保証する。
