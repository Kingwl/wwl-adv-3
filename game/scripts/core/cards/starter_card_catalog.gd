class_name StarterCardCatalog
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")


static func create_strike() -> CardDefinition:
	return CardDefinition.new(
		"strike",
		"打击",
		1,
		6,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_bolt() -> CardDefinition:
	return CardDefinition.new(
		"bolt",
		"闪电",
		2,
		9,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_guard() -> CardDefinition:
	return CardDefinition.new(
		"guard",
		"防守",
		1,
		0,
		5,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_focus() -> CardDefinition:
	return CardDefinition.new(
		"focus",
		"专注",
		0,
		0,
		0,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_swift_strike() -> CardDefinition:
	return CardDefinition.new(
		"swift_strike",
		"迅击",
		0,
		3,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_slash() -> CardDefinition:
	return CardDefinition.new(
		"slash",
		"劈砍",
		1,
		8,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_charged_slash() -> CardDefinition:
	return CardDefinition.new(
		"charged_slash",
		"蓄力斩",
		2,
		12,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_heavy_hammer() -> CardDefinition:
	return CardDefinition.new(
		"heavy_hammer",
		"重锤",
		3,
		18,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_block() -> CardDefinition:
	return CardDefinition.new(
		"block",
		"格挡",
		1,
		0,
		8,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_iron_wall() -> CardDefinition:
	return CardDefinition.new(
		"iron_wall",
		"铁壁",
		2,
		0,
		14,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_insight() -> CardDefinition:
	return CardDefinition.new(
		"insight",
		"洞察",
		0,
		0,
		0,
		2,
		CardDefinition.TargetMode.SELF
	)


static func create_starter_deck() -> Array:
	return [
		create_strike(),
		create_strike(),
		create_strike(),
		create_bolt(),
		create_bolt(),
		create_guard(),
		create_guard(),
		create_focus(),
	]


static func create_stage_1_reward_pool() -> Array:
	return [
		create_swift_strike(),
		create_slash(),
		create_charged_slash(),
		create_heavy_hammer(),
		create_block(),
		create_iron_wall(),
		create_insight(),
	]
