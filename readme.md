# AI Assisted Development Rust Boilerplate

A comprehensive Rust project boilerplate designed for AI-assisted development with built-in quality assurance, test-driven development practices, and automated code quality checks.

## Features

### 🧪 Quality Assurance Pipeline

- **Automated Quality Checks**: Run `./scripts/quality-check.sh` to validate code quality across multiple dimensions
- **Pre-commit Hooks**: Integrated pre-commit configuration to ensure quality gates pass before commits
- **CI/CD Pipeline**: GitHub Actions workflow for continuous integration with formatting, linting, testing, and security checks

### 📋 Quality Gates

- **Code Quality**: Enforces maximum 300 lines per file and modular design to work with AI tools effectively
- **Formatting**: `cargo fmt` compliance with auto-fixing
- **Linting**: `cargo clippy` with auto-fix capabilities
- **Security**: `cargo audit` for vulnerability scanning
- **Testing**: Comprehensive test suite with coverage analysis
- **Coverage**: Minimum 80% line coverage and 85% function coverage requirements
- **Duplication**: Automated detection and prevention of code duplication

### 🏗️ Development Workflow

1. Write tests first using `#[cfg(test)]` modules for unit tests
2. Implement code to pass the tests
3. Run quality checks: `./scripts/quality-check.sh`
4. Fix any issues found by the quality gates
5. Commit only when all quality gates pass

### 🤖 AI Assistance

- **Copilot Instructions**: Specialized prompts for AI-assisted development
- **TDD Focus**: Test-driven development principles built into the workflow
- **Domain-Driven Design**: Strong typing and separation of business logic from infrastructure

## Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/gnunesmoura/rust-boilerplate.git
   cd rust-boilerplate
   ```

2. **Run quality checks**

   ```bash
   ./scripts/quality-check.sh
   ```

3. **Build and run**

   ```bash
   cargo build
   cargo run
   ```

## Quality Check Commands

```bash
# Run all quality checks
./scripts/quality-check.sh

# Run only formatting and linting checks
./scripts/quality-check.sh --only "03-formatting.sh|04-linting.sh"

# Run only testing validation
./scripts/quality-check.sh --only 06-testing.sh

# List all available quality gates
./scripts/quality-check.sh --list
```

## Project Structure

```text
rust-boilerplate/
├── .github/
│   ├── copilot-instructions.md    # AI assistance guidelines
│   └── workflows/
│       └── ci.yml                 # GitHub Actions CI pipeline
├── scripts/
│   ├── quality-check.sh           # Main quality check orchestrator
│   └── quality-check.d/           # Individual quality gate scripts
├── src/
│   └── main.rs                    # Application entry point
├── .pre-commit-config.yaml        # Pre-commit hook configuration
├── Cargo.toml                     # Rust project configuration
└── readme.md                      # This file
```

## Requirements

- Rust 2024 edition or later
- Bash shell (for quality check scripts)
- Git (for version control and pre-commit hooks)

## Contributing

1. Follow the test-driven development workflow
2. Ensure all quality checks pass before submitting changes
3. Maintain high test coverage and code quality standards
4. Use `cargo fmt` and `cargo clippy` for consistent code style

## License

This project is open source. Please check the license file for details.
