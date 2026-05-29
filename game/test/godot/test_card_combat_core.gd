extends SceneTree

const CardDeck = preload("res://scripts/core/cards/card_deck.gd")
const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const ComboState = preload("res://scripts/core/combat/combo_state.gd")
const EnemyCatalog = preload("res://scripts/core/combat/enemy_catalog.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")


func _init() -> void:
	var failed := false
	failed = not _test_combo_requires_next_cost_step() or failed
	failed = not _test_deck_shuffle_is_seeded() or failed
	failed = not _test_combat_applies_combo_damage_and_block() or failed
	failed = not _test_enemy_catalog_defines_first_roles() or failed
	failed = not _test_run_controller_uses_enemy_role_rows() or failed
	failed = not _test_enemy_guard_block_is_personal_and_refreshes() or failed
	failed = not _test_enemy_rows_only_front_attacks_and_rear_waits_after_advancing() or failed
	failed = not _test_primary_target_prioritizes_ready_attacker() or failed
	failed = not _test_primary_target_prioritizes_highest_attack_threat() or failed
	failed = not _test_enemy_rows_are_capped_at_five_enemies() or failed
	failed = not _test_stage_1_reward_pool_is_stable_and_chinese() or failed
	failed = not _test_reward_cards_are_simple_categories() or failed
	quit(1 if failed else 0)


func _test_combo_requires_next_cost_step() -> bool:
	var combo := ComboState.new()
	var focus = StarterCardCatalog.create_focus()
	var strike = StarterCardCatalog.create_strike()
	var bolt = StarterCardCatalog.create_bolt()
	var guard = StarterCardCatalog.create_guard()
	var hammer = StarterCardCatalog.create_heavy_hammer()

	var ok := true
	ok = _assert_eq(combo.apply_card(focus), 100, "first card has base multiplier") and ok
	ok = _assert_eq(combo.apply_card(strike), 200, "next cost step extends combo") and ok
	ok = _assert_eq(combo.apply_card(bolt), 300, "second next cost step extends combo") and ok
	ok = _assert_eq(combo.preview_multiplier_basis_points(hammer), 400, "exact next higher cost previews combo") and ok
	ok = _assert_eq(combo.preview_multiplier_basis_points(guard), 100, "same cost resets combo") and ok
	ok = _assert_eq(combo.preview_multiplier_basis_points(focus), 100, "lower cost resets combo") and ok
	ok = _assert_eq(combo.apply_card(hammer), 400, "exact next higher cost applies combo") and ok
	ok = _assert_eq(combo.apply_card(guard), 100, "non-next cost resets combo") and ok
	ok = _assert_eq(combo.chain, 1, "reset combo chain") and ok
	return ok


func _test_deck_shuffle_is_seeded() -> bool:
	var cards := StarterCardCatalog.create_starter_deck()
	var first_deck := CardDeck.new()
	var second_deck := CardDeck.new()
	first_deck.setup(cards, 77)
	second_deck.setup(cards, 77)

	var first_draw := _card_ids(first_deck.draw(5))
	var second_draw := _card_ids(second_deck.draw(5))
	return _assert_eq(first_draw, second_draw, "same seed draws same opening hand")


func _test_combat_applies_combo_damage_and_block() -> bool:
	var combat := CombatState.new()
	combat.player = CombatantState.new("hero", "Hero", 20, 0)
	combat.enemies = [CombatantState.new("slime", "Slime", 50, 3)]
	combat.mana = 5
	combat.max_mana = 5
	combat.deck.hand = [
		StarterCardCatalog.create_focus(),
		StarterCardCatalog.create_strike(),
		StarterCardCatalog.create_bolt(),
		StarterCardCatalog.create_guard(),
	]

	var focus_result = combat.play_card(0)
	var strike_result = combat.play_card(0, 0)
	var bolt_result = combat.play_card(0, 0)
	var guard_result = combat.play_card(0)

	var ok := true
	ok = _assert_eq(focus_result.ok, true, "focus can start combo") and ok
	ok = _assert_eq(guard_result.block_gained, 5, "guard grants block") and ok
	ok = _assert_eq(strike_result.damage_requested, 12, "second combo card scales strike") and ok
	ok = _assert_eq(bolt_result.damage_requested, 27, "third combo card scales bolt") and ok
	ok = _assert_eq(combat.enemies[0].health, 11, "enemy loses scaled damage") and ok
	return ok


