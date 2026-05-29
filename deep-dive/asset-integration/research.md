# Research: asset-integration

## Scope

Investigated how the current Godot prototype renders map, combat enemies, cards, rewards, and assets so real art can be introduced without destabilizing core rules.

## Findings

### Architecture

- `game/scripts/ui/run_scene.gd` builds the active run UI programmatically.
- Exploration uses a `GridContainer` of `Button` cells. Each cell is styled with `StyleBoxFlat` colors and a single Chinese text marker.
- Combat enemies are rendered as `PanelContainer` cards containing labels for name, HP, block, attack, and intent.
- Hand cards and reward cards are rendered as large text `Button` controls with colored backgrounds based on attack, defense, or draw category.
- The rule layer is separated from UI: dungeon movement, card combat, rewards, and encounter generation live under `game/scripts/core/`.
- `game/assets/` currently contains only the Chinese font assets plus `.gitkeep`; no gameplay sprites, portraits, card art, icons, tiles, or backgrounds exist yet.

### Dependencies

- Godot 4.6.3 is the active runtime.
- Existing tests focus on rule behavior and one scene smoke test.
- No external art-loading framework or resource registry exists yet.

### Constraints

- `DungeonTile` carries tile type and occupant id, which is enough for tile and pickup visuals.
- `CardDefinition` carries card id and display data, which is enough for card art lookup.
- `CombatantState` carries runtime id and display name, but does not preserve the source enemy catalog id after `EnemyCatalog.create_enemy()`. Enemy visuals need a stable visual id or catalog id to avoid brittle lookup from display names.
- The current exploration map is UI-grid based, not a `TileMapLayer`/`Node2D` scene.
- Current visual constants assume 48x48 map cells, 150x170 hand cards, 220x240 reward choices, and 150x134 enemy panels.

### Data Flow

- `StageFixtureCatalog` defines maps as string rows.
- `DungeonMapState` converts markers into `DungeonTile` instances.
- `RunController` creates encounters from tiles and builds `CombatState`.
- `RunScene` reads `run_state`, `DungeonTile`, `CombatState`, `CardDefinition`, and `CombatantState` to rebuild visible UI.

## Open Questions

- Should the first real-art pass be pixel-art, clean HD illustration, or a hybrid?
- Are real assets already available, or should they be generated through the sprite/map skills?
- Should exploration stay as a UI grid for the next milestone, or should map rendering move to `Node2D`/`TileMapLayer` soon?
