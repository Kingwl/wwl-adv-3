class_name RewardGenerator
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")

const REWARD_TYPE_CARD := "card"
const CATEGORY_ATTACK := "attack"
const CATEGORY_DEFENSE := "defense"
const CATEGORY_DRAW := "draw"
const EVENT_REWARD_APPLIED := "reward_applied"
const EVENT_REWARD_REJECTED := "reward_rejected"


static func create_stage_1_card_choices(
	run_seed: int,
	stage_index: int,
	level: int,
	offer_index: int = 0
) -> Array:
	return create_card_choices(
		StarterCardCatalog.create_stage_1_reward_pool(),
		reward_seed(run_seed, stage_index, level, offer_index),
		3
	)


static func create_card_choices(card_pool: Array, seed_value: int, choice_count: int = 3) -> Array:
	var selected_cards := _select_diverse_cards(card_pool, seed_value, choice_count)
	var choices: Array = []
	for card in selected_cards:
		choices.append(create_card_choice(card))
	return choices


static func create_card_choice(card: CardDefinition) -> Dictionary:
	if card == null:
		return {}
	return {
		"type": REWARD_TYPE_CARD,
		"card_id": card.id,
		"display_name": card.display_name,
		"category": _category_for_card(card),
		"description": _description_for_card(card),
		"cost": card.cost,
		"base_damage": card.base_damage,
		"block": card.block,
		"draw_count": card.draw_count,
	}


static func apply_choice(run_state: RunState, choice: Dictionary) -> Dictionary:
	if run_state == null:
		return _result(EVENT_REWARD_REJECTED, false, "missing_run_state", choice)
	if str(choice.get("type", "")) != REWARD_TYPE_CARD:
		return _result(EVENT_REWARD_REJECTED, false, "unsupported_reward_type", choice)

	var card_id := str(choice.get("card_id", ""))
	if not run_state.add_card(card_id):
		return _result(EVENT_REWARD_REJECTED, false, "invalid_card", choice)
	return _result(EVENT_REWARD_APPLIED, true, "", choice)


static func reward_seed(run_seed: int, stage_index: int, level: int, offer_index: int = 0) -> int:
	return (
		abs(run_seed)
		+ max(stage_index, 1) * 1009
		+ max(level, 1) * 9176
		+ max(offer_index, 0) * 7919
	)


static func _select_diverse_cards(card_pool: Array, seed_value: int, choice_count: int) -> Array:
	var buckets := {
		CATEGORY_ATTACK: [],
		CATEGORY_DEFENSE: [],
		CATEGORY_DRAW: [],
	}
	for raw_card in card_pool:
		var card: CardDefinition = raw_card
		buckets[_category_for_card(card)].append(card)

	var selected_cards: Array = []
	var selected_ids := {}
	var categories := _shuffled([CATEGORY_ATTACK, CATEGORY_DEFENSE, CATEGORY_DRAW], seed_value + 17)
	for raw_category in categories:
		if selected_cards.size() >= choice_count:
			break
		var category := str(raw_category)
		var bucket: Array = _shuffled(buckets[category], seed_value + _category_seed_offset(category))
		for raw_card in bucket:
			var card: CardDefinition = raw_card
			if selected_ids.has(card.id):
				continue
			selected_cards.append(card)
			selected_ids[card.id] = true
			break

	var shuffled_pool := _shuffled(card_pool, seed_value + 73)
	for raw_card in shuffled_pool:
		if selected_cards.size() >= choice_count:
			break
		var card: CardDefinition = raw_card
		if selected_ids.has(card.id):
			continue
		selected_cards.append(card)
		selected_ids[card.id] = true

	return _shuffled(selected_cards, seed_value + 131)


static func _category_for_card(card: CardDefinition) -> String:
	if card != null and card.base_damage > 0:
		return CATEGORY_ATTACK
	if card != null and card.block > 0:
		return CATEGORY_DEFENSE
	return CATEGORY_DRAW


static func _description_for_card(card: CardDefinition) -> String:
	if card.base_damage > 0:
		return "费用 %s，造成 %s 伤害" % [card.cost, card.base_damage]
	if card.block > 0:
		return "费用 %s，获得 %s 护甲" % [card.cost, card.block]
	if card.draw_count > 0:
		return "费用 %s，抽 %s 张牌" % [card.cost, card.draw_count]
	return "费用 %s" % card.cost


static func _shuffled(values: Array, seed_value: int) -> Array:
	var shuffled := values.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = max(seed_value, 1)
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp
	return shuffled


static func _category_seed_offset(category: String) -> int:
	if category == CATEGORY_ATTACK:
		return 211
	if category == CATEGORY_DEFENSE:
		return 421
	return 631


static func _result(event_type: String, ok: bool, reason: String, choice: Dictionary) -> Dictionary:
	return {
		"type": event_type,
		"ok": ok,
		"reason": reason,
		"choice": choice,
		"card_id": str(choice.get("card_id", "")),
	}
