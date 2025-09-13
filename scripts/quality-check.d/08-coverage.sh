#!/usr/bin/env bash
# Gate: coverage - Analyze code coverage and enforce minimum thresholds

# Check if coverage data already exists from previous gate (06-test-and-coverage.sh)
if [ -f "target/coverage/lcov.info" ] && [ "${RUN_COVERAGE:-0}" = "1" ]; then
  echo "[coverage] Using existing coverage data from previous gate"
elif [ "${RUN_COVERAGE:-0}" = "1" ]; then
  # Check if nightly toolchain is available
  if ! rustup toolchain list | grep -q "nightly"; then
    echo "[coverage] Installing nightly toolchain..."
    if ! run_cmd "rustup install nightly"; then
      add_err "Failed to install nightly toolchain required for coverage analysis"
      exit 1
    fi
  fi

  # Generate coverage data (lcov format for parsing)
  if ! run_cmd "cargo +nightly llvm-cov --workspace --all-features --lcov --output-path target/coverage/lcov.info --no-report"; then
    add_err "Failed to generate coverage data"
    exit 1
  fi
else
  echo "[coverage] Skipping coverage analysis (set RUN_COVERAGE=1 to enable)"
  exit 0
fi

# Calculate overall coverage statistics
total_functions_hit=$(awk '/^FNH:/ {split($1,a,":"); sum += a[2]} END {print sum+0}' target/coverage/lcov.info)
total_functions_found=$(awk '/^FNF:/ {split($1,a,":"); sum += a[2]} END {print sum+0}' target/coverage/lcov.info)
total_lines_hit=$(awk '/^LH:/ {split($1,a,":"); sum += a[2]} END {print sum+0}' target/coverage/lcov.info)
total_lines_found=$(awk '/^LF:/ {split($1,a,":"); sum += a[2]} END {print sum+0}' target/coverage/lcov.info)

# Calculate percentages
if [ -n "$total_functions_found" ] && [ "$total_functions_found" -gt 0 ]; then
  function_coverage_percent=$((total_functions_hit * 100 / total_functions_found))
else
  function_coverage_percent=0
fi

if [ -n "$total_lines_found" ] && [ "$total_lines_found" -gt 0 ]; then
  line_coverage_percent=$((total_lines_hit * 100 / total_lines_found))
else
  line_coverage_percent=0
fi

echo "[coverage] Total Functions: $total_functions_hit / $total_functions_found hit (${function_coverage_percent}%)"
echo "[coverage] Total Lines: $total_lines_hit / $total_lines_found hit (${line_coverage_percent}%)"

# Check coverage thresholds
coverage_failed=false

if [ "$function_coverage_percent" -lt "$COVERAGE_MIN_FUNCTION_PERCENT" ]; then
  echo "[coverage] Function coverage ${function_coverage_percent}% is below minimum ${COVERAGE_MIN_FUNCTION_PERCENT}%"
  coverage_failed=true
fi

if [ "$line_coverage_percent" -lt "$COVERAGE_MIN_LINE_PERCENT" ]; then
  echo "[coverage] Line coverage ${line_coverage_percent}% is below minimum ${COVERAGE_MIN_LINE_PERCENT}%"
  coverage_failed=true
fi

if [ "$coverage_failed" = true ]; then
  if [ "$COVERAGE_FAIL_ON_LOW" = true ]; then
    add_err "Coverage requirements not met (functions: ${function_coverage_percent}% < ${COVERAGE_MIN_FUNCTION_PERCENT}%, lines: ${line_coverage_percent}% < ${COVERAGE_MIN_LINE_PERCENT}%)"
    exit 1
  else
    echo "[coverage] Warning: Coverage requirements not met, but continuing due to COVERAGE_FAIL_ON_LOW=false"
  fi
else
  echo "[coverage] Coverage requirements met"
fi
