#!/usr/bin/env bash
# Configuration for quality-check

# Maximum allowed lines for a Rust source file
MAX_RS_LINES=300

# Code duplication (PMD CPD) settings
# Minimum tokens to consider as duplication. Tune to reduce noise.
: "${CPD_MIN_TOKENS:=100}"
# Include test directories in duplication scan (defaults to false)
: "${CPD_INCLUDE_TESTS:=false}"
# PMD version to download if not installed and Java is available
: "${PMD_VERSION:=7.0.0}"
# Path under target/ where tools may be cached
: "${TOOLS_DIR:=$ROOT_DIR/target/tools}"

# Coverage analysis settings
# Minimum required line coverage percentage (0-100)
: "${COVERAGE_MIN_LINE_PERCENT:=80}"
# Minimum required function coverage percentage (0-100)
: "${COVERAGE_MIN_FUNCTION_PERCENT:=85}"
# Whether to fail the build if coverage requirements are not met
: "${COVERAGE_FAIL_ON_LOW:=true}"

export MAX_RS_LINES
export CPD_MIN_TOKENS
export CPD_INCLUDE_TESTS
export PMD_VERSION
export TOOLS_DIR
export COVERAGE_MIN_LINE_PERCENT
export COVERAGE_MIN_FUNCTION_PERCENT
export COVERAGE_FAIL_ON_LOW
