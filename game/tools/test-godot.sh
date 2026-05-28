#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

tests=(
  "test/godot/test_card_combat_core.gd"
  "test/godot/test_dungeon_core.gd"
  "test/godot/test_core_gameplay_flow.gd"
  "test/godot/test_run_scene_smoke.gd"
)

for test_path in "${tests[@]}"; do
  echo "running ${test_path}"
  "${GODOT_BIN}" --headless --path "${GAME_DIR}" -s "res://${test_path}"
done

echo "all Godot headless tests passed"
