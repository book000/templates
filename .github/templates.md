# book000/templates

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

## Node.js プロジェクトテンプレート

対話式セットアップスクリプトで Node.js プロジェクトを初期構築します。

```powershell
irm https://raw.githubusercontent.com/book000/templates/master/nodejs/setup.ps1 | iex
```

### バリアント

| バリアント | 説明 | 追加依存 |
| --- | --- | --- |
| `base` | 最小構成 | なし |
| `config-batch` | 設定ファイルありのバッチ処理 | `typescript-json-schema` |
| `fastify` | Fastify HTTP サーバー | `fastify`, `@fastify/cors`, `fastify-raw-body` |
| `discord-bot` | Discord Bot | `discord.js`, `typescript-json-schema` |

### セットアップ内容

- `tsconfig.json`（`moduleResolution: bundler`、ESM / CommonJS を対話選択）
- `.prettierrc.yml` / `eslint.config.mjs`（`@book000/eslint-config`）
- `renovate.json`（`base-public` 継承）
- `pnpm-workspace.yaml`（`allowBuilds: esbuild, unrs-resolver`）
- `.devcontainer/devcontainer.json`（`typescript-node:24`）
- `package.json`（プロジェクト情報・依存を pnpm でインストール）
- `.gitignore` / `.node-version` / `LICENSE`
- `.github/workflows/nodejs-ci-pnpm.yml`（必須）
- `.github/workflows/docker.yml`（Dockerfile 選択時）
- `.github/workflows/add-reviewer.yml`（add-reviewer 選択時）