func _test_enemy_catalog_defines_first_roles() -> bool:
	var grunt := EnemyCatalog.create_enemy("grunt_a", EnemyCatalog.ID_GRUNT)
	var bat := EnemyCatalog.create_enemy("bat_a", EnemyCatalog.ID_BAT)
	var guard := EnemyCatalog.create_enemy("guard_a", EnemyCatalog.ID_GUARD)
	var brute := EnemyCatalog.create_enemy("brute_a", EnemyCatalog.ID_BRUTE)

	var ok := true
	ok = _assert_eq(grunt.display_name, "走卒", "grunt display name") and ok
	ok = _assert_eq(grunt.max_health, 12, "grunt health") and ok
	ok = _assert_eq(grunt.attack_damage, 4, "grunt attack") and ok
	ok = _assert_eq(bat.display_name, "刺蝠", "bat display name") and ok
	ok = _assert_eq(bat.max_health, 8, "bat health") and ok
	ok = _assert_eq(bat.attack_damage, 6, "bat attack") and ok
	ok = _assert_eq(guard.display_name, "盾卫", "guard display name") and ok
	ok = _assert_eq(guard.guard_block, 5, "guard block intent") and ok
	ok = _assert_eq(brute.display_name, "重甲兵", "brute display name") and ok
	ok = _assert_eq(brute.max_health, 24, "brute health") and ok
	ok = _assert_eq(brute.guard_block, 6, "brute block intent") and ok
	return ok


func _test_run_controller_uses_enemy_role_rows() -> bool:
	var controller := RunController.new()
	controller.setup(11)
	controller.start_stage_1()

	var first_rows := controller.create_enemy_rows_for_tile(DungeonTile.new(DungeonTile.TileType.ENEMY, "enemy_01"))
	var guard_rows := controller.create_enemy_rows_for_tile(DungeonTile.new(DungeonTile.TileType.ENEMY, "enemy_03"))
	var elite_rows := controller.create_enemy_rows_for_tile(DungeonTile.new(DungeonTile.TileType.ELITE, "elite_01"))
	var boss_rows := controller.create_enemy_rows_for_tile(DungeonTile.new(DungeonTile.TileType.BOSS, "boss_01"))
	controller.run_state.start_stage_2()
	var stage_two_rows := controller.create_enemy_rows_for_tile(DungeonTile.new(DungeonTile.TileType.ENEMY, "enemy_01"))

	var ok := true
	ok = _assert_eq(_enemy_names(first_rows[0]), ["走卒"], "stage 1 first front row") and ok
	ok = _assert_eq(_enemy_names(first_rows[1]), ["走卒"], "stage 1 first rear row") and ok
	ok = _assert_eq(_enemy_names(guard_rows[0]), ["盾卫"], "stage 1 guard teaching front row") and ok
	ok = _assert_eq(_enemy_names(elite_rows[0]), ["重甲兵", "盾卫"], "stage 1 elite front row") and ok
	ok = _assert_eq(_enemy_names(boss_rows[0]), ["首领护卫", "首领护卫"], "stage 1 boss guard row") and ok
	ok = _assert_eq(_enemy_names(stage_two_rows[0]), ["盾卫", "刺蝠"], "stage 2 first front row") and ok
	ok = _assert_eq(_enemy_names(stage_two_rows[1]), ["走卒"], "stage 2 first rear row") and ok
	return ok


func _test_enemy_guard_block_is_personal_and_refreshes() -> bool:
	var combat := CombatState.new()
	combat.setup(
		CombatantState.new("hero", "英雄", 40, 0),
		[],
		[[
			CombatantState.new("guard", "盾卫", 20, 2, -1, 5),
			CombatantState.new("striker", "敌人", 20, 4),
		]],
		21,
		3,
		0
	)

	var first_damage := combat.end_player_turn()
	var second_damage := combat.end_player_turn()
	var guard_block_after_guard_turn: int = combat.enemies[0].block
	var guard_intent := combat.enemy_intent_for(combat.enemies[0])
	var striker_intent := combat.enemy_intent_for(combat.enemies[1])
	combat.deck.hand = [
		CardDefinition.new("poke", "轻击", 1, 2, 0, 0, CardDefinition.TargetMode.SINGLE_ENEMY),
	]
	combat.mana = 3
	var poke_result = combat.play_card(0, 0)
	var guard_block_after_poke: int = combat.enemies[0].block
	var striker_block_after_poke: int = combat.enemies[1].block
	var guard_health_after_poke: int = combat.enemies[0].health
	var third_damage := combat.end_player_turn()

	var ok := true
	ok = _assert_eq(first_damage, 6, "shield enemy attacks on its first ready turn") and ok
	ok = _assert_eq(second_damage, 4, "shield enemy guards instead of attacking on alternating turn") and ok
	ok = _assert_eq(guard_block_after_guard_turn, 5, "shield enemy gains its own block") and ok
	ok = _assert_eq(combat.enemies[0].block, 0, "enemy block refreshes at the next enemy turn") and ok
	ok = _assert_eq(third_damage, 6, "shield enemy attacks again after guard turn") and ok
	ok = _assert_eq(str(guard_intent.get("type", "")), CombatState.ENEMY_INTENT_ATTACK, "guard intends to attack after guarding") and ok
	ok = _assert_eq(str(striker_intent.get("type", "")), CombatState.ENEMY_INTENT_ATTACK, "non-shield enemy intends to attack") and ok
	ok = _assert_eq(poke_result.damage_dealt, 0, "target shield absorbs small damage") and ok
	ok = _assert_eq(guard_block_after_poke, 3, "target shield is reduced by damage") and ok
	ok = _assert_eq(striker_block_after_poke, 0, "other enemies do not share the target shield") and ok
	ok = _assert_eq(guard_health_after_poke, 20, "shield prevents health damage") and ok
	return ok


