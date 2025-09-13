#!/usr/bin/env bash

set -euo pipefail

# Remove all Rust comments from files strictly inside the crates/ directory.
# - Supports nested block comments (/* ... */) with nesting.
# - Preserves string, raw string (r#"..."# / br#"..."#), and char literals.
# - Skips files outside of crates/ even if passed explicitly.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
CRATES_DIR="$REPO_ROOT/crates"

if [[ ! -d "$CRATES_DIR" ]]; then
    echo "Error: crates directory not found at $CRATES_DIR" >&2
    exit 1
fi

resolve_path() {
    # Cross-shell realpath (macOS/Linux compatible). Linux usually has realpath.
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    else
        python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"
    fi
}

is_under_crates() {
    local f_abs="$1"
    [[ "$f_abs" == "$CRATES_DIR"/* ]]
}

strip_file() {
    local file="$1"
    python3 - "$file" << 'PYSTRIP'
import sys, io, os

def is_char_lit(src, i):
        # Heuristic: '\''x' or '\'\'' or '\'u{..}' etc., short and closed soon.
        n = len(src)
        if src[i] != "'":
                return False
        j = i + 1
        if j >= n:
                return False
        if src[j] == '\\':
                j += 1
                if j < n:
                        j += 1
        else:
                j += 1
        return j < n and src[j] == "'" and (j - i) <= 4

def raw_string_prefix_len(src, i):
        # Matches: r#*"  or br#*"
        n = len(src)
        j = i
        saw_b = False
        if j < n and src[j] == 'b':
                saw_b = True
                j += 1
        if j >= n or src[j] != 'r':
                return 0, 0  # not raw
        j += 1
        h = 0
        while j < n and src[j] == '#':
                h += 1
                j += 1
        if j < n and src[j] == '"':
                # length of prefix to write from i to j inclusive
                return (j - i + 1), h
        return 0, 0

def strip_comments(src: str) -> str:
        out = []
        i = 0
        n = len(src)
        in_line = False
        block_depth = 0
        in_str = False
        raw_hashes = -1  # -1 means normal escaped string, >=0 raw string with that many '#'
        in_char = False

        while i < n:
                ch = src[i]

                # Handle line comment state
                if in_line:
                        if ch == '\n':
                                in_line = False
                                out.append('\n')
                        i += 1
                        continue

                # Handle block comment state (preserve newlines to keep line count)
                if block_depth > 0:
                        if ch == '/' and i + 1 < n and src[i+1] == '*':
                                block_depth += 1
                                i += 2
                                continue
                        if ch == '*' and i + 1 < n and src[i+1] == '/':
                                block_depth -= 1
                                i += 2
                                continue
                        if ch == '\n':
                                out.append('\n')
                        i += 1
                        continue

                # Handle string
                if in_str:
                        out.append(ch)
                        if raw_hashes == -1:
                                # normal string with escapes
                                if ch == '\\':
                                        if i + 1 < n:
                                                out.append(src[i+1])
                                                i += 2
                                                continue
                                elif ch == '"':
                                        in_str = False
                        else:
                                # raw string: end is '"' followed by raw_hashes '#'
                                if ch == '"':
                                        if src[i+1:i+1+raw_hashes] == ('#' * raw_hashes):
                                                out.append('#' * raw_hashes)
                                                i += 1 + raw_hashes
                                                in_str = False
                                                continue
                        i += 1
                        continue

                # Handle char literal
                if in_char:
                        out.append(ch)
                        if ch == '\\':
                                if i + 1 < n:
                                        out.append(src[i+1])
                                        i += 2
                                        continue
                        elif ch == "'":
                                in_char = False
                        i += 1
                        continue

                # Normal code: detect comment starts
                if ch == '/' and i + 1 < n:
                        nxt = src[i+1]
                        if nxt == '/':
                                in_line = True
                                i += 2
                                continue
                        if nxt == '*':
                                block_depth = 1
                                i += 2
                                continue

                # Detect string starts (raw and normal)
                # Raw first (r#*" or br#*" patterns)
                pref_len, hashes = raw_string_prefix_len(src, i)
                if pref_len:
                        out.append(src[i:i+pref_len])
                        i += pref_len
                        in_str = True
                        raw_hashes = hashes
                        continue

                if ch == '"':
                        out.append('"')
                        in_str = True
                        raw_hashes = -1
                        i += 1
                        continue

                # Detect small char literal to avoid stripping inside it
                if ch == "'" and is_char_lit(src, i):
                        in_char = True
                        out.append("'")
                        i += 1
                        continue

                # Otherwise, emit as code
                out.append(ch)
                i += 1

        return ''.join(out)

path = sys.argv[1]
with io.open(path, 'r', encoding='utf-8') as f:
        src = f.read()
stripped = strip_comments(src)
tmp = path + '.tmp'
with io.open(tmp, 'w', encoding='utf-8', newline='') as f:
        f.write(stripped)
os.replace(tmp, path)
PYSTRIP
}

process_path() {
    local p="$1"
    if [[ -d "$p" ]]; then
        while IFS= read -r -d '' f; do
            local f_abs
            f_abs=$(resolve_path "$f")
            if is_under_crates "$f_abs"; then
                echo "Processing: $f_abs"
                strip_file "$f_abs"
            else
                echo "Skipping (outside crates): $f_abs" >&2
            fi
        done < <(find "$p" -type f -name '*.rs' -print0)
    elif [[ -f "$p" ]]; then
        local f_abs
        f_abs=$(resolve_path "$p")
        if [[ "$f_abs" == *.rs ]] && is_under_crates "$f_abs"; then
            echo "Processing: $f_abs"
            strip_file "$f_abs"
        else
            echo "Skipping (not a .rs under crates): $f_abs" >&2
        fi
    else
        echo "Warning: path not found: $p" >&2
    fi
}

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        process_path "$arg"
    done
else
    # No args: process all Rust files under crates/
    while IFS= read -r -d '' f; do
        echo "Processing: $f"
        strip_file "$f"
    done < <(find "$CRATES_DIR" -type f -name '*.rs' -print0)
fi

echo "Done removing comments from Rust files under crates/."
