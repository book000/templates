# book000/templates

複数のリポジトリで使い回すテンプレートを管理するリポジトリです。このリポジトリのファイルは `wget` で各リポジトリへコピーして使います。

- GitHub Actions ワークフロー: `workflows/` のファイルをコピーして使う。実処理は Reusable Workflow（`.github/workflows/reusable-*.yml`）に置き、コピーしたワークフローから `uses: book000/templates/.github/workflows/reusable-*.yml@master` で呼び出す
- Dockerfile: `dockerfiles/` のファイルを `Dockerfile` としてコピーして使う
- Renovate: `renovate/` の設定を `renovate.json` としてコピーして使う

各ワークフローの表で、「必須」列に `✔` が付いた入力は必須です。

## GitHub Action workflows

### actionlint.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/actionlint.yml https://raw.githubusercontent.com/book000/templates/master/workflows/actionlint.yml
```

### add-reviewer.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/add-reviewer.yml https://raw.githubusercontent.com/book000/templates/master/workflows/add-reviewer.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `actors` | 対象のアクター（カンマ区切り） | `string` | `dependabot[bot],renovate[bot],github-actions[bot],book000` |
|  | `reviewers` | レビュアー（カンマ区切り） | `string` | `book000` |
|  | `light-runs-on` | 軽量ジョブのランナーラベル（ubuntu-slim、ubuntu-latest など） | `string` | `ubuntu-slim` |

### bicep-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/bicep-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/bicep-ci.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `bicep-file` | Bicep ファイルのパス | `string` | `infra/main.bicep` |
|  | `bicepparam-file` | Bicep パラメータファイルのパス | `string` | `infra/main.bicepparam` |

### docker.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/docker.yml https://raw.githubusercontent.com/book000/templates/master/workflows/docker.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `registry` | Docker レジストリ | `string` | `ghcr.io` |
|  | `platforms` | Docker プラットフォーム | `string` | `linux/amd64,linux/arm64` |
| ✔ | `targets` | Docker ビルド対象 | `string` |  |
|  | `is-merged` | マージ済みかどうか | `boolean` | `${{ github.event.pull_request.merged == true }}` |
|  | `is-release` | リリースするかどうか | `boolean` | `true` |
|  | `pr-head-sha` | プルリクエストの head SHA | `string` | `${{ github.event.pull_request.head.sha }}` |
|  | `version` | 次のバージョンを明示する場合の値（プレフィックスを含めない） | `string` | `` |
|  | `allow-unsafe-pr-checkout` | pull_request_target で起動されたワークフローから、フォーク PR の head SHA をチェックアウトすることを許可する。actions/checkout 既定の pwn-request 対策を無効にするため、呼び出し側ワークフローで手動レビュー（Environment 承認など）を必須にした後でのみ true にすること。 | `boolean` | `false` |
|  | `light-runs-on` | 軽量ジョブのランナーラベル（ubuntu-slim、ubuntu-latest など） | `string` | `ubuntu-slim` |

### hadolint-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/hadolint-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/hadolint-ci.yml
```

### maven-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/maven-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/maven-ci.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `java-version` | Java のバージョン | `string` | `17` |
|  | `jdk-distribution` | JDK のディストリビューション | `string` | `adopt` |
|  | `is-merged` | マージ済みかどうか | `boolean` | `${{ github.event.pull_request.merged == true }}` |
|  | `is-release` | リリースするかどうか | `boolean` | `true` |
|  | `pr-head-sha` | プルリクエストの head SHA | `string` | `${{ github.event.pull_request.head.sha }}` |
|  | `version` | 次のバージョンを明示する場合の値（プレフィックスを含めない） | `string` | `` |
|  | `directory` | pom.xml があるワーキングディレクトリ | `string` | `.` |
|  | `allow-unsafe-pr-checkout` | pull_request_target で起動されたワークフローから、フォーク PR の head SHA をチェックアウトすることを許可する。actions/checkout 既定の pwn-request 対策を無効にするため、呼び出し側ワークフローで手動レビュー（Environment 承認など）を必須にした後でのみ true にすること。 | `boolean` | `false` |

