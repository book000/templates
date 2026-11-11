# AGENTS.md

AI コーディングエージェントとコントリビューター向けの指針です。`CLAUDE.md` はこのファイルを取り込み、`.github/copilot-instructions.md` はレビュー用のチェックリストを補います。

## Language

- 成果物はすべて **日本語** で書く。コミットメッセージの説明部分、PR・Issue のタイトルと本文、レビューコメント、コードコメント・docstring、ドキュメント（`README.md`、`AGENTS.md`、`test-scenarios/README.md` など）が対象。
- 日本語と英数字の間には半角スペースを入れる。段落の途中で手動改行しない。
- 例外（そのまま維持する）: 引用、技術的な識別子、生成ファイル、外部由来のテキスト。`.github/copilot-instructions.md` は Copilot に渡す指示のため英語で書く（日本語の要約を含める）。`docs/` は rhysd/actionlint のドキュメントをそのまま同梱したもの（英語）で、翻訳しない。
- ランタイムメッセージ（ログ、エラー）は英語にする。既存の日本語メッセージは、利用側リポジトリへの影響を確認せずに変更しない。
- 過去のコミットの言語を変えるために Git 履歴を書き換えない。

## 概要

複数のリポジトリで使い回すテンプレートの提供元です。実行アプリケーションではなく、`package.json` もありません。他のリポジトリが `wget` でコピーするか、`uses: book000/templates/.github/workflows/reusable-*.yml@master` で参照するため、変更は下流に直接影響します。

- `workflows/`: 利用側にコピーさせるワークフロー（`old/` は旧版）。実処理は `.github/workflows/reusable-*.yml` を呼び出す
- `.github/workflows/reusable-*.yml`: Reusable Workflow 本体
- `.github/workflows/` の `reusable-*.yml` 以外: このリポジトリ自身の CI（lint、テスト、README 生成、Renovate 設定の検証など）
- `dockerfiles/*.Dockerfile`: Dockerfile テンプレート。`dockerfiles/tests/<名前>/` が動作確認用のアプリ
- `renovate/`: Renovate の共有設定（`base*.json` が共通部分、`public.json` と `private.json` が利用側にコピーするもの）。ルートの `renovate.json` はこのリポジトリ自身の設定
- `test-scenarios/`: Reusable Workflow のテスト用プロジェクト（詳細は `test-scenarios/README.md`）
- `scripts/generate-readme.js`: `README.md` の生成スクリプト
- `actionlint`: チェックイン済みの actionlint バイナリ（Linux 64-bit ELF）。CI は最新版をダウンロードして使い、このバイナリは使わない
- `docs/`: rhysd/actionlint のドキュメントの同梱コピー。このリポジトリ固有の内容ではない

## コマンド

```bash
# README.md の再生成（.github/templates.md と workflows/ から生成。js-yaml が必要）
npm install --no-save js-yaml   # 初回のみ（CI は yarn add js-yaml）。ロックファイルを残さない
node scripts/generate-readme.js

# ワークフローの検証（CI と同じ除外指定）
./actionlint -color -shellcheck= \
  -ignore='unexpected.*key.*background' \
  -ignore='step.*must.*run.*script.*with.*run.*section.*or.*run.*action.*with.*uses.*section'

# Dockerfile の検証
docker build --check -f dockerfiles/node-app-pnpm.Dockerfile .
docker run --rm -i hadolint/hadolint < dockerfiles/node-app-pnpm.Dockerfile
```

- `-ignore` は `actionlint.yml`（このリポジトリ自身の `reusable-*.yml` の検査）と同じ指定で、GitHub Actions の `background` / `wait-all` に actionlint が未対応なための既知の誤検知を除く。新しい actionlint が対応したら不要になる。
- `workflows/` の検査（`actionlint-templates.yml`）は、`.github/workflows/*` を `workflows/*` で置き換えたうえで、`-ignore` なしで実行する。ローカルでは別の一時リポジトリで行う。
- Reusable Workflow と Dockerfile の結合テストは、GitHub Actions 上の `test-reusable-workflows.yml`、`dockerfile-test.yml` が担う。

## 開発方針

- `README.md` は生成物なので手で編集しない。`.github/templates.md` を編集し、`node scripts/generate-readme.js` で再生成する（push 時は `generate-readme.yml` が自動コミットする）。入力の説明は Reusable Workflow の `inputs.<名前>.description` から生成される。
- Reusable Workflow の `inputs`、`secrets`、`outputs`、ジョブ名、ファイルパスを、後方互換性を確認せずに削除・改名・必須化しない。デフォルト値の変更も挙動を変えないか確認する。
- 利用側がマッチする文字列（`workflows/*.yml` の承認依頼コメントの `body-includes: Environment 承認待ち` など）を変更しない。変更するときは `workflows/` 内の本文と検索条件を必ず揃える。
- `allow-unsafe-pr-checkout` のように信頼境界に関わる入力は、既定で安全側（`false`）にする。fork PR のコードを特権コンテキストで実行しない。
- `book000/templates` 自身への参照は、Renovate の設定（`pinDigests: false`）に従いタグ・ブランチで参照する。
- 新しい Reusable Workflow を追加したら、`workflows/` にラッパー、`test-scenarios/` にテスト、`test-reusable-workflows.yml` にテストジョブ（`test-summary` の `needs` と判定も）を追加する。
- Dockerfile テンプレートは Alpine ベースで、タイムゾーンを `Asia/Tokyo` に設定する。追加したら `dockerfiles/tests/<ファイル名から拡張子を除いた名前>/` に動作確認用アプリを置く。
- GitHub Actions の YAML は 2 スペースインデント。サードパーティ Action は既存の書き方に合わせてコミット SHA で固定する。
- Secrets は呼び出し側のリポジトリで管理する。ログに認証情報を出力しない。

## 規約

- コミットは [Conventional Commits](https://www.conventionalcommits.org/)、ブランチは [Conventional Branch](https://conventional-branch.github.io) の短縮形（`feat/...`、`fix/...`）に従う。
- Renovate が作成した PR にコミットしない。
- 調査でリポジトリを確認するときは、一時ディレクトリへ clone する。
