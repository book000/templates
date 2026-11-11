# book000/templates

Templates shared across multiple repositories. Copy the files from this repository with `wget`.

- GitHub Actions workflows: copy the files under `workflows/`. The real work lives in the reusable workflows (`.github/workflows/reusable-*.yml`), which the copied workflow calls with `uses: book000/templates/.github/workflows/reusable-*.yml@master`.
- Dockerfile: copy a file under `dockerfiles/` as `Dockerfile`.
- Renovate: copy a configuration under `renovate/` as `renovate.json`.

In each workflow table, an input marked with `✔` in the `Required` column is required.

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

