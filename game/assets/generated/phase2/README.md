# Phase 2 Generated Combat Art Pack

This folder contains the second generated sprite pass for combat expression.

## Scope

- Six enemy attack animations.
- Three guard/block animations for enemies that use guard intent.
- One dedicated card FX atlas for high-identity cards.

## Preferred Sheets

| Asset | Preferred sheet | Frames | Notes |
| --- | --- | ---: | --- |
| Grunt attack | `processed/enemy_grunt_attack/sheet-transparent.png` | 6 | One 6-frame dagger attack. |
| Bat attack | `processed/enemy_bat_attack/sheet-transparent.png` | 6 | One 6-frame dive/bite attack. |
| Guard attack | `processed/enemy_guard_attack/sheet-transparent.png` | 6 | One 6-frame spear thrust. |
| Brute attack | `processed/enemy_brute_attack/sheet-transparent.png` | 6 | One 6-frame heavy club swing. |
| Boss guard attack | `processed/enemy_boss_guard_attack/sheet-transparent.png` | 6 | One 6-frame shield/sword attack. |
| Stage boss attack | `processed/enemy_stage_boss_attack/sheet-transparent.png` | 6 | One 6-frame soul-fire cast. |
| Guard guard/block | `processed/enemy_guard_guard/sheet-transparent.png` | 4 | One 4-frame shield brace. |
| Brute guard/block | `processed/enemy_brute_guard/sheet-transparent.png` | 4 | One 4-frame heavy brace. |
| Boss guard guard/block | `processed/enemy_boss_guard_guard/sheet-transparent.png` | 4 | One 4-frame tower-shield brace. |
| Dedicated card FX | `processed/dedicated_card_fx_atlas/sheet-transparent.png` | 24 | Row order: whip, king bible, garlic, santa water, pentagram, lightning ring. |

## QC Notes

- No edge-touch warnings: `enemy_grunt_attack`, `enemy_bat_attack`, `enemy_brute_attack`, `enemy_guard_guard`, `enemy_brute_guard`, `enemy_boss_guard_guard`.
- Minor edge-touch warnings: `enemy_guard_attack` (1), `enemy_boss_guard_attack` (1), `enemy_stage_boss_attack` (2), `dedicated_card_fx_atlas` (6).
- Sheets with warnings are still usable as a first combat pass, but should be reviewed before wiring into final runtime effects.

## Runtime Mapping

- Attack sheets: frames 1-6 are a single `attack` animation.
- Guard sheets: frames 1-4 are a single `guard` animation.
- Dedicated card FX atlas:
  - frames 1-4: `whip_sweep`
  - frames 5-8: `king_bible_orbit`
  - frames 9-12: `garlic_aura`
  - frames 13-16: `santa_water_splash`
  - frames 17-20: `pentagram_burst`
  - frames 21-24: `lightning_ring_strike`
