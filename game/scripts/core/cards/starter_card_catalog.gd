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
const CARD_ID_FORTIFY := "fortify"
const CARD_ID_STEADY_BREATH := "steady_breath"
const CARD_ID_TACTICAL_ADJUSTMENT := "tactical_adjustment"
const CARD_ID_RIPOSTE := "riposte"
const CARD_ID_SHIELD_BASH := "shield_bash"
const CARD_ID_SWEEP := "sweep"
const CARD_ID_WHIRLWIND := "whirlwind"
const CARD_ID_FINISHING_BLOW := "finishing_blow"
const CARD_ID_PREPARE := "prepare"
const CARD_ID_DEEP_FOCUS := "deep_focus"


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


static func create_fortify() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_FORTIFY,
		"固守",
		0,
		0,
		4,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_steady_breath() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_STEADY_BREATH,
		"稳息",
		0,
		0,
		2,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_tactical_adjustment() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_TACTICAL_ADJUSTMENT,
		"战术调整",
		1,
		0,
		5,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_riposte() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_RIPOSTE,
		"还击",
		1,
		5,
		5,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_shield_bash() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SHIELD_BASH,
		"盾击",
		2,
		8,
		8,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_sweep() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SWEEP,
		"横扫",
		2,
		5,
		0,
		0,
		CardDefinition.TargetMode.ALL_ENEMIES
	)


static func create_whirlwind() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_WHIRLWIND,
		"旋刃",
		3,
		8,
		0,
		0,
		CardDefinition.TargetMode.ALL_ENEMIES
	)


static func create_finishing_blow() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_FINISHING_BLOW,
		"收束一击",
		3,
		14,
		0,
		1,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_prepare() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_PREPARE,
		"预演",
		1,
		0,
		0,
		3,
		CardDefinition.TargetMode.SELF
	)


static func create_deep_focus() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_DEEP_FOCUS,
		"深思",
		2,
		0,
		0,
		4,
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
		CARD_ID_FORTIFY,
		CARD_ID_STEADY_BREATH,
		CARD_ID_TACTICAL_ADJUSTMENT,
		CARD_ID_RIPOSTE,
		CARD_ID_SHIELD_BASH,
		CARD_ID_SWEEP,
		CARD_ID_WHIRLWIND,
		CARD_ID_FINISHING_BLOW,
		CARD_ID_PREPARE,
		CARD_ID_DEEP_FOCUS,
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
	if card_id == CARD_ID_FORTIFY:
		return create_fortify()
	if card_id == CARD_ID_STEADY_BREATH:
		return create_steady_breath()
	if card_id == CARD_ID_TACTICAL_ADJUSTMENT:
		return create_tactical_adjustment()
	if card_id == CARD_ID_RIPOSTE:
		return create_riposte()
	if card_id == CARD_ID_SHIELD_BASH:
		return create_shield_bash()
	if card_id == CARD_ID_SWEEP:
		return create_sweep()
	if card_id == CARD_ID_WHIRLWIND:
		return create_whirlwind()
	if card_id == CARD_ID_FINISHING_BLOW:
		return create_finishing_blow()
	if card_id == CARD_ID_PREPARE:
		return create_prepare()
	if card_id == CARD_ID_DEEP_FOCUS:
		return create_deep_focus()
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
