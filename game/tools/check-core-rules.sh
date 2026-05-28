#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "${GAME_DIR}/scripts/core/cards/card_definition.gd"
  "${GAME_DIR}/scripts/core/cards/card_deck.gd"
  "${GAME_DIR}/scripts/core/cards/starter_card_catalog.gd"
  "${GAME_DIR}/scripts/core/combat/combo_state.gd"
  "${GAME_DIR}/scripts/core/combat/combatant_state.gd"
  "${GAME_DIR}/scripts/core/combat/card_play_result.gd"
  "${GAME_DIR}/scripts/core/combat/combat_state.gd"
  "${GAME_DIR}/scripts/core/dungeon/dungeon_tile.gd"
  "${GAME_DIR}/scripts/core/dungeon/stage_config.gd"
  "${GAME_DIR}/scripts/core/dungeon/stage_fixture_catalog.gd"
  "${GAME_DIR}/scripts/core/dungeon/dungeon_map_state.gd"
  "${GAME_DIR}/scripts/core/rewards/reward_generator.gd"
  "${GAME_DIR}/scripts/core/run/run_state.gd"
  "${GAME_DIR}/scripts/core/run/run_controller.gd"
  "${GAME_DIR}/test/godot/test_reward_core.gd"
  "${GAME_DIR}/test/godot/test_card_combat_core.gd"
  "${GAME_DIR}/test/godot/test_dungeon_core.gd"
  "${GAME_DIR}/test/godot/test_core_gameplay_flow.gd"
  "${GAME_DIR}/test/godot/test_run_scene_smoke.gd"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "${path}" ]]; then
    echo "missing core rules file: ${path}" >&2
    exit 1
  fi
done

echo "core rules scaffold check passed"
