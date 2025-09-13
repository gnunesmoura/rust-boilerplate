#!/usr/bin/env bash
# Gate: security (cargo-audit) - optional locally via RUN_AUDIT=1

# Check if a command exists
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Log file for cargo-audit output
AUDIT_LOG="target/quality-logs/cargo-audit.log"



if [ "${RUN_AUDIT:-0}" = "1" ] || has_cmd cargo-audit; then
  if ! has_cmd cargo-audit; then
    echo "[quality-check][info] cargo-audit not available; skipping (expected pre-installed in dev image)"
    exit 0
  fi
  echo "[quality-check] Running cargo-audit"

  mkdir -p "$(dirname "$AUDIT_LOG")"


    # If AUDIT_STRICT=1, run without ignore list
    if [ "${AUDIT_STRICT:-0}" = "1" ]; then
      echo "[quality-check] Running cargo-audit in strict mode (no ignores)"
      run_cmd "cargo audit --deny warnings" | tee "$AUDIT_LOG"
    else
      # List of advisories to ignore (add more as needed)
      IGNORED_ADVISORIES=(
      )

      IGNORE_FLAGS=""
      for adv in "${IGNORED_ADVISORIES[@]}"; do
        IGNORE_FLAGS+=" --ignore $adv"
      done

      # Run cargo audit with ignore flags and save output to log
      run_cmd "cargo audit --deny warnings $IGNORE_FLAGS" | tee "$AUDIT_LOG"
    fi

  # Print summary if vulnerabilities found
  if grep -q "Vulnerabilities found" "$AUDIT_LOG"; then
    echo "[quality-check][fail] Vulnerabilities detected by cargo-audit! See $AUDIT_LOG for details."
    # Optionally, print the summary section
    grep -A 10 "Vulnerabilities found" "$AUDIT_LOG"
  fi
else
  echo "[quality-check][info] cargo-audit not enabled (set RUN_AUDIT=1 to run locally or install cargo-audit to enable)."
fi
