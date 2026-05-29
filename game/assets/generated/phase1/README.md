# Phase 1 Generated Art Pack

This folder contains the first generated sprite pass for the playable prototype.

## Preferred Sheets

Use the processed transparent sheets first:

| Asset | Preferred sheet | Frames | Notes |
| --- | --- | ---: | --- |
| Hero 4-direction walk | `processed/hero_walk_4dir_v2/sheet-transparent.png` | 16 | Row order: down, left, right, up; 4 frames per direction. |
| Grunt combat | `processed/enemy_grunt_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Bat combat | `processed/enemy_bat_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Guard combat | `processed/enemy_guard_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Brute combat | `processed/enemy_brute_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Boss guard combat | `processed/enemy_boss_guard_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Stage boss combat | `processed/enemy_stage_boss_combat/sheet-transparent.png` | 12 | Row order: idle, hurt, death; 4 frames per row. |
| Shared card FX | `processed/card_fx_atlas/sheet-transparent.png` | 24 | Row order: projectile, impact, front sweep, random strike, bounce rune, full burst. |
| Pickups and exits | `processed/pickups_exit_pack/sheet-transparent.png` | 9 | Row-major: treasure, healing, XP gem, forge, shrine, hazard, locked exit, open exit, entrance. |

## Raw Sources

Raw generated images are under `raw/`. The original image-generation outputs were left in the Codex generated image cache as well.

## QC Notes

- `enemy_grunt_combat`, `enemy_brute_combat`, and `pickups_exit_pack` had no edge-touch warnings in the local processor metadata.
- `hero_walk_4dir_v2` is preferred over `hero_walk_4dir`; it reduced edge-touch warnings from 8 to 4 and is visually usable as a first pass.
- `enemy_bat_combat`, `enemy_guard_combat`, `enemy_boss_guard_combat`, `enemy_stage_boss_combat`, and `card_fx_atlas` are usable draft sheets, but several frames touch or approach generated cell edges. Review them before final integration.
- For production integration, regenerate warning sheets with stricter layout guides or split them into smaller per-action sheets.

## Runtime Mapping

Suggested action mapping:

- Combat enemy sheets: frames 1-4 `idle`, 5-8 `hurt`, 9-12 `death`.
- Hero walk sheet: frames 1-4 `walk_down`, 5-8 `walk_left`, 9-12 `walk_right`, 13-16 `walk_up`.
- Shared FX sheet: frames 1-4 `single_projectile`, 5-8 `single_impact`, 9-12 `front_row_sweep`, 13-16 `random_strike`, 17-20 `bounce_projectile`, 21-24 `all_screen_burst`.
