#!/usr/bin/env bash
# Helper functions used by quality-check gates

add_err() {
  local msg="$1"
  local prefix="${GATE_NAME:+[$GATE_NAME]}"
  if [ -n "$prefix" ]; then
    msg="$prefix $msg"
  fi
  if [ -z "${ERR_MSGS:-}" ]; then
    ERR_MSGS="$msg"
  else
    ERR_MSGS="$ERR_MSGS\n$msg"
  fi
  # Also persist errors to a shared errors file so child shells can report back to the orchestrator.
  # LOG_DIR should be exported by the caller; fallback to ./target/quality-logs if not set.
  ERR_FILE="${ERR_FILE:-${LOG_DIR:-./target/quality-logs}/errors.txt}"
  mkdir -p "$(dirname "$ERR_FILE")" 2>/dev/null || true
  printf "%s\n" "$msg" >>"$ERR_FILE" 2>&2 || true
}

run_cmd() {
  echo "[quality-check] $*"
  if ! logfile=$(mktemp "$LOG_DIR/quality-logs-XXXXXXXX.log"); then
    logfile="$LOG_DIR/quality-logs-fallback.log"
  fi

  if eval "$@" >"$logfile" 2>&1; then
    rm -f "$logfile" 2>/dev/null || true
    return 0
  else
    echo "[quality-check][error] command failed: $* (log: $logfile)" >&2
    add_err "Command failed: $* (log: $logfile). Repro: run this command locally, inspect $logfile or target/quality-logs/latest/*.err"
    return 1
  fi
}
