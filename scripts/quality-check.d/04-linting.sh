#!/usr/bin/env bash
# Gate: linting - attempt auto-fix and fail on remaining warnings
run_cmd "cargo clippy --all-targets --all-features --fix --allow-dirty --allow-staged"
# Run clippy strictly and fail on warnings for remaining issues
run_cmd "cargo clippy --all-targets --all-features -- -D warnings"
# Stage any changes made by clippy --fix
run_cmd "git add -- ./"
