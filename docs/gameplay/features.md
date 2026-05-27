# Gameplay Features

## Direction

`wwl大冒险3` is a 2D roguelite deck-crawler. The first prototype focuses on
grid dungeon exploration, card-driven combat, combo scaling, run rewards, and
lightweight long-term progression.

## Implemented

- Card definitions with id, display name, mana cost, damage, block, draw count,
  and target mode.
- Seeded deck setup, shuffle, draw, hand, and discard piles.
- Combo state where non-decreasing mana costs extend the chain; lower-cost cards
  reset it.
- Integer combo multipliers in basis points, starting at 100 and adding 25 per
  extra chain step.
- Combatant state with health, block, incoming damage absorption, and defeat.
- Combat state for player turn setup, card play validation, card effects, enemy
  turn damage, victory, and defeat.
- Starter deck catalog with Strike, Bolt, Guard, and Focus.

## Planned

- 2D dungeon grid, rooms, encounters, treasure, and boss nodes.
- Card rewards and card upgrade rules.
- Relics or passive modifiers.
- Scene adapter for playable hand, enemies, and dungeon movement.
