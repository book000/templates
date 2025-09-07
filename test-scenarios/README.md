# Test Scenarios for Reusable Workflows

This directory contains test scenarios to validate that the reusable GitHub workflows in this repository function correctly.

## Test Structure

- `nodejs-yarn/` - Test project for `reusable-nodejs-ci.yml`
- `nodejs-pnpm/` - Test project for `reusable-nodejs-ci-pnpm.yml`
- `maven/` - Test project for `reusable-maven.yml`
- `docker/` - Test files for `reusable-docker.yml` and `reusable-hadolint-ci.yml`
- `workflows/` - Test workflow files for `reusable-actionlint.yml`

## Purpose

These test scenarios help ensure that:

1. **Breaking changes are detected early** - When dependencies like `actions/setup-node` are updated, the tests will catch issues before they affect downstream projects.
2. **Workflow syntax is valid** - All reusable workflows use correct GitHub Actions syntax.
3. **Basic functionality works** - Each workflow can successfully process simple, valid inputs.
4. **Regression prevention** - Changes to workflows are validated before being released.

## How Tests Work

The tests are executed by the `.github/workflows/test-reusable-workflows.yml` workflow, which:

1. **Calls each reusable workflow** with appropriate test inputs
2. **Uses non-destructive parameters** (e.g., `is-merged: false`, `is-release: false`)
3. **Skips problematic steps** (e.g., dependency checking that might fail in test scenarios)
4. **Validates basic execution** without side effects like publishing or deploying

## Maintenance

When adding or modifying reusable workflows:

1. **Update test scenarios** if new input parameters are added
2. **Add new test directories** for new workflow types
3. **Ensure test projects remain minimal** but functional
4. **Update the main test workflow** to include new workflows

This testing approach helps maintain the reliability of reusable workflows that are used across multiple repositories.