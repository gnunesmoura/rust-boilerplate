#!/usr/bin/env bash
set -euo pipefail

# Simplified setup script: all tooling (rustup, toolchains, cargo-audit,
# cargo-llvm-cov, pre-commit) is pre-installed in the development/CI
# Docker image or expected developer environment. This script now only:
# 1. Verifies availability
# 2. Installs / refreshes the pre-commit git hooks
# 3. Prints versions for quick diagnostics

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[setup-dev] Repo root: $ROOT_DIR"

missing=0
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[setup-dev][missing] $1 not found in PATH" >&2
    missing=1
  else
    echo "[setup-dev][ok] $1: $(command -v "$1")"
  fi
}

echo "[setup-dev] Verifying required commands"
need git
need rustup
need cargo
need pre-commit
need python3
need clang
need lld
need cargo-audit
need cargo-llvm-cov || true

if [ $missing -eq 1 ]; then
  echo "[setup-dev][fail] Missing required tooling. Ensure you are using the provided dev container / runner image." >&2
  exit 1
fi

echo "[setup-dev] Installing / updating pre-commit hooks"
pre-commit install --install-hooks --overwrite

echo "[setup-dev] Tool versions:" 
rustc --version || true
cargo --version || true
rustup show active-toolchain || true
clang --version | head -n1 || true
lldb --version 2>/dev/null | head -n1 || true
cargo audit --version || true
cargo llvm-cov --version || echo "(cargo-llvm-cov optional)"
pre-commit --version || true

echo "[setup-dev] Done."
exit 0
