#!/usr/bin/env bash
# Gate: code quality - check all .rs files don't exceed MAX_RS_LINES

MAX_RS_LINES=300

echo "[quality-check] Verifying all Rust files for max lines ($MAX_RS_LINES)"
find src -name "*.rs" -type f | while read -r f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt "$MAX_RS_LINES" ]; then
    if ! printf '%s\n' "${ALLOWED_LONG_FILES[@]}" | grep -q "^$f$"; then
      rel="$(realpath --relative-to="$ROOT_DIR" "$f" 2>/dev/null || printf "%s" "$f")"
      msg="Rust file exceeds ${MAX_RS_LINES} lines: $rel ($lines lines)"
      echo "[quality-check][fail] $msg" >&2
      echo "  -> Run the CDP Check, solve duplications, refactor the code into smaller, domain-focused modules to stay within the ${MAX_RS_LINES} line limit." >&2
      add_err "$msg"
    fi
  fi
done
