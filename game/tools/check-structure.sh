#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_dirs=(
  "${GAME_DIR}/scenes"
  "${GAME_DIR}/scripts/core/cards"
  "${GAME_DIR}/scripts/core/combat"
  "${GAME_DIR}/scripts/core/dungeon"
  "${GAME_DIR}/scripts/core/rewards"
  "${GAME_DIR}/scripts/core/run"
  "${GAME_DIR}/scripts/core"
  "${GAME_DIR}/scripts/board"
  "${GAME_DIR}/scripts/ui"
  "${GAME_DIR}/data"
  "${GAME_DIR}/assets"
  "${GAME_DIR}/test"
  "${GAME_DIR}/test/godot"
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

required_files=(
  "${GAME_DIR}/scenes/start.tscn"
  "${GAME_DIR}/scenes/run.tscn"
  "${GAME_DIR}/scripts/start_screen.gd"
  "${GAME_DIR}/scripts/ui/run_scene.gd"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "${path}" ]]; then
    echo "missing required structure file: ${path}" >&2
    exit 1
  fi
done

echo "structure check passed"
