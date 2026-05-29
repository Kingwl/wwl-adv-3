# Phase 4 Generated Attack Card FX

This folder contains generated 2D VFX sprite sheets for attack cards that did not yet have dedicated runtime effects.

## Scope

- 11 attack-card VFX sheets generated with `zero generate sprite` guidance and built-in image generation.
- Each card uses a separate 2x2, 4-frame raw sheet before processing.
- Existing Phase 2 dedicated effects remain in use for `whip`, `king_bible`, `garlic`, `santa_water`, `pentagram`, and `lightning_ring`.

## Generated Sheets

| Card | Preferred sheet | Frames | Visual direction |
| --- | --- | ---: | --- |
| Magic Wand | `processed/magic_wand_fx/sheet-transparent.png` | 4 | Blue-white wand orb and star impact. |
| Knife | `processed/knife_fx/sheet-transparent.png` | 4 | Silver throwing-knife barrage. |
| Axe | `processed/axe_fx/sheet-transparent.png` | 4 | Heavy spinning axe arc. |
| Cross | `processed/cross_fx/sheet-transparent.png` | 4 | Gold holy cross boomerang. |
| Fire Wand | `processed/fire_wand_fx/sheet-transparent.png` | 4 | Fireball trail and explosion. |
| Runetracer | `processed/runetracer_fx/sheet-transparent.png` | 4 | Cyan angular rune ricochet. |
| Peachone | `processed/peachone_fx/sheet-transparent.png` | 4 | White feather bullet fan. |
| Ebony Wings | `processed/ebony_wings_fx/sheet-transparent.png` | 4 | Black-purple feather blades. |
| Song of Mana | `processed/song_of_mana_fx/sheet-transparent.png` | 4 | Blue-violet musical wave pulse. |
| Bone | `processed/bone_fx/sheet-transparent.png` | 4 | Tumbling bone ricochet. |
| Cherry Bomb | `processed/cherry_bomb_fx/sheet-transparent.png` | 4 | Red-pink cherry bomb burst. |

## QC Notes

- All processed sheets have 4 frames.
- No processed frame has edge-touch warnings after regenerating `song_of_mana_fx`.
- Runtime loads these via `VisualAssetCatalog.card_attack_fx_texture()`.
