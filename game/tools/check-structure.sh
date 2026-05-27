#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_dirs=(
  "${GAME_DIR}/scenes"
  "${GAME_DIR}/scripts/core"
  "${GAME_DIR}/scripts/board"
  "${GAME_DIR}/scripts/ui"
  "${GAME_DIR}/data"
  "${GAME_DIR}/assets"
  "${GAME_DIR}/test"
  "${GAME_DIR}/tools"
)

for path in "${required_dirs[@]}"; do
  if [[ ! -d "${path}" ]]; then
    echo "missing required directory: ${path}" >&2
    exit 1
  fi
done

if [[ ! -f "${GAME_DIR}/project.godot" ]]; then
  echo "missing Godot project: ${GAME_DIR}/project.godot" >&2
  exit 1
fi

echo "structure check passed"
