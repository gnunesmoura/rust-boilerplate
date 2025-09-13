#!/usr/bin/env bash
set -u

# Orchestrator for modular pre-commit quality checks
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 2

# -----------------------------
# Args and environment toggles
# -----------------------------
VERBOSE=${QC_VERBOSE:-0}
ONLY=${QC_ONLY:-}
LIST=0
MAX_LOG_LINES=${QC_MAX_LOG_LINES:-120}

print_usage() {
  cat <<USAGE
Usage: scripts/quality-check.sh [--list] [--only PATTERN] [-v|--verbose] [--max-log-lines N]

Options:
  --list              List available gates and exit.
  --only PATTERN      Run only gates whose filename contains PATTERN (substring match).
  -v, --verbose       Print per-gate summaries and echo failures with tail of logs.
  --max-log-lines N   How many lines of a failing gate's .err to print (default: $MAX_LOG_LINES).

Env toggles (alternatives to flags):
  QC_VERBOSE=1, QC_ONLY=pattern, QC_MAX_LOG_LINES=N
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --only) ONLY=${2:-}; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    --max-log-lines) MAX_LOG_LINES=${2:-120}; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "[quality-check][warn] Unknown arg: $1" >&2; shift ;;
  esac
done

echo "[quality-check] Running modular pre-commit quality checks from $ROOT_DIR"

