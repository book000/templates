# Reusable Workflow のテストシナリオ

このディレクトリは、このリポジトリの Reusable Workflow が正しく動作することを検証するためのテストシナリオです。

## 構成

- `nodejs-yarn/`: `reusable-nodejs-ci.yml` 用のテストプロジェクト
- `nodejs-pnpm/`: `reusable-nodejs-ci-pnpm.yml` 用のテストプロジェクト
- `nodejs-pnpm-ignored-build-scripts/`: pnpm の Ignored build scripts 検出が機能することを確かめる負のテスト用プロジェクト
- `maven/`: `reusable-maven.yml` 用のテストプロジェクト
- `docker/`: `reusable-docker.yml` と `reusable-hadolint-ci.yml` 用のテストファイル（`docker/test.sh` は `reusable-shellcheck-ci.yml` の対象にもなる）
- `python/`: `reusable-python-ci.yml` 用のテストプロジェクト
- `bicep/`: `reusable-bicep-ci.yml` 用のテストファイル
- `workflows/`: actionlint 用のサンプルワークフロー（テストワークフローからは参照されない。`reusable-actionlint.yml` はリポジトリ自身の `.github/workflows/` を検査する）

## 目的

- 依存（`actions/setup-node` など）の更新による破壊的変更を、利用側のリポジトリに影響する前に検出する
- Reusable Workflow の構文が正しいことを確認する
- 単純で正しい入力を各ワークフローが処理できることを確認する
- 変更による退行を防ぐ

## テストの実行方法

テストは `.github/workflows/test-reusable-workflows.yml` が実行します。各 Reusable Workflow を `test-scenarios/` 配下のテスト用入力で呼び出し、公開やデプロイといった副作用が出ないよう `is-merged: false`、`is-release: false` などを指定します。テストに支障が出るステップ（`depcheck` など）は `disabled-jobs` でスキップします。

## メンテナンス

Reusable Workflow を追加・変更するときは、次のとおり更新します。

1. 入力を追加した場合は、テストシナリオを更新する
2. 新しい種類のワークフローを追加した場合は、テスト用ディレクトリを追加する
3. テストプロジェクトは最小限で動作する状態を保つ
4. `test-reusable-workflows.yml` に新しいワークフローのテストを追加し、`test-summary` ジョブの `needs` にも加える
