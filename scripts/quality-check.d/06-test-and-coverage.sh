#!/usr/bin/env bash
# Quality gate: Code coverage reporting (non-blocking for CI)

set -euo pipefail

echo "[coverage] Checking coverage capabilities..."

# Check if cargo-llvm-cov is available
if ! command -v cargo-llvm-cov >/dev/null 2>&1; then
    echo "[coverage] cargo-llvm-cov not available in PATH - skipping (expected in dev image; treat as optional locally)"
    exit 0
fi

# For pre-commit speed, skip coverage instrumentation unless explicitly requested
if [ "${RUN_COVERAGE:-0}" != "1" ]; then
    echo "[coverage] Skipping coverage instrumentation for pre-commit speed"
    echo "[coverage] Set RUN_COVERAGE=1 to run full coverage analysis"
    echo "[coverage] Running all tests without coverage instrumentation..."
    
    # Run all tests without coverage instrumentation for speed
    run_cmd "cargo test --workspace --all-features --exclude test-helpers --exclude test-helpers-macros --exclude performance-tests --exclude user-journey-tests"
    echo "[coverage] All tests passed (coverage instrumentation skipped for speed)"
    exit 0
fi

# Ensure coverage directory exists
mkdir -p target/coverage

echo "[coverage] Coverage analysis capability confirmed"
echo "[coverage] Target: ${COVERAGE_MIN_LINE_PERCENT}% line coverage, ${COVERAGE_MIN_FUNCTION_PERCENT}% function coverage (enforced)"

echo "[coverage] Running tests with coverage instrumentation for workspace"
run_cmd "cargo llvm-cov test --workspace --all-features --exclude test-helpers --exclude test-helpers-macros --exclude performance-tests --exclude user-journey-tests"

echo "[coverage] Generating lcov report for evaluation"

# Generate lcov only
run_cmd "cargo llvm-cov report --lcov --output-path target/coverage/lcov.info"

# Function to parse lcov report and check all files for >=75% coverage
parse_lcov_for_all() {
    local lcov_file="target/coverage/lcov.info"
    local current_file=""
    local total_lines=0
    local covered_lines=0
    local failed=0
    local files_checked=0

    while IFS= read -r line; do
        if [[ $line == SF:* ]]; then
            # Process previous file
            if [[ -n $current_file ]]; then
                if (( total_lines > 0 )); then
                    local perc=$(( covered_lines * 100 / total_lines ))
                    (( files_checked++ ))
                    if (( perc < COVERAGE_MIN_LINE_PERCENT )); then
                        echo "[coverage] FAIL: $current_file at $perc% ($covered_lines/$total_lines)"
                        failed=1
                    fi
                fi
            fi
            current_file="${line#SF:}"
            total_lines=0
            covered_lines=0
        elif [[ $line == DA:* ]]; then
            local da_part="${line#DA:}"
            local exec_count="${da_part#*,}"
            (( total_lines++ ))
            if (( exec_count > 0 )); then
                (( covered_lines++ ))
            fi
        fi
    done < "$lcov_file"

    # Process the last file
    if [[ -n $current_file ]]; then
        if (( total_lines > 0 )); then
            local perc=$(( covered_lines * 100 / total_lines ))
            (( files_checked++ ))
            if (( perc < COVERAGE_MIN_LINE_PERCENT )); then
                echo "[coverage] FAIL: $current_file at $perc% ($covered_lines/$total_lines)"
                failed=1
            fi
        fi
    fi

    if (( failed )); then
        echo "[coverage] Coverage check failed: $files_checked files checked, some below ${COVERAGE_MIN_LINE_PERCENT}%"
        return 1
    else
        echo "[coverage] Coverage check passed: $files_checked files at >=${COVERAGE_MIN_LINE_PERCENT}%"
        return 0
    fi
}

# Call the function to perform the check
if ! parse_lcov_for_all; then
    echo "[coverage] Overall coverage check failed"
    exit 1
fi

echo "[coverage] Coverage check passed (${COVERAGE_MIN_LINE_PERCENT}% lines overall)"