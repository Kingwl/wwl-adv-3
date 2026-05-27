class_name StarterCardCatalog
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")


static func create_strike() -> CardDefinition:
	return CardDefinition.new(
		"strike",
		"Strike",
		1,
		6,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_bolt() -> CardDefinition:
	return CardDefinition.new(
		"bolt",
		"Bolt",
		2,
		9,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_guard() -> CardDefinition:
	return CardDefinition.new(
		"guard",
		"Guard",
		1,
		0,
		5,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_focus() -> CardDefinition:
	return CardDefinition.new(
		"focus",
		"Focus",
		0,
		0,
		0,
		1,
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
