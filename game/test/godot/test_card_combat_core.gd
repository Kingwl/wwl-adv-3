extends SceneTree

const CardDeck = preload("res://scripts/core/cards/card_deck.gd")
const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const ComboState = preload("res://scripts/core/combat/combo_state.gd")


func _init() -> void:
	var failed := false
	failed = not _test_combo_resets_when_cost_drops() or failed
	failed = not _test_deck_shuffle_is_seeded() or failed
	failed = not _test_combat_applies_combo_damage_and_block() or failed
	failed = not _test_enemy_rows_only_front_attacks_and_rear_waits_after_advancing() or failed
	failed = not _test_enemy_rows_are_capped_at_five_enemies() or failed
	failed = not _test_stage_1_reward_pool_is_stable_and_chinese() or failed
	failed = not _test_reward_cards_are_simple_categories() or failed
	quit(1 if failed else 0)


func _test_combo_resets_when_cost_drops() -> bool:
	var combo := ComboState.new()
	var strike = StarterCardCatalog.create_strike()
	var bolt = StarterCardCatalog.create_bolt()
	var guard = StarterCardCatalog.create_guard()

	var ok := true
	ok = _assert_eq(combo.apply_card(strike), 100, "first card has base multiplier") and ok
	ok = _assert_eq(combo.apply_card(bolt), 200, "higher cost extends combo") and ok
	ok = _assert_eq(combo.apply_card(guard), 100, "lower cost resets combo") and ok
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
	combat.enemies = [CombatantState.new("slime", "Slime", 30, 3)]
	combat.mana = 5
	combat.max_mana = 5
	combat.deck.hand = [
		StarterCardCatalog.create_guard(),
		StarterCardCatalog.create_strike(),
		StarterCardCatalog.create_bolt(),
	]

	var guard_result = combat.play_card(0)
	var strike_result = combat.play_card(0, 0)
	var bolt_result = combat.play_card(0, 0)

	var ok := true
	ok = _assert_eq(guard_result.block_gained, 5, "guard grants block") and ok
	ok = _assert_eq(strike_result.damage_requested, 12, "second combo card scales strike") and ok
	ok = _assert_eq(bolt_result.damage_requested, 27, "third combo card scales bolt") and ok
	ok = _assert_eq(combat.enemies[0].health, 0, "enemy loses scaled damage") and ok
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
	combat.enemies = [CombatantState.new("enemy_a", "敌人甲", 100, 0)]
	combat.mana = 6
	combat.max_mana = 6
	combat.deck.hand = [
		StarterCardCatalog.create_insight(),
		StarterCardCatalog.create_block(),
		StarterCardCatalog.create_slash(),
		StarterCardCatalog.create_heavy_hammer(),
	]
	combat.deck.draw_pile = [StarterCardCatalog.create_charged_slash(), StarterCardCatalog.create_iron_wall()]

	var insight_result = combat.play_card(0)
	var block_result = combat.play_card(0)
	var slash_result = combat.play_card(0, 0)
	var hammer_result = combat.play_card(0, 0)

	var ok := true
	ok = _assert_eq(insight_result.cards_drawn, 2, "insight draws") and ok
	ok = _assert_eq(block_result.block_gained, 8, "block grants block") and ok
	ok = _assert_eq(slash_result.damage_dealt, 24, "slash deals combo damage") and ok
	ok = _assert_eq(hammer_result.damage_dealt, 72, "hammer deals combo damage") and ok
	return ok


func _card_ids(cards: Array) -> Array:
	var ids: Array = []
	for card in cards:
		ids.append(card.id)
	return ids


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