# Check for recent successful run and no relevant changes
CACHE_FILE="$ROOT_DIR/target/quality-check-cache.txt"
if [ -f "$CACHE_FILE" ]; then
  STORED_HASH=$(head -n1 "$CACHE_FILE")
  # Compute current hash of relevant files
  CURRENT_HASH=$(find "$ROOT_DIR" -type f \( -name "*.rs" -o -name "Cargo.toml" -o -name "Cargo.lock" -o -path "*/scripts/quality-check*" \) -not -path "*/target/*" -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
  if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
    echo "[quality-check][skip] Skipping quality checks - no changes to relevant files since last successful run"
    exit 0
  fi
fi

# Directory to store logs for gate commands and aggregated errors. Put under target/ so it's ignored by git by default.
# Use a timestamped directory for each run and maintain a 'latest' symlink for quick access.
RUN_ID="$(date +%Y%m%d-%H%M%S)"
BASE_LOG_DIR="$ROOT_DIR/target/quality-logs"
LOG_DIR="$BASE_LOG_DIR/$RUN_ID"
mkdir -p "$LOG_DIR"

# Rotate old run directories in $BASE_LOG_DIR, keeping only the most recent 3 runs.
# We only consider directories that match the timestamp format YYYYMMDD-HHMMSS to avoid
# touching other files or symlinks (like 'latest').
KEEP=3
if [ -d "$BASE_LOG_DIR" ]; then
  # Collect timestamped run directories sorted lexicographically (timestamp format sorts correctly).
  mapfile -t _runs < <(find "$BASE_LOG_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | grep -E '^[0-9]{8}-[0-9]{6}$' | sort)
  _num_runs=${#_runs[@]}
  if [ "$_num_runs" -gt "$KEEP" ]; then
    _del_count=$((_num_runs - KEEP))
    for ((i=0; i<_del_count; i++)); do
      _old_dir="${_runs[i]}"
      # Extra safety: ensure variable is non-empty and the path exists before deletion.
      if [ -n "$_old_dir" ] && [ -d "$BASE_LOG_DIR/$_old_dir" ]; then
        rm -rf "$BASE_LOG_DIR/$_old_dir" || true
      fi
    done
  fi
fi

ln -sfn "$LOG_DIR" "$BASE_LOG_DIR/latest"

# Shared file for child shells to append errors into
ERR_FILE="$LOG_DIR/errors.txt"
: >"$ERR_FILE"

# Global (in-memory) error accumulator for this orchestrator process
ERR_MSGS=""
export ERR_MSGS
export LOG_DIR
export ERR_FILE

# Collect gates, skip helpers/config, sort deterministically
mapfile -t ALL_GATES < <(find "$ROOT_DIR/scripts/quality-check.d" -maxdepth 1 -type f -name '*.sh' -printf '%f\n' | sort)
GATES=()
for gate_name in "${ALL_GATES[@]}"; do
  # Skip orchestrator helpers/config (00/01)
  if [[ "$gate_name" =~ ^0[01]- ]]; then
    continue
  fi
  # Apply --only filter if provided
  if [ -n "$ONLY" ] && [[ "$gate_name" != *"$ONLY"* ]]; then
    continue
  fi
  GATES+=("$gate_name")
done

if [ "$LIST" -eq 1 ]; then
  printf '%s\n' "${GATES[@]}"
  exit 0
fi

if [ ${#GATES[@]} -eq 0 ]; then
  echo "[quality-check][ok] No gates matched selection. Nothing to run."
  exit 0
fi

# Run all modular gate scripts in isolated shells so one failing gate doesn't stop others.
# Each gate may rely on functions from 01-helpers.sh; source helpers in the child shell before running the gate.
failed_any=0

# Function to run a single gate
run_gate() {
  local gate_name="$1"
  local f="$ROOT_DIR/scripts/quality-check.d/$gate_name"
  [ -f "$f" ] || return 1

  printf '[quality-check] Running gate: %s\n' "$gate_name"

  local start_ts=$(date +%s)
  # Run the gate in a subshell, sourcing helpers first so functions like run_cmd and add_err are available.
  (
    set -euo pipefail
    export GATE_NAME="$gate_name"
    # shellcheck disable=SC1090
    source "$ROOT_DIR/scripts/quality-check.d/00-config.sh" || true
    # shellcheck disable=SC1090
    source "$ROOT_DIR/scripts/quality-check.d/01-helpers.sh" || true
    # shellcheck disable=SC1090
    source "$f"
  ) >"$LOG_DIR/${gate_name%.sh}.out" 2>"$LOG_DIR/${gate_name%.sh}.err" || local rc=$?

  # Capture exit code (rc may be unset if subshell succeeded)
  local rc=${rc:-0}
  local dur=$(( $(date +%s) - start_ts ))
  if [ "$rc" -ne 0 ]; then
    echo "[quality-check][gate-fail] $gate_name exited with code $rc in ${dur}s (logs: ${gate_name%.sh}.out, ${gate_name%.sh}.err)" >&2
    if [ "$VERBOSE" -eq 1 ]; then
      echo "[quality-check][gate-fail][tail:$MAX_LOG_LINES] $gate_name .err:" >&2
      tail -n "$MAX_LOG_LINES" "$LOG_DIR/${gate_name%.sh}.err" >&2 || true
    fi
    return 1
  else
    if [ "$VERBOSE" -eq 1 ]; then
      echo "[quality-check][gate-ok] $gate_name (${dur}s)" 
    fi
    return 0
  fi
}

# Function to run gates in parallel
run_parallel() {
  local gates=("$@")
  local pids=()
  local failed=0

  for gate_name in "${gates[@]}"; do
    run_gate "$gate_name" &
    pids+=($!)
  done

  # Wait for all background processes and collect exit codes
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      failed=1
    fi
  done

  return $failed
}

# Function to run gates sequentially
run_sequential() {
  local gates=("$@")
  local failed=0

  for gate_name in "${gates[@]}"; do
    if ! run_gate "$gate_name"; then
      failed=1
    fi
  done

  return $failed
}

# Group gates by execution strategy
# Parallel group: independent static checks (code quality, security, duplication)
PARALLEL_GATES=()
# Sequential group 1: file-modifying gates (formatting, linting)
SEQUENTIAL_GATES_1=()
# Sequential group 2: testing and coverage
SEQUENTIAL_GATES_2=()

for gate_name in "${GATES[@]}"; do
  case "$gate_name" in
    02-code-quality.sh|05-security.sh|07-duplication.sh)
      PARALLEL_GATES+=("$gate_name")
      ;;
    03-formatting.sh|04-linting.sh)
      SEQUENTIAL_GATES_1+=("$gate_name")
      ;;
    06-testing.sh|08-coverage.sh)
      SEQUENTIAL_GATES_2+=("$gate_name")
      ;;
    *)
      # Any other gates run sequentially as fallback
      SEQUENTIAL_GATES_1+=("$gate_name")
      ;;
  esac
done

# Execute gate groups
if [ ${#PARALLEL_GATES[@]} -gt 0 ]; then
  echo "[quality-check] Running ${#PARALLEL_GATES[@]} gates in parallel: ${PARALLEL_GATES[*]}"
  if ! run_parallel "${PARALLEL_GATES[@]}"; then
    failed_any=1
  fi
fi

if [ ${#SEQUENTIAL_GATES_1[@]} -gt 0 ]; then
  echo "[quality-check] Running ${#SEQUENTIAL_GATES_1[@]} gates sequentially: ${SEQUENTIAL_GATES_1[*]}"
  if ! run_sequential "${SEQUENTIAL_GATES_1[@]}"; then
    failed_any=1
  fi
fi

if [ ${#SEQUENTIAL_GATES_2[@]} -gt 0 ]; then
  echo "[quality-check] Running ${#SEQUENTIAL_GATES_2[@]} gates sequentially: ${SEQUENTIAL_GATES_2[*]}"
  if ! run_sequential "${SEQUENTIAL_GATES_2[@]}"; then
    failed_any=1
  fi
fi

# Read back any persisted errors from child shells
if [ -s "$ERR_FILE" ]; then
  echo "[quality-check][fail] One or more quality checks reported issues:" >&2
  # Print the errors file content
  sed -n '1,2000p' "$ERR_FILE" >&2 || true
  echo "Logs at: $LOG_DIR (symlink: $BASE_LOG_DIR/latest)" >&2
  echo "Fix the issues and try again." >&2
  exit 1
fi

if [ "$failed_any" -ne 0 ]; then
  # There were non-zero exit codes but no structured error messages collected; print per-gate err logs
  echo "[quality-check][fail] One or more gates exited with non-zero status. See logs in $LOG_DIR (symlink: $BASE_LOG_DIR/latest)" >&2
  exit 1
fi

echo "[quality-check][ok] All quality checks passed. Logs at: $LOG_DIR (symlink: $BASE_LOG_DIR/latest)"
# Cache hash of relevant files for future skip validation
find "$ROOT_DIR" -type f \( -name "*.rs" -o -name "Cargo.toml" -o -name "Cargo.lock" -o -path "*/scripts/quality-check*" \) -not -path "*/target/*" -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1 > "$CACHE_FILE"
exit 0

