---
mode: 'agent'
tools: ['GitHubCopilotTools']
description: 'Run pre-commit quality checks and fix any issues found'
---

# Pre-Commit Quality Check and Fix Agent

Your goal is to run the pre-commit quality checks for the Product Management CLI project and systematically fix any issues that are discovered.

## Step-by-Step Process


### 1. Initial Analyzis of Failures

If any quality gates fail:

- Examine the detailed logs in `target/quality-logs/latest/`
- Identify the specific type of failure (formatting, linting, test failures, etc.)
- Prioritize fixes based on severity and ease of resolution

#### If there is no Issue, Initial Quality Check Run

- Run `./scripts/quality-check.sh` to execute all pre-commit quality gates
- This includes: formatting, linting, tests, security audit, code duplication, and layering checks
- Capture the output and check for any failures

### 2. Fix Issues Systematically

#### For File Size Issues

- Identify rust files exceeding size limits of 300 lines
- Refactor large files into smaller, domain-specific modules
- Ensure all functionality remains intact after refactoring

#### For Formatting Issues

- Run `cargo fmt` to automatically fix formatting
- Verify the changes don't break functionality

#### For Linting Issues

- Fix clippy warnings by addressing the specific suggestions
- Use `cargo clippy --fix` for automatic fixes where possible
- Manually fix remaining issues following Rust best practices

#### For Test Failures

- Run `cargo test` to identify failing tests
- Evaluate the need for the usage of the test_helpers module
- Analyze test output to understand root causes
- Fix test logic, assertions, or implementation bugs
- Ensure all tests pass individually and in parallel

#### For Security Audit Issues

- Review `cargo audit` output for vulnerabilities
- Update dependencies to patched versions
- Document any ignored advisories with justification

#### For Code Duplication Issues

- Review PMD CPD findings in the logs
- Refactor duplicated code into shared functions/utilities
- Ensure changes maintain functionality

#### For Layering Violations

- Review the layering report for architectural violations
- Move code to appropriate layers (CLI → Core → Infra)
- Update dependencies and imports accordingly

### 3. Validation and Re-run

- After fixing issues, re-run the quality checks
- Ensure all gates pass successfully
- If new issues are introduced, repeat the fix process
- Continue until all quality gates pass

### 4. Documentation Updates

- If code changes affect documentation, update relevant docs
- Ensure any new features or changes are properly documented
- Update CHANGELOG.md if applicable

## Quality Standards to Maintain

- **Zero warnings**: Both rustc and clippy must pass cleanly
- **Test coverage**: All tests must pass (coverage analysis optional in fast mode)
- **Code formatting**: Must comply with `cargo fmt` standards
- **Security**: No unaddressed vulnerabilities
- **Architecture**: Clean separation between CLI, Core, and Infra layers
- **Performance**: No significant performance regressions

## Tools and Commands

Use these tools to investigate and fix issues:

- `run_in_terminal`: Execute quality checks and fix commands
- `read_file`: Examine log files and source code
- `insert_edit_into_file`: Apply fixes to source files
- `get_errors`: Check for compilation errors
- `grep_search`: Find patterns in code for refactoring

## Success Criteria

The process is complete when:

- ✅ `./scripts/quality-check.sh` exits with code 0
- ✅ All quality gates pass without errors
- ✅ No new issues are introduced during fixes
- ✅ Code maintains functionality and follows project standards
