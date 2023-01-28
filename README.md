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
|  | `pr-head-sha` | Pull request head SHA | `string` | `${{ github.event.pull_request.head.sha }}` |

### hadolint-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/hadolint-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/hadolint-ci.yml
```

### maven-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/maven-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/maven-ci.yml
```

### nodejs-ci.yml

```shell
mkdir -p .github/workflows ; wget -O .github/workflows/nodejs-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/nodejs-ci.yml
```

| Required | Key | Description | Type | Default |
| --- | --- | --- | --- | --- |
|  | `directorys` | Target directorys (comma separated) | `string` | `.` |
|  | `disabled-jobs` | Disable Jobs (comma separated) | `string` | `NULL` |
|  | `install-apt-packages` | Install apt packages (space separated) | `string` |  |

## Dockerfile

### node-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/node-app.Dockerfile
```

### node-ncc-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/node-ncc-app.Dockerfile
```

### php-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/php-app.Dockerfile
```

### puppeteer.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/puppeteer.Dockerfile
```

### python-app.Dockerfile

```shell
wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/python-app.Dockerfile
```
