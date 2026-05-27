#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  "${ROOT_DIR}/AGENTS.md"
  "${ROOT_DIR}/docs/README.md"
  "${ROOT_DIR}/docs/status.md"
  "${ROOT_DIR}/docs/gameplay/features.md"
  "${ROOT_DIR}/docs/gameplay/test-plan.md"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "${path}" ]]; then
    echo "missing required doc: ${path}" >&2
    exit 1
  fi
done

echo "docs check passed"
