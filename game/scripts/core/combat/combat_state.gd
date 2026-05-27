class_name CombatState
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CardDeck = preload("res://scripts/core/cards/card_deck.gd")
const ComboState = preload("res://scripts/core/combat/combo_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const CardPlayResult = preload("res://scripts/core/combat/card_play_result.gd")

var player: CombatantState
var enemies: Array = []
var deck: CardDeck = CardDeck.new()
var combo: ComboState = ComboState.new()

var max_mana: int = 3
var mana: int = 3
var draw_per_turn: int = 5
var turn: int = 0


func setup(
	p_player: CombatantState,
	starter_deck: Array,
	p_enemies: Array,
	seed_value: int = 1,
	p_max_mana: int = 3,
	p_draw_per_turn: int = 5
) -> void:
	player = p_player.duplicate_state()
	enemies.clear()
	for enemy in p_enemies:
		if enemy != null and enemy.has_method("duplicate_state"):
			enemies.append(enemy.duplicate_state())

	deck.setup(starter_deck, seed_value)
	max_mana = max(p_max_mana, 0)
	draw_per_turn = max(p_draw_per_turn, 0)
	turn = 0
	start_player_turn()


func start_player_turn() -> Array:
	turn += 1
	mana = max_mana
	if player != null:
		player.clear_block()
	combo.reset()
	return deck.draw(draw_per_turn)


func play_card(hand_index: int, target_index: int = -1) -> CardPlayResult:
	if player == null:
		return CardPlayResult.failure("missing_player")
	if hand_index < 0 or hand_index >= deck.hand.size():
		return CardPlayResult.failure("invalid_hand_index")

	var card: CardDefinition = deck.hand[hand_index]
	if card.cost > mana:
		return CardPlayResult.failure("not_enough_mana")
	if card.needs_enemy_target() and not _is_valid_enemy_target(target_index):
		return CardPlayResult.failure("invalid_target")

	var result := CardPlayResult.new()
	result.card_id = card.id
	result.mana_spent = card.cost
	result.multiplier_basis_points = combo.apply_card(card)
	result.combo_chain = combo.chain

	_apply_card_effect(card, target_index, result)
	mana -= card.cost
	deck.discard_card_from_hand(hand_index)

	if card.draw_count > 0:
		result.cards_drawn = deck.draw(card.draw_count).size()

	return result


func end_player_turn() -> int:
	deck.discard_hand()
	combo.reset()

	var damage_taken := 0
	if is_victory() or player == null:
		return damage_taken

	for enemy in enemies:
		if not enemy.is_defeated():
			damage_taken += player.take_damage(enemy.attack_damage)

	if not player.is_defeated():
		start_player_turn()
	return damage_taken


func living_enemies() -> Array:
	var alive: Array = []
	for enemy in enemies:
		if not enemy.is_defeated():
			alive.append(enemy)
	return alive


func is_victory() -> bool:
	return living_enemies().is_empty()


func is_defeat() -> bool:
	return player != null and player.is_defeated()


func _apply_card_effect(card: CardDefinition, target_index: int, result: CardPlayResult) -> void:
	if card.base_damage > 0:
		var scaled_damage := _scale_damage(card.base_damage, result.multiplier_basis_points)
		result.damage_requested = scaled_damage
		if card.target_mode == CardDefinition.TargetMode.SINGLE_ENEMY:
			var target: CombatantState = enemies[target_index]
			result.target_id = target.id
			result.damage_dealt = target.take_damage(scaled_damage)
			if target.is_defeated():
				result.defeated_enemy_ids.append(target.id)
		elif card.target_mode == CardDefinition.TargetMode.ALL_ENEMIES:
			for enemy in enemies:
				if enemy.is_defeated():
					continue
				result.damage_dealt += enemy.take_damage(scaled_damage)
				if enemy.is_defeated():
					result.defeated_enemy_ids.append(enemy.id)

	if card.block > 0:
		player.gain_block(card.block)
		result.block_gained = card.block


func _scale_damage(base_damage: int, multiplier_basis_points: int) -> int:
	return int((base_damage * multiplier_basis_points) / 100)


func _is_valid_enemy_target(target_index: int) -> bool:
	return target_index >= 0 and target_index < enemies.size() and not enemies[target_index].is_defeated()
