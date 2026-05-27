extends SceneTree

const CardDeck = preload("res://scripts/core/cards/card_deck.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const ComboState = preload("res://scripts/core/combat/combo_state.gd")


func _init() -> void:
	var failed := false
	failed = not _test_combo_resets_when_cost_drops() or failed
	failed = not _test_deck_shuffle_is_seeded() or failed
	failed = not _test_combat_applies_combo_damage_and_block() or failed
	quit(1 if failed else 0)


func _test_combo_resets_when_cost_drops() -> bool:
	var combo := ComboState.new()
	var strike = StarterCardCatalog.create_strike()
	var bolt = StarterCardCatalog.create_bolt()
	var guard = StarterCardCatalog.create_guard()

	var ok := true
	ok = _assert_eq(combo.apply_card(strike), 100, "first card has base multiplier") and ok
	ok = _assert_eq(combo.apply_card(bolt), 125, "higher cost extends combo") and ok
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
	ok = _assert_eq(strike_result.damage_requested, 7, "second combo card scales strike") and ok
	ok = _assert_eq(bolt_result.damage_requested, 13, "third combo card scales bolt") and ok
	ok = _assert_eq(combat.enemies[0].health, 10, "enemy loses scaled damage") and ok
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
