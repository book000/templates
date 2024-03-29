# book000/templates

## GitHub Action workflows

### actionlint.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/actionlint.yml https://raw.githubusercontent.com/book000/templates/master/workflows/actionlint.yml
```

### add-reviewer.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/add-reviewer.yml https://raw.githubusercontent.com/book000/templates/master/workflows/add-reviewer.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `actors` | Target actors (comma separated) | `string` | `dependabot[bot],renovate[bot],github-actions[bot],book000` |
|  | `reviewers` | Reviewers (comma separated) | `string` | `book000` |

### docker.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/docker.yml https://raw.githubusercontent.com/book000/templates/master/workflows/docker.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `registry` | Docker registry | `string` | `ghcr.io` |
|  | `platforms` | Docker platforms | `string` | `linux/amd64,linux/arm64` |
| ✔ | `targets` | Docker targets | `string` |  |
|  | `is-merged` | Is merged | `boolean` | `${{ github.event.pull_request.merged == true }}` |
|  | `is-release` | Whether to release | `boolean` | `true` |
|  | `pr-head-sha` | Pull request head SHA | `string` | `${{ github.event.pull_request.head.sha }}` |
|  | `version` | Next custom version (Not included prefix) | `string` |  |

### hadolint-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/hadolint-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/hadolint-ci.yml
```

### maven-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/maven-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/maven-ci.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `java-version` | Java version | `string` | `17` |
|  | `jdk-distribution` | JDK distribution | `string` | `adopt` |
|  | `is-merged` | Is merged | `boolean` | `${{ github.event.pull_request.merged == true }}` |
|  | `is-release` | Whether to release | `boolean` | `true` |
|  | `pr-head-sha` | Pull request head SHA | `string` | `${{ github.event.pull_request.head.sha }}` |
|  | `version` | Next custom version (Not included prefix) | `string` |  |

### nodejs-ci-pnpm.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/nodejs-ci-pnpm.yml https://raw.githubusercontent.com/book000/templates/master/workflows/nodejs-ci-pnpm.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `directorys` | Target directorys (comma separated) | `string` | `.` |
|  | `disabled-jobs` | Disable Jobs (comma separated) | `string` | `NULL` |
|  | `install-apt-packages` | Install apt packages (space separated) | `string` |  |
|  | `lock-path` | Lock file path | `string` | `{dir}/pnpm-lock.yaml` |
|  | `check-git-diff` | Check git diff | `boolean` |  |

### nodejs-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/nodejs-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/nodejs-ci.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `directorys` | Target directorys (comma separated) | `string` | `.` |
|  | `disabled-jobs` | Disable Jobs (comma separated) | `string` | `NULL` |
|  | `install-apt-packages` | Install apt packages (space separated) | `string` |  |
|  | `lock-path` | yarn.lock path | `string` | `{dir}/yarn.lock` |
|  | `check-git-diff` | Check git diff | `boolean` |  |

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

