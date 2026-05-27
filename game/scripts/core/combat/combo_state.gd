class_name ComboState
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")

const BASE_MULTIPLIER_BASIS_POINTS := 100
const CHAIN_BONUS_BASIS_POINTS := 25

var chain: int = 0
var last_cost: int = -1


func reset() -> void:
	chain = 0
	last_cost = -1


func preview_chain_for(card: CardDefinition) -> int:
	if card == null:
		return 1
	if chain == 0 or card.cost >= last_cost:
		return chain + 1
	return 1


func preview_multiplier_basis_points(card: CardDefinition) -> int:
	var next_chain := preview_chain_for(card)
	return BASE_MULTIPLIER_BASIS_POINTS + max(next_chain - 1, 0) * CHAIN_BONUS_BASIS_POINTS


func apply_card(card: CardDefinition) -> int:
	var multiplier_basis_points := preview_multiplier_basis_points(card)
	chain = preview_chain_for(card)
	if card != null:
		last_cost = card.cost
	return multiplier_basis_points
