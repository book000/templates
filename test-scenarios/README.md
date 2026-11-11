# Test Scenarios for Reusable Workflows

This directory contains test scenarios to validate that the reusable GitHub workflows in this repository function correctly.

## Test Structure

- `nodejs-yarn/` - Test project for `reusable-nodejs-ci.yml`
- `nodejs-pnpm/` - Test project for `reusable-nodejs-ci-pnpm.yml`
- `nodejs-pnpm-ignored-build-scripts/` - Project for the negative test that checks pnpm "Ignored build scripts" detection
- `maven/` - Test project for `reusable-maven.yml`
- `docker/` - Test files for `reusable-docker.yml` and `reusable-hadolint-ci.yml` (`docker/test.sh` is also the target of `reusable-shellcheck-ci.yml`)
- `python/` - Test project for `reusable-python-ci.yml`
- `bicep/` - Test files for `reusable-bicep-ci.yml`

## Purpose

These test scenarios help ensure that:

1. **Breaking changes are detected early** - When dependencies like `actions/setup-node` are updated, the tests catch issues before they affect downstream projects.
2. **Workflow syntax is valid** - All reusable workflows use correct GitHub Actions syntax.
3. **Basic functionality works** - Each workflow can successfully process simple, valid inputs.
4. **Regression prevention** - Changes to workflows are validated before being released.

## How Tests Work

The tests are executed by `.github/workflows/test-reusable-workflows.yml`, which:

1. **Calls each reusable workflow** with test inputs from this directory
2. **Uses non-destructive parameters** (e.g. `is-merged: false`, `is-release: false`) so nothing is published or deployed
3. **Skips problematic steps** (e.g. `depcheck`, via `disabled-jobs`)
4. **Validates basic execution** without side effects

## Maintenance

When adding or modifying reusable workflows:

1. **Update test scenarios** if new input parameters are added
2. **Add new test directories** for new workflow types
3. **Keep test projects minimal** but functional
4. **Update the main test workflow** to include new workflows, and add the new job to the `needs` and the result check of the `test-summary` job
