# Innovation: asset-integration

## Research Summary

The current prototype has clean rule/UI separation but no visual asset layer. The fastest path is to add a data-driven visual registry and skin existing UI controls first. A larger rendering migration to `Node2D` or `TileMapLayer` can follow once the asset contract stabilizes.

## Approach A: Skin Existing UI

### Core Concept

Keep the current `Control`/`Button` UI structure and add textures, icons, and portraits through a visual lookup layer.

### Advantages

- Lowest implementation risk.
- Preserves existing keyboard, mouse, touch, and smoke-test behavior.
- Lets real assets appear quickly across map cells, cards, rewards, and combat enemy panels.
- Easy to keep color/text fallback for missing assets.

### Challenges / Risks

- Exploration remains grid-like and UI-based.
- Animation support is limited.
- Rich map art, y-sort, collision shapes, and layered props remain awkward.

### Compatibility

Fits current `RunScene` with small component extraction.

### Scalability & Maintainability

Good for the next visual milestone, but not a final rendering architecture for a richer action/exploration scene.

## Approach B: Move Exploration To Node2D / TileMapLayer

### Core Concept

Keep combat/reward UI as `Control`, but render the dungeon with `Node2D`, sprites, and eventually `TileMapLayer`.

### Advantages

- Better fit for real maps, animation, y-sort, collision previews, fog, particles, and camera.
- More natural Godot scene architecture for a game view.
- Opens the path to generated layered maps and prop packs.

### Challenges / Risks

- Higher refactor cost.
- Needs careful preservation of current input behavior.
- Scene smoke tests and screenshots need to be updated.

### Compatibility

Core dungeon state can still drive rendering. The migration mainly replaces map-cell UI nodes.

### Scalability & Maintainability

Best long-term if exploration becomes visually rich.

## Approach C: Hybrid Visual Registry First, Map Renderer Later

### Core Concept

Introduce a visual asset registry and reusable card/enemy/map view components now, skin existing UI first, then move only the map layer to `Node2D` after assets and visual ids are stable.

### Advantages

- Gets visible improvement quickly.
- Avoids locking the project into UI-only rendering.
- Keeps asset ids stable when later replacing map rendering.
- Allows card and combat UI work to remain useful after the map renderer changes.

### Challenges / Risks

- Requires discipline to keep registry APIs stable.
- Some map-cell skinning work may be temporary.

### Compatibility

Best fit for the current codebase because it respects the existing rule/UI boundary.

### Scalability & Maintainability

Strong balance between immediate delivery and future rendering needs.

## Comparison Matrix

| Criterion | Approach A: Skin Existing UI | Approach B: Node2D Map | Approach C: Hybrid |
| --- | --- | --- | --- |
| Complexity | Low | High | Medium |
| Risk | Low | Medium-High | Medium |
| Time to deliver | Fast | Slow | Fast initial, scalable later |
| Visual ceiling | Medium | High | High |
| Test impact | Low | Medium | Low then medium |
| Maintainability | Medium | High | High |

## Next Steps

Choose the first milestone scope: full UI skinning, map-renderer migration, or hybrid registry-first rollout.
