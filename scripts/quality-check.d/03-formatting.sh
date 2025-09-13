#!/usr/bin/env bash
# Gate: formatting - auto-fix formatting issues and stage changes
# Run formatter (will modify files in-place)
run_cmd "cargo fmt --all"
# Stage any formatting changes made by cargo fmt
run_cmd "git add -- ./"
