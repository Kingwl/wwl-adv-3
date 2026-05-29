class_name CombatState
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CardDeck = preload("res://scripts/core/cards/card_deck.gd")
const ComboState = preload("res://scripts/core/combat/combo_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const CardPlayResult = preload("res://scripts/core/combat/card_play_result.gd")

const MAX_ENEMIES_PER_ROW := 5
const ENEMY_INTENT_ATTACK := "attack"
const ENEMY_INTENT_GUARD := "guard"
const ENEMY_INTENT_WAIT := "wait"

var player: CombatantState
var enemies: Array = []
var enemy_rows: Array = []
var enemy_front_turns: Dictionary = {}
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
	enemy_rows.clear()
	enemy_front_turns.clear()
	_setup_enemy_rows(p_enemies)

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

	_clear_enemy_blocks()
	for enemy in front_row_enemies():
		var intent := enemy_intent_for(enemy)
		var intent_type := str(intent.get("type", ENEMY_INTENT_WAIT))
		if intent_type == ENEMY_INTENT_ATTACK:
			damage_taken += player.take_damage(int(intent.get("amount", 0)))
		elif intent_type == ENEMY_INTENT_GUARD:
			enemy.gain_block(int(intent.get("amount", 0)))

	if not player.is_defeated():
		start_player_turn()
	return damage_taken


func front_row_enemies() -> Array:
	_ensure_enemy_rows()
	_advance_front_rows()
	if enemy_rows.is_empty():
		return []
	return _living_enemies_in_row(enemy_rows[0])


func active_attackers() -> Array:
	var attackers: Array = []
	for enemy in front_row_enemies():
		if can_enemy_attack(enemy):
			attackers.append(enemy)
	return attackers


func enemy_intent_for(enemy: CombatantState) -> Dictionary:
	if enemy == null or enemy.is_defeated():
		return {"type": ENEMY_INTENT_WAIT, "amount": 0}
	if not front_row_enemies().has(enemy):
		return {"type": ENEMY_INTENT_WAIT, "amount": 0}
	if not _enemy_is_ready(enemy):
		return {"type": ENEMY_INTENT_WAIT, "amount": 0}
	if _enemy_should_guard(enemy):
		return {"type": ENEMY_INTENT_GUARD, "amount": enemy.guard_block}
	return {"type": ENEMY_INTENT_ATTACK, "amount": enemy.attack_damage}


func can_enemy_attack(enemy: CombatantState) -> bool:
	if enemy == null or enemy.is_defeated():
		return false
	return front_row_enemies().has(enemy) and _enemy_is_ready(enemy) and not _enemy_should_guard(enemy)


func can_enemy_guard(enemy: CombatantState) -> bool:
	if enemy == null or enemy.is_defeated():
		return false
	return front_row_enemies().has(enemy) and _enemy_is_ready(enemy) and _enemy_should_guard(enemy)


func primary_target_index() -> int:
	var attackers := active_attackers()
	var best_attacker_index := -1
	var best_attacker_threat := -1
	for i in range(enemies.size()):
		if attackers.has(enemies[i]):
			var threat := _enemy_attack_threat(enemies[i])
			if threat > best_attacker_threat:
				best_attacker_index = i
				best_attacker_threat = threat
	if best_attacker_index >= 0:
		return best_attacker_index

	var targetable := targetable_enemy_indices()
	if targetable.is_empty():
		return -1
	return int(targetable[0])


func targetable_enemy_indices() -> Array:
	var front := front_row_enemies()
	var indices: Array = []
	for i in range(enemies.size()):
		if front.has(enemies[i]):
			indices.append(i)
	return indices


func living_enemy_rows() -> Array:
	_ensure_enemy_rows()
	_advance_front_rows()
	var rows: Array = []
	for raw_row in enemy_rows:
		var row: Array = raw_row
		var living := _living_enemies_in_row(row)
		if not living.is_empty():
			rows.append(living)
	return rows


func living_enemies() -> Array:
	_ensure_enemy_rows()
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
			_advance_front_rows()
		elif card.target_mode == CardDefinition.TargetMode.ALL_ENEMIES:
			for enemy in enemies:
				if enemy.is_defeated():
					continue
				result.damage_dealt += enemy.take_damage(scaled_damage)
				if enemy.is_defeated():
					result.defeated_enemy_ids.append(enemy.id)
			_advance_front_rows()

	if card.block > 0:
		player.gain_block(card.block)
		result.block_gained = card.block


func _scale_damage(base_damage: int, multiplier_basis_points: int) -> int:
	return int((base_damage * multiplier_basis_points) / 100)


func _is_valid_enemy_target(target_index: int) -> bool:
	return targetable_enemy_indices().has(target_index)


func _setup_enemy_rows(p_enemies: Array) -> void:
	if not p_enemies.is_empty() and p_enemies[0] is Array:
		for raw_row in p_enemies:
			_append_enemy_row(raw_row)
	else:
		_append_enemy_row(p_enemies)
	_mark_front_row_entered(0)


func _append_enemy_row(raw_enemies: Array) -> void:
	var row: Array = []
	for raw_enemy in raw_enemies:
		if raw_enemy == null or not raw_enemy.has_method("duplicate_state"):
			continue
		var enemy: CombatantState = raw_enemy.duplicate_state()
		enemies.append(enemy)
		row.append(enemy)
		if row.size() >= MAX_ENEMIES_PER_ROW:
			enemy_rows.append(row)
			row = []
	if not row.is_empty():
		enemy_rows.append(row)


func _ensure_enemy_rows() -> void:
	if not enemy_rows.is_empty():
		return
	var row: Array = []
	for enemy in enemies:
		if enemy == null:
			continue
		row.append(enemy)
		if row.size() >= MAX_ENEMIES_PER_ROW:
			enemy_rows.append(row)
			row = []
	if not row.is_empty():
		enemy_rows.append(row)
	_mark_front_row_entered(turn - 1)


func _advance_front_rows() -> void:
	_ensure_enemy_rows()
	while not enemy_rows.is_empty() and _living_enemies_in_row(enemy_rows[0]).is_empty():
		enemy_rows.pop_front()
		if not enemy_rows.is_empty():
			_mark_front_row_entered(turn)


func _mark_front_row_entered(entered_turn: int) -> void:
	if enemy_rows.is_empty():
		return
	for enemy in _living_enemies_in_row(enemy_rows[0]):
		var key := _enemy_key(enemy)
		if not enemy_front_turns.has(key):
			enemy_front_turns[key] = entered_turn


func _enemy_front_turn(enemy: CombatantState) -> int:
	return int(enemy_front_turns.get(_enemy_key(enemy), turn - 1))


func _enemy_is_ready(enemy: CombatantState) -> bool:
	return _enemy_front_turn(enemy) < turn


func _enemy_front_age(enemy: CombatantState) -> int:
	return max(turn - _enemy_front_turn(enemy), 0)


func _enemy_should_guard(enemy: CombatantState) -> bool:
	return enemy.guard_block > 0 and _enemy_front_age(enemy) % 2 == 0


func _enemy_attack_threat(enemy: CombatantState) -> int:
	var intent := enemy_intent_for(enemy)
	if str(intent.get("type", ENEMY_INTENT_WAIT)) != ENEMY_INTENT_ATTACK:
		return 0
	return int(intent.get("amount", 0))


func _enemy_key(enemy: CombatantState) -> int:
	return enemy.get_instance_id()


func _clear_enemy_blocks() -> void:
	for enemy in living_enemies():
		enemy.clear_block()


func _living_enemies_in_row(row: Array) -> Array:
	var living: Array = []
	for enemy in row:
		if enemy != null and not enemy.is_defeated():
			living.append(enemy)
	return living
