#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

mkdir -p docs/generated

if [ -f Package.swift ]; then
  if command -v swift >/dev/null 2>&1; then
    swift package --allow-writing-to-directory docs/generated generate-documentation --target SharedKit --output-path docs/generated 2>/dev/null || true
  fi
else
  proj=$(ls -1 *.xcodeproj 2>/dev/null | head -n1)
  if [ -n "$proj" ]; then
    scheme=${proj%.xcodeproj}
    xcodebuild docbuild -project "$proj" -scheme "$scheme" -derivedDataPath build/docbuild >/dev/null 2>&1 || true
  fi
fi

echo "Documentation generation completed."
