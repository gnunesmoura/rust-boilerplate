#!/usr/bin/env bash
# Gate: cpd - Check for code duplications using PMD CPD

# Input directories
input_dirs=("src")
test_dirs=("tests")

# Build include/exclude options based on CPD_INCLUDE_TESTS
includes=("--dir" "${input_dirs[0]}")
excludes=()
if [ "${CPD_INCLUDE_TESTS}" != "true" ]; then
  for d in "${test_dirs[@]}"; do
    excludes+=("--exclude" "$d/")
  done
else
  # If tests included, add them to dirs
  for d in "${test_dirs[@]}"; do
    includes+=("--dir" "$d")
  done
fi

# Run CPD via Docker
cpd_log="$LOG_DIR/cpd.txt"
if ! docker run --rm -v "$ROOT_DIR":"/src" -w /src pmdcode/pmd:latest \
  cpd --language rust --minimum-tokens "$CPD_MIN_TOKENS" "${includes[@]}" "${excludes[@]}" \
  >"$cpd_log" 2>&1; then
  # CPD returns non-zero exit code when duplications are found, which is normal
  # Check if it actually produced output (meaning it ran successfully)
  if [ ! -s "$cpd_log" ]; then
    add_err "CPD execution failed (see $cpd_log)"
    exit 1
  fi
  # If log file has content, CPD ran successfully (even with non-zero exit)
fi

# Parse and check for duplications
duplication_count=$(grep -c "Found a [0-9]\+ line" "$cpd_log")

if [ "$duplication_count" -gt 0 ]; then
  add_err "Found $duplication_count duplication(s) (see $cpd_log)"
  exit 1
fi
