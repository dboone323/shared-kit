#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

echo "Configuring git hooks path..."
git config core.hooksPath .githooks

echo "Checking required tools..."
for tool in swiftformat swiftlint; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "  - $tool: installed"
  else
    echo "  - $tool: missing"
  fi
done

echo "Development environment setup complete."
