# Phase 5 Enemy Attack And Player Hit FX

This folder contains generated 2D VFX sprite sheets for enemy attacks and player hurt feedback.

## Scope

- Six enemy attack VFX sheets, one per combat enemy visual id.
- One player hurt impact VFX sheet.
- Each sheet uses a separate 2x2, 4-frame raw image before processing.

## Generated Sheets

| Asset | Preferred sheet | Frames | Visual direction |
| --- | --- | ---: | --- |
| Grunt attack FX | `processed/enemy_grunt_attack_fx/sheet-transparent.png` | 4 | Rusty dagger slash, dust, and red-orange hit spark. |
| Bat attack FX | `processed/enemy_bat_attack_fx/sheet-transparent.png` | 4 | Purple wing slash and bite impact. |
| Guard attack FX | `processed/enemy_guard_attack_fx/sheet-transparent.png` | 4 | Blue-gray spear thrust and shield shock. |
| Brute attack FX | `processed/enemy_brute_attack_fx/sheet-transparent.png` | 4 | Heavy club arc, debris, and ground crack. |
| Boss guard attack FX | `processed/enemy_boss_guard_attack_fx/sheet-transparent.png` | 4 | Dark steel slash with crimson shield flare. |
| Stage boss attack FX | `processed/enemy_stage_boss_attack_fx/sheet-transparent.png` | 4 | Purple-black soul-fire and spectral impact. |
| Player hurt FX | `processed/player_hurt_fx/sheet-transparent.png` | 4 | Red-white hit flash, crack lines, and fading sparks. |

## QC Notes

- All processed sheets have 4 frames.
- No processed frame has edge-touch warnings.
- Runtime loads enemy attack effects via `VisualAssetCatalog.enemy_attack_fx_texture()`.
- Runtime loads player hurt effects via `VisualAssetCatalog.player_hurt_fx_texture()`.
