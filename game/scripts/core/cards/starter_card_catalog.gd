class_name StarterCardCatalog
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")

const CARD_ID_STRIKE := "strike"
const CARD_ID_BOLT := "bolt"
const CARD_ID_GUARD := "guard"
const CARD_ID_FOCUS := "focus"
const CARD_ID_SWIFT_STRIKE := "swift_strike"
const CARD_ID_SLASH := "slash"
const CARD_ID_CHARGED_SLASH := "charged_slash"
const CARD_ID_HEAVY_HAMMER := "heavy_hammer"
const CARD_ID_BLOCK := "block"
const CARD_ID_IRON_WALL := "iron_wall"
const CARD_ID_INSIGHT := "insight"


static func create_strike() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_STRIKE,
		"打击",
		1,
		6,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_bolt() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_BOLT,
		"闪电",
		2,
		9,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_guard() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_GUARD,
		"防守",
		1,
		0,
		5,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_focus() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_FOCUS,
		"专注",
		0,
		0,
		0,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_swift_strike() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SWIFT_STRIKE,
		"迅击",
		0,
		3,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_slash() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SLASH,
		"劈砍",
		1,
		8,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_charged_slash() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_CHARGED_SLASH,
		"蓄力斩",
		2,
		12,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_heavy_hammer() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_HEAVY_HAMMER,
		"重锤",
		3,
		18,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_block() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_BLOCK,
		"格挡",
		1,
		0,
		8,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_iron_wall() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_IRON_WALL,
		"铁壁",
		2,
		0,
		14,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_insight() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_INSIGHT,
		"洞察",
		0,
		0,
		0,
		2,
		CardDefinition.TargetMode.SELF
	)


static func create_starter_deck() -> Array:
	return create_cards_from_ids(starter_deck_card_ids())


static func starter_deck_card_ids() -> Array:
	return [
		CARD_ID_STRIKE,
		CARD_ID_STRIKE,
		CARD_ID_STRIKE,
		CARD_ID_BOLT,
		CARD_ID_BOLT,
		CARD_ID_GUARD,
		CARD_ID_GUARD,
		CARD_ID_FOCUS,
	]


static func create_stage_1_reward_pool() -> Array:
	return create_cards_from_ids(stage_1_reward_card_ids())


static func stage_1_reward_card_ids() -> Array:
	return [
		CARD_ID_SWIFT_STRIKE,
		CARD_ID_SLASH,
		CARD_ID_CHARGED_SLASH,
		CARD_ID_HEAVY_HAMMER,
		CARD_ID_BLOCK,
		CARD_ID_IRON_WALL,
		CARD_ID_INSIGHT,
	]


static func create_card_by_id(card_id: String) -> CardDefinition:
	if card_id == CARD_ID_STRIKE:
		return create_strike()
	if card_id == CARD_ID_BOLT:
		return create_bolt()
	if card_id == CARD_ID_GUARD:
		return create_guard()
	if card_id == CARD_ID_FOCUS:
		return create_focus()
	if card_id == CARD_ID_SWIFT_STRIKE:
		return create_swift_strike()
	if card_id == CARD_ID_SLASH:
		return create_slash()
	if card_id == CARD_ID_CHARGED_SLASH:
		return create_charged_slash()
	if card_id == CARD_ID_HEAVY_HAMMER:
		return create_heavy_hammer()
	if card_id == CARD_ID_BLOCK:
		return create_block()
	if card_id == CARD_ID_IRON_WALL:
		return create_iron_wall()
	if card_id == CARD_ID_INSIGHT:
		return create_insight()
	return null


static func create_cards_from_ids(card_ids: Array) -> Array:
	var cards: Array = []
	for raw_card_id in card_ids:
		var card := create_card_by_id(str(raw_card_id))
		if card != null:
			cards.append(card)
	return cards


static func has_card_id(card_id: String) -> bool:
	return create_card_by_id(card_id) != null
