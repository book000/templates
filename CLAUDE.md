# Claude Code 作業方針

## 目的

このドキュメントは、Claude Code がこのリポジトリで作業を行う際の方針とルールを定義します。

## 判断記録のルール

判断は必ずレビュー可能な形で記録すること：

1. **判断内容の要約**: 何を決定したのかを明確に記載する
2. **検討した代替案**: 他にどのような選択肢があったのかを列挙する
3. **採用しなかった案とその理由**: なぜその代替案を採用しなかったのかを説明する
4. **前提条件・仮定・不確実性**: 判断の前提となる条件や仮定、不確実な要素を明示する
5. **他エージェントによるレビュー可否**: Codex CLI や Gemini CLI によるレビューが必要かどうかを示す

前提・仮定・不確実性を明示し、仮定を事実のように扱わない。

## プロジェクト概要

**book000/templates** は、GitHub 上の複数プロジェクトで再利用可能なテンプレートリポジトリです。

- **目的**: GitHub Actions Reusable Workflows、Dockerfile テンプレート、Renovate 設定を一元管理し、複数プロジェクト間で再利用可能なテンプレートを提供する
- **主な機能**:
  - GitHub Actions Reusable Workflows の提供（Node.js、Maven、Docker、Actionlint、Hadolint など 7 種類）
  - Docker コンテナ化のための Dockerfile テンプレート（Node.js、Python、PHP、Puppeteer など 7 種類）
  - Renovate 設定ファイルのベーステンプレート
  - CI/CD パイプラインの標準化と自動テスト
  - README.md の自動生成

## 重要ルール

- **会話言語**: 日本語
- **コミット規約**: Conventional Commits に従う（`<description>` は日本語）
  - 例: `feat: Reusable Workflow にテストステップを追加`
- **コード内コメント**: 日本語
- **エラーメッセージ**: 英語
- **日本語と英数字の間**: 半角スペースを挿入

## 環境のルール

- **ブランチ命名**: Conventional Branch に従う（`<type>/<description>`）
  - `<type>` は短縮形（feat, fix）を使用
  - 例: `feat/add-docker-template`
- **GitHub リポジトリ調査方法**: テンポラリディレクトリに git clone してコード検索
- **Renovate PR の扱い**: Renovate が作成した既存の PR に対して、追加コミットや更新を行ってはならない

## Git Worktree

このプロジェクトでは Git Worktree を使用していません。通常の Git ブランチ管理を行います。

## コード改修時のルール

- **エラーメッセージの絵文字統一**: 既存のエラーメッセージに絵文字がある場合は、全体で統一する
- **TypeScript の `skipLibCheck` 禁止**: このリポジトリは TypeScript プロジェクトではないため、該当しない
- **docstring 記載**: 関数やインターフェースには docstring（JSDoc など）を日本語で記載・更新する

## 相談ルール

Codex CLI や Gemini CLI の他エージェントに相談することができます。以下の観点で使い分けてください：

### Codex CLI (ask-codex)

- 実装コードに対するソースコードレビュー
- 関数設計、モジュール内部の実装方針などの局所的な技術判断
- アーキテクチャ、モジュール間契約、パフォーマンス / セキュリティといった全体影響の判断
- 実装の正当性確認、機械的ミスの検出、既存コードとの整合性確認

### Gemini CLI (ask-gemini)

- SaaS 仕様、言語・ランタイムのバージョン差、料金・制限・クォータといった、最新の適切な情報が必要な外部依存の判断
- 外部一次情報の確認、最新仕様の調査、外部前提条件の検証

### 他エージェントが指摘・異議を提示した場合

Claude Code は必ず以下のいずれかを行う。黙殺・無言での不採用は禁止する。

- 指摘を受け入れ、判断を修正する
- 指摘を退け、その理由を明示する

### 必ず実施すること

- 他エージェントの提案を鵜呑みにせず、その根拠や理由を理解する
- 自身の分析結果と他エージェントの意見が異なる場合は、双方の視点を比較検討する
- 最終的な判断は、両者の意見を総合的に評価した上で、自身で下す

## 開発コマンド

このリポジトリには `package.json` が存在しないため、npm スクリプトはありません。以下のコマンドを使用します：

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

## アーキテクチャと主要ファイル

### アーキテクチャサマリー

このリポジトリは、**Reusable Workflows を中心とした分散型 CI/CD テンプレートシステム** として設計されています。

- **Reusable Workflows**: GitHub Actions の `workflow_call` トリガーを使用し、他のリポジトリから直接参照可能
- **Dockerfile テンプレート**: Alpine ベースイメージを使用し、マルチステージビルドとキャッシュ最適化を実装
- **Renovate 設定**: ベース設定を提供し、公開/プライベートリポジトリで設定を分離
- **自動テスト**: 全テンプレートの統合テストで品質保証

### 主要ディレクトリ

