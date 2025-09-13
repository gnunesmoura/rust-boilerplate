## Copilot / AI Agent Instructions for Rust Project

This file provides guidance for an AI coding agent to be productive in this Rust workspace.

### Test-Driven Development (TDD)

- **Behavior**: Act as a test-driven developer. Write tests first, then implement code to pass those tests.
- **Testable Code**: Ensure all code is testable. Use dependency injection, interfaces, and avoid tight coupling.
- **Unit Tests**: Place unit tests inside the Rust files using `#[cfg(test)]` modules.
- **Integration Tests**: Place integration tests in `tests/` directory at the crate root (e.g., `src/tests/` or `tests/` for binary crates).
- **Testing Framework**: Use Rust's built-in testing framework with `#[test]` attributes.
- **Coverage**: Aim for high test coverage, focusing on critical paths and edge cases.

### Code Quality

- Prefer small, focused modules.
- Follow Rust best practices for safety and performance.
- Use `cargo fmt` and `clippy` for formatting and linting.
