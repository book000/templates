# book000/templates

複数のリポジトリで使い回すテンプレートを管理するリポジトリです。このリポジトリのファイルは `wget` で各リポジトリへコピーして使います。

- GitHub Actions ワークフロー: `workflows/` のファイルをコピーして使う。実処理は Reusable Workflow（`.github/workflows/reusable-*.yml`）に置き、コピーしたワークフローから `uses: book000/templates/.github/workflows/reusable-*.yml@master` で呼び出す
- Dockerfile: `dockerfiles/` のファイルを `Dockerfile` としてコピーして使う
- Renovate: `renovate/` の設定を `renovate.json` としてコピーして使う

各ワークフローの表で、「必須」列に `✔` が付いた入力は必須です。

## GitHub Action workflows

<!-- gw-templates -->

## Dockerfile

<!-- dockerfiles -->

## renovate

### Public repo

```shell
wget -O renovate.json https://raw.githubusercontent.com/book000/templates/master/renovate/public.json
```

### Private repo

```shell
wget -O renovate.json https://raw.githubusercontent.com/book000/templates/master/renovate/private.json
```