```
.github/workflows/      # Reusable workflow 定義（14 ファイル）
workflows/              # Reusable workflow の source（7 ファイル）
dockerfiles/            # Docker テンプレート（7 ファイル）
renovate/               # Renovate 設定ファイル
test-scenarios/         # テストシナリオ
scripts/                # ユーティリティスクリプト
docs/                   # ドキュメント
man/                    # man ページ（actionlint）
```

### 主要ファイル

- `README.md`: 自動生成されるメインドキュメント（手動編集禁止）
- `.github/templates.md`: README のテンプレート（手動編集）
- `scripts/generate-readme.js`: README 自動生成スクリプト
- `actionlint`: actionlint バイナリ（Linux 64-bit ELF）
- `renovate.json`: このリポジトリ自身の Renovate 設定

## 実装パターン

### 推奨パターン

- **Reusable Workflow の作成**:
  - `workflows/` ディレクトリに配置
  - `.github/workflows/reusable-*.yml` でラップして公開
  - `inputs` セクションで入力パラメータを定義
  - `secrets` セクションで必要な Secrets を定義
- **Dockerfile の作成**:
  - Alpine ベースイメージを使用
  - マルチステージビルドでサイズを最適化
  - キャッシュマウント（`RUN --mount=type=cache`）を活用
  - タイムゾーンは `Asia/Tokyo` に設定
- **README.md の更新**:
  - `.github/templates.md` を編集
  - `node scripts/generate-readme.js` を実行

### 非推奨パターン

- README.md を手動で編集する（自動生成されるため）
- Reusable Workflow を `.github/workflows/` に直接配置する（`workflows/` に配置すべき）
- Renovate が作成した PR に追加コミットを行う

## テスト

### テスト方針

- **テストフレームワーク**: GitHub Actions ワークフロー（`.github/workflows/test-reusable-workflows.yml`）
- **テスト対象**: 全 Reusable Workflows と Dockerfile テンプレート
- **テスト実行**: GitHub Actions で定期的に自動実行

### 追加テスト条件

- 新しい Reusable Workflow を追加した場合は、`test-scenarios/` にテストシナリオを追加する
- Dockerfile を追加した場合は、`dockerfiles/tests/` にテストアプリケーションを追加する
- actionlint と Hadolint のチェックを必ず通過させる

## ドキュメント更新ルール

### 更新対象

- `README.md`: 自動生成されるため、手動編集せず `scripts/generate-readme.js` を実行する
- `.github/templates.md`: README のテンプレート（手動編集）
- `docs/`: 各種ドキュメント（手動編集）

### 更新タイミング

- Reusable Workflow を追加・変更した場合
- Dockerfile テンプレートを追加・変更した場合
- Renovate 設定を変更した場合

## 作業チェックリスト

### 新規改修時

1. プロジェクトを詳細に探索し理解すること
2. 作業を行うブランチが適切であること。すでに PR を提出しクローズされたブランチでないこと
3. 最新のリモートブランチに基づいた新規ブランチであること
4. PR がクローズされ、不要となったブランチは削除されていること
5. プロジェクトで指定されたパッケージマネージャにより、依存パッケージをインストールしたこと（このリポジトリには該当しない）

### コミット・プッシュ前

1. コミットメッセージが Conventional Commits に従っていること。`<description>` は日本語で記載すること
2. コミット内容にセンシティブな情報が含まれていないこと
3. Lint / Format エラーが発生しないこと（actionlint、Hadolint）
4. 動作確認を行い、期待通り動作すること

### プルリクエスト作成前

1. プルリクエストの作成をユーザーから依頼されていること
2. コミット内容にセンシティブな情報が含まれていないこと
3. コンフリクトする恐れが無いこと

### プルリクエスト作成後

1. コンフリクトが発生していないこと
2. PR 本文の内容は、ブランチの現在の状態を、今までのこの PR での更新履歴を含むことなく、最新の状態のみ、漏れなく日本語で記載されていること
3. `gh pr checks <PR ID> --watch` で GitHub Actions CI を待ち、その結果がエラーとなっていないこと
4. GitHub Copilot レビューに対応し、コメントに返信すること（該当する場合）
5. `/code-review:code-review` によるコードレビューを実施し、スコアが 50 以上の指摘事項に対して対応すること
6. PR 本文の崩れがないことを確認すること

## リポジトリ固有

- このリポジトリは **テンプレートの提供** が目的であり、実行可能なアプリケーションではない。
- Reusable Workflows は `workflows/` ディレクトリに配置し、`.github/workflows/reusable-*.yml` でラップして公開する。
- README.md は自動生成されるため、手動で編集してはならない。変更は `.github/templates.md` で行う。
- actionlint バイナリは Linux 64-bit ELF 形式であり、CI 環境で実行される。
- Renovate 設定は `renovate/` ディレクトリに配置し、`base.json`、`public.json`、`private.json` で分類する。
- Docker テンプレートは Alpine ベースイメージを使用し、タイムゾーンは `Asia/Tokyo` に設定する。
- `test-scenarios/` のテストシナリオは、GitHub Actions で定期的に実行され、テンプレートの品質を保証する。
