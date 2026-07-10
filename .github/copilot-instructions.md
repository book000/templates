# GitHub Copilot レビュー方針

このファイルは GitHub Copilot のコードレビュー機能向けの指示です。開発作業全体の方針は `CLAUDE.md` を参照してください。ここではレビュー時に重点的に確認すべき点のみを記載します。

## このリポジトリの性質

- **book000/templates は再利用可能な GitHub Actions Reusable Workflow / Dockerfile / Renovate 設定の提供元**であり、実行アプリケーションではない。
- ここで公開される Reusable Workflow は `book000/templates/.github/workflows/reusable-*.yml` として **他の多数のリポジトリから参照される**。破壊的変更（`inputs` / `secrets` の削除・必須化・意味変更、ジョブ名やアウトプットの変更）は下流のリポジトリの CI を壊すため、後方互換性の観点を最優先でレビューする。

## レビューの重点

- **後方互換性**: `workflows/` および `.github/workflows/reusable-*.yml` の変更で、既存 `inputs`/`secrets`/`outputs` が削除・リネーム・必須化されていないか。デフォルト値の変更が挙動を変えないか。
- **セキュリティ**:
  - `secrets` を `echo` や `run` で標準出力・ログに出していないか（マスクされない箇所での漏洩）。
  - `allow-unsafe-pr-checkout` のような信頼境界に関わる入力を、デフォルトで安全側（無効）にしているか。fork PR のコードを特権コンテキストでチェックアウト・実行していないか。
  - `pull_request_target` 使用時に、信頼できない PR のコードを実行していないか。
  - サードパーティ Action は原則タグではなくコミット SHA で固定する意図か（ただしこのリポジトリ自身の参照は Renovate 運用に従う。過去に digest 固定を意図的に無効化した経緯があるため、`book000/templates` 自身への参照の固定方式変更は慎重に確認する）。
- **Dockerfile**: Hadolint のベストプラクティスに従っているか（バージョン固定、`--no-cache`、レイヤー最適化）。Alpine ベース・マルチステージ・`Asia/Tokyo` タイムゾーンという既存方針から逸脱していないか。
- **エラーハンドリング**: シェルステップで `set -euo pipefail` 相当の失敗検知があるか。パイプの失敗が握りつぶされていないか。
- **YAML**: GitHub Actions YAML は 2 スペースインデント。actionlint で検出される式の誤りや権限（`permissions`）の過剰付与がないか。

## Copilot が誤検知しやすい・フラグすべきでないパターン

- `README.md` は `scripts/generate-readme.js` により **自動生成される**。README への直接編集は誤りだが、逆に「README を手で更新せよ」という指摘は不要。README の変更は `.github/templates.md` の編集と再生成で行う。
- `actionlint`（リポジトリ直下）は **チェックイン済みの Linux 64-bit ELF バイナリ**であり、テキストソースではない。「巨大ファイル」「バイナリをコミットするな」という指摘は不要。
- このリポジトリには `package.json` が存在しない。「`npm install` / `npm test` を追加せよ」といった Node.js プロジェクト前提の指摘は不要。
- `workflows/` にソースを置き `.github/workflows/reusable-*.yml` でラップする二層構成は意図的な設計。重複に見えても指摘不要。

## コメント言語

- レビューコメントは日本語で行う。コミット・PR は Conventional Commits に従い、`<description>` は日本語。
