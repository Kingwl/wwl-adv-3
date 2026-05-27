# Gameplay Test Plan

## Current Coverage

- `game/test/godot/test_card_combat_core.gd` covers combo reset, seeded deck
  determinism, and card combat damage/block outcomes.
- `game/tools/check-core-rules.sh` verifies that the core rule files and Godot
  test entry exist while the scaffold is still lightweight.

## Next Coverage

- Add a Godot headless runner to CI once Godot is installed in the project gate.
- Add focused tests for invalid card plays: missing mana, invalid hand index,
  defeated target, and empty deck.
- Add dungeon map tests before implementing scene movement.
