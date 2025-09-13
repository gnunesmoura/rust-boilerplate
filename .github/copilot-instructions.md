## Copilot / AI Agent Instructions for Rust Project

### Core Principles

- **Test-Driven Development**: Write tests first, then implement code to pass those tests
- **Quality First**: Run `./scripts/quality-check.sh` before finalizing any code changes
- **Small Modules**: Keep Rust files under 300 lines (enforced by 02-code-quality.sh)
- **High Coverage**: Maintain 80%+ line coverage and 85%+ function coverage
- **Domain Driven Design**: Model domain concepts explicitly using Rust's type system, keep business logic separate from infrastructure concerns

### Quality Standards

**Code Quality**: Maximum 300 lines per file, modular design
**Formatting**: `cargo fmt` compliance (auto-fixed by 03-formatting.sh)
**Linting**: `cargo clippy` with auto-fix (enforced by 04-linting.sh)
**Security**: `cargo audit` for vulnerabilities (05-security.sh)
**Testing**: `cargo test` with coverage analysis (06-testing.sh)
**Coverage**: Minimum 80% lines, 85% functions (08-coverage.sh)
**Duplication**: No code duplication (enforced by 07-duplication.sh)

### Essential Commands

```bash
# Validate all quality gates
./scripts/quality-check.sh

# Quick format/lint check
./scripts/quality-check.sh --only "03-formatting.sh|04-linting.sh"

# Test validation
./scripts/quality-check.sh --only 06-testing.sh
```

### Development Workflow

1. Write tests first (`#[cfg(test)]` modules for unit tests)
2. Implement code to pass tests
3. Run quality checks: `./scripts/quality-check.sh`
4. Fix any issues found
5. Commit only when all quality gates pass

### Test Structure

- **Unit Tests**: Inside source files with `#[cfg(test)]` modules
- **Integration Tests**: In `tests/` directory at crate root
- **Framework**: Rust's built-in testing with `#[test]` attributes
- **Coverage**: Focus on critical paths and edge cases

### Key Reminders

- Always run quality checks before committing
- Prefer small, focused modules
- Use `cargo fmt` and `clippy` for consistent code style
- Avoid code duplication
- Maintain high test coverage
- Address security vulnerabilities promptly
- **DDD Practices**: Use strong typing for domain models, separate business logic from infrastructure, model domain events and invariants explicitly
