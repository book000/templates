# AGENTS.md

Guidance for AI coding agents and contributors. `CLAUDE.md` imports this file, and `.github/copilot-instructions.md` adds the review checklist.

## Language

- All deliverables are written in **English**: commit messages, PR/Issue titles and bodies, review comments, code comments and docstrings, and documentation (`README.md`, `AGENTS.md`, `test-scenarios/README.md`, etc.).
- Exceptions (keep as is): quotations, technical identifiers, generated files, external text, and strings that other repositories match on. The fork-PR approval comment in `workflows/*.yml` (`body-includes: Environment 承認待ち`) must stay Japanese: it matches the `## Environment 承認待ち` heading of the bot comment, so change the search condition and the heading together, and only after checking downstream repositories. The rest of that comment body is legacy Japanese text, tracked with the runtime messages below. `docs/` is a bundled copy of the rhysd/actionlint documentation and is not translated.
- Runtime messages (logs, errors) are English. Existing Japanese runtime text in workflows (log and error messages, and the tracking Issue created by `check-typescript-eslint-ts7-support.yml`) is tracked separately; do not change it without checking the impact on downstream repositories.
- Do not rewrite Git history to change the language of past commits.

## Overview

A provider of templates reused across many repositories. It is not an application and has no `package.json`. Other repositories either copy files with `wget` or reference `uses: book000/templates/.github/workflows/reusable-*.yml@master`, so changes directly affect downstream repositories.

- `workflows/`: workflows that callers copy (`old/` holds legacy ones). The real work is done by calling `.github/workflows/reusable-*.yml`
- `.github/workflows/reusable-*.yml`: the reusable workflows themselves
- Other files in `.github/workflows/`: this repository's own CI (lint, tests, README generation, Renovate config validation, etc.)
- `dockerfiles/*.Dockerfile`: Dockerfile templates. `dockerfiles/tests/<name>/` holds the apps used to verify them
- `renovate/`: shared Renovate configs (`base*.json` are the common parts, `public.json` and `private.json` are what callers copy). The root `renovate.json` is this repository's own config
- `test-scenarios/`: test projects for the reusable workflows (see `test-scenarios/README.md`)
- `scripts/generate-readme.js`: generates `README.md`
- `actionlint`: a committed actionlint binary (Linux 64-bit ELF). CI downloads the latest version and does not use this binary
- `docs/`: a bundled copy of the rhysd/actionlint documentation, not specific to this repository

## Commands

```bash
# Regenerate README.md (from .github/templates.md and workflows/; needs js-yaml)
npm install --no-save js-yaml   # first time only (CI uses yarn add js-yaml); leaves no lock file
node scripts/generate-readme.js

# Validate workflows (same ignores as CI)
./actionlint -color -shellcheck= \
  -ignore='unexpected.*key.*background' \
  -ignore='step.*must.*run.*script.*with.*run.*section.*or.*run.*action.*with.*uses.*section'

# Validate Dockerfiles
docker build --check -f dockerfiles/node-app-pnpm.Dockerfile .
docker run --rm -i hadolint/hadolint < dockerfiles/node-app-pnpm.Dockerfile
```

- The `-ignore` flags match `actionlint.yml` (which checks this repository's own workflows in `.github/workflows/`) and suppress known false positives: actionlint does not support the GitHub Actions `background` / `wait-all` keywords yet. Drop them once actionlint supports them.
- The `workflows/` check (`actionlint-templates.yml`) replaces `.github/workflows/*` with `workflows/*` and runs without `-ignore`. Do this in a separate temporary repository locally.
- Integration tests for the reusable workflows and Dockerfiles run on GitHub Actions (`test-reusable-workflows.yml`, `dockerfile-test.yml`).

## Development guidelines

- `README.md` is generated; do not edit it by hand. Edit `.github/templates.md` and run `node scripts/generate-readme.js` (on push, `generate-readme.yml` commits the result). The input descriptions come from `inputs.<name>.description` in the reusable workflows.
- Do not remove, rename or make required any `inputs`, `secrets`, `outputs`, job name or file path of a reusable workflow without checking backward compatibility. Check that a changed default does not change behavior.
- Do not change strings that callers match on (for example `body-includes: Environment 承認待ち` in the approval comment of `workflows/*.yml`). If you must, change the heading of the comment body and the search condition in `workflows/` together.
- In new shell steps, pass workflow inputs and other expressions through `env:` and reference them as `"$VAR"`; do not interpolate `${{ }}` directly into `run:` scripts.
- Inputs that cross a trust boundary, such as `allow-unsafe-pr-checkout`, must be safe by default (`false`). Never run fork PR code in a privileged context.
- References to `book000/templates` itself use tags or branches, following the Renovate setting (`pinDigests: false`).
- When adding a reusable workflow, add the wrapper under `workflows/`, a test under `test-scenarios/`, and a test job in `test-reusable-workflows.yml` (including `needs` and the result check of `test-summary`).
- Dockerfile templates are Alpine-based and set the timezone to `Asia/Tokyo`. When adding one, put a verification app in `dockerfiles/tests/<file name without extension>/`.
- GitHub Actions YAML uses 2-space indentation. Pin third-party Actions to commit SHAs, as the existing files do.
- Never put secrets or credentials in `.env` files or commits, and never print credentials or personal data to logs. Secrets used by reusable workflows are managed in the caller repository.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and branches follow [Conventional Branch](https://conventional-branch.github.io) (`feat/...`, `fix/...`).
- Do not commit to Renovate PRs.
- Clone repositories to a temporary directory when investigating them.
