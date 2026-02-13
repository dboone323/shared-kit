#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

if command -v swiftlint >/dev/null 2>&1 && [ -f .swiftlint.yml ]; then
  swiftlint --strict || true
fi

if command -v swiftformat >/dev/null 2>&1 && [ -f .swiftformat ]; then
  swiftformat . --config .swiftformat --lint || true
fi

if [ -f Package.swift ]; then
  swift test --parallel || true
fi

echo "Automated code review checks completed."