func _test_enemy_rows_only_front_attacks_and_rear_waits_after_advancing() -> bool:
	var combat := CombatState.new()
	combat.setup(
		CombatantState.new("hero", "英雄", 30, 0),
		[],
		[
			[CombatantState.new("front", "前排", 3, 4)],
			[CombatantState.new("rear", "后排", 8, 7)],
		],
		12,
		3,
		0
	)
	combat.deck.hand = [StarterCardCatalog.create_strike()]

	var play_result := combat.play_card(0, combat.primary_target_index())
	var front_after_kill: Array = combat.front_row_enemies()
	var can_advanced_enemy_attack_now := false
	if front_after_kill.size() > 0:
		can_advanced_enemy_attack_now = combat.can_enemy_attack(front_after_kill[0])
	var damage_on_advance_turn := combat.end_player_turn()
	var damage_next_turn := combat.end_player_turn()

	var ok := true
	ok = _assert_eq(play_result.defeated_enemy_ids, ["front"], "front enemy is defeated first") and ok
	ok = _assert_eq(front_after_kill.size(), 1, "rear advances into front row") and ok
	if front_after_kill.size() > 0:
		ok = _assert_eq(front_after_kill[0].id, "rear", "rear is now the front target") and ok
		ok = _assert_eq(can_advanced_enemy_attack_now, false, "newly advanced enemy waits this turn") and ok
	ok = _assert_eq(damage_on_advance_turn, 0, "newly advanced enemy does not attack immediately") and ok
	ok = _assert_eq(damage_next_turn, 7, "advanced enemy attacks on the next enemy turn") and ok
	return ok


func _test_primary_target_prioritizes_ready_attacker() -> bool:
	var combat := CombatState.new()
	combat.setup(
		CombatantState.new("hero", "英雄", 30, 0),
		[],
		[[
			CombatantState.new("waiting", "待命敌人", 8, 2),
			CombatantState.new("ready", "攻击敌人", 8, 5),
		]],
		14,
		3,
		0
	)
	combat.enemy_front_turns[combat.enemies[0].get_instance_id()] = combat.turn
	combat.enemy_front_turns[combat.enemies[1].get_instance_id()] = combat.turn - 1

	var ok := true
	ok = _assert_eq(combat.can_enemy_attack(combat.enemies[0]), false, "waiting enemy cannot attack this turn") and ok
	ok = _assert_eq(combat.can_enemy_attack(combat.enemies[1]), true, "ready enemy can attack this turn") and ok
	ok = _assert_eq(combat.primary_target_index(), 1, "primary target is the ready attacker") and ok
	return ok


func _test_primary_target_prioritizes_highest_attack_threat() -> bool:
	var combat := CombatState.new()
	combat.setup(
		CombatantState.new("hero", "英雄", 30, 0),
		[],
		[[
			EnemyCatalog.create_enemy("guard", EnemyCatalog.ID_GUARD),
			EnemyCatalog.create_enemy("bat", EnemyCatalog.ID_BAT),
		]],
		17,
		3,
		0
	)

	var ok := true
	ok = _assert_eq(combat.can_enemy_attack(combat.enemies[0]), true, "guard is attacking on first ready turn") and ok
	ok = _assert_eq(combat.can_enemy_attack(combat.enemies[1]), true, "bat is attacking on first ready turn") and ok
	ok = _assert_eq(combat.primary_target_index(), 1, "primary target is highest attack threat") and ok
	return ok