### nodejs-ci-pnpm.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/nodejs-ci-pnpm.yml https://raw.githubusercontent.com/book000/templates/master/workflows/nodejs-ci-pnpm.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `directorys` | 対象ディレクトリ（カンマ区切り） | `string` | `.` |
|  | `disabled-jobs` | 無効化するジョブ（カンマ区切り） | `string` | `NULL` |
|  | `install-apt-packages` | インストールする apt パッケージ（スペース区切り） | `string` | `` |
|  | `lock-path` | ロックファイルのパス | `string` | `{dir}/pnpm-lock.yaml` |
|  | `check-git-diff` | git diff を確認するかどうか | `boolean` | `false` |
|  | `allow-unsafe-pr-checkout` | pull_request_target で起動されたワークフローから、フォーク PR の head SHA をチェックアウトすることを許可する。actions/checkout 既定の pwn-request 対策を無効にするため、呼び出し側ワークフローで手動レビュー（Environment 承認など）を必須にした後でのみ true にすること。 | `boolean` | `false` |
|  | `light-runs-on` | 軽量ジョブのランナーラベル（ubuntu-slim、ubuntu-latest など） | `string` | `ubuntu-slim` |

### nodejs-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/nodejs-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/nodejs-ci.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `directorys` | 対象ディレクトリ（カンマ区切り） | `string` | `.` |
|  | `disabled-jobs` | 無効化するジョブ（カンマ区切り） | `string` | `NULL` |
|  | `install-apt-packages` | インストールする apt パッケージ（スペース区切り） | `string` | `` |
|  | `lock-path` | yarn.lock のパス | `string` | `{dir}/yarn.lock` |
|  | `check-git-diff` | git diff を確認するかどうか | `boolean` | `false` |
|  | `allow-unsafe-pr-checkout` | pull_request_target で起動されたワークフローから、フォーク PR の head SHA をチェックアウトすることを許可する。actions/checkout 既定の pwn-request 対策を無効にするため、呼び出し側ワークフローで手動レビュー（Environment 承認など）を必須にした後でのみ true にすること。 | `boolean` | `false` |

### python-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/python-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/python-ci.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `directory` | 対象ディレクトリ | `string` | `.` |
|  | `python-version` | Python のバージョン。空の場合は {directory}/.python-version があればそれを、なければ 3.x を使う | `string` | `` |
|  | `requirements-file` | 対象ディレクトリからの requirements ファイルの相対パス（存在しない場合はスキップ） | `string` | `requirements.txt` |
|  | `disabled-jobs` | 無効化するジョブ（カンマ区切り。compile, ruff, format, test） | `string` | `NULL` |
|  | `install-apt-packages` | インストールする apt パッケージ（スペース区切り） | `string` | `` |

### shellcheck-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/shellcheck-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/shellcheck-ci.yml
```

| 必須 | キー | 説明 | 型 | デフォルト |
| --- | --- | --- | --- | --- |
|  | `directory` | 対象ディレクトリ（git 管理下のファイルのみ） | `string` | `.` |
|  | `severity` | 報告する指摘の最小重大度（error, warning, info, style） | `string` | `warning` |

## Dockerfile

### node-app-pnpm.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/node-app-pnpm.Dockerfile
```

### node-app-yarn.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/node-app-yarn.Dockerfile
```

### node-ncc-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/node-ncc-app.Dockerfile
```

### php-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/php-app.Dockerfile
```

### puppeteer-pnpm.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/puppeteer-pnpm.Dockerfile
```

### puppeteer-virtual-display-pnpm.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/puppeteer-virtual-display-pnpm.Dockerfile
```

### python-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/python-app.Dockerfile
```

## renovate

### Public repo

```shell
wget -O renovate.json https://raw.githubusercontent.com/book000/templates/master/renovate/public.json
```

### Private repo

```shell
wget -O renovate.json https://raw.githubusercontent.com/book000/templates/master/renovate/private.json
```