func _test_enemy_rows_are_capped_at_five_enemies() -> bool:
	var row: Array = []
	for i in range(6):
		row.append(CombatantState.new("enemy_%s" % i, "敌人", 5, 1))

	var combat := CombatState.new()
	combat.setup(CombatantState.new("hero", "英雄", 30, 0), [], [row], 13, 3, 0)
	var rows := combat.living_enemy_rows()

	var ok := true
	ok = _assert_eq(rows.size(), 2, "oversized enemy row splits into two rows") and ok
	if rows.size() == 2:
		ok = _assert_eq(rows[0].size(), CombatState.MAX_ENEMIES_PER_ROW, "front row is capped at five") and ok
		ok = _assert_eq(rows[1].size(), 1, "overflow enemy moves to next row") and ok
	return ok


func _test_stage_1_reward_pool_is_stable_and_chinese() -> bool:
	var cards := StarterCardCatalog.create_stage_1_reward_pool()
	var ids := {}

	var ok := true
	ok = _assert_eq(cards.size(), 7, "stage 1 reward pool size") and ok
	for card in cards:
		ok = _assert_eq(ids.has(card.id), false, "reward card id is unique") and ok
		ok = _assert_eq(_string_has_english(card.display_name), false, "reward card display name uses Chinese") and ok
		ids[card.id] = true
	return ok


func _test_reward_cards_are_simple_categories() -> bool:
	var cards := StarterCardCatalog.create_stage_1_reward_pool()

	var attack_count := 0
	var defense_count := 0
	var draw_count := 0
	var ok := true
	for card in cards:
		var has_damage: bool = card.base_damage > 0
		var has_block: bool = card.block > 0
		var has_draw: bool = card.draw_count > 0
		var effect_count := int(has_damage) + int(has_block) + int(has_draw)
		ok = _assert_eq(effect_count, 1, "reward card has exactly one simple effect") and ok
		if has_damage:
			attack_count += 1
			ok = _assert_eq(card.target_mode, CardDefinition.TargetMode.SINGLE_ENEMY, "attack card is single target") and ok
		if has_block:
			defense_count += 1
			ok = _assert_eq(card.target_mode, CardDefinition.TargetMode.SELF, "defense card targets self") and ok
		if has_draw:
			draw_count += 1
			ok = _assert_eq(card.target_mode, CardDefinition.TargetMode.SELF, "draw card targets self") and ok

	ok = _assert_eq(attack_count, 4, "reward pool attack count") and ok
	ok = _assert_eq(defense_count, 2, "reward pool defense count") and ok
	ok = _assert_eq(draw_count, 1, "reward pool draw count") and ok
	ok = _test_simple_reward_cards_resolve() and ok
	return ok


func _test_simple_reward_cards_resolve() -> bool:
	var combat := CombatState.new()
	combat.player = CombatantState.new("hero", "英雄", 30, 0)
	combat.enemies = [CombatantState.new("enemy_a", "敌人甲", 120, 0)]
	combat.mana = 6
	combat.max_mana = 6
	combat.deck.hand = [
		StarterCardCatalog.create_insight(),
		StarterCardCatalog.create_block(),
		StarterCardCatalog.create_charged_slash(),
		StarterCardCatalog.create_heavy_hammer(),
	]
	combat.deck.draw_pile = [StarterCardCatalog.create_slash(), StarterCardCatalog.create_iron_wall()]

	var insight_result = combat.play_card(0)
	var block_result = combat.play_card(0)
	var charged_result = combat.play_card(0, 0)
	var hammer_result = combat.play_card(0, 0)

	var ok := true
	ok = _assert_eq(insight_result.cards_drawn, 2, "insight draws") and ok
	ok = _assert_eq(block_result.block_gained, 8, "block grants block") and ok
	ok = _assert_eq(charged_result.damage_dealt, 36, "charged slash deals combo damage") and ok
	ok = _assert_eq(hammer_result.damage_dealt, 72, "hammer deals combo damage") and ok
	return ok


func _card_ids(cards: Array) -> Array:
	var ids: Array = []
	for card in cards:
		ids.append(card.id)
	return ids


func _enemy_names(enemies: Array) -> Array:
	var names: Array = []
	for enemy in enemies:
		names.append(enemy.display_name)
	return names


func _assert_eq(actual, expected, label: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return false
	return true


func _string_has_english(value: String) -> bool:
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false
