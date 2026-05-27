class_name CardDeck
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")

var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []

var _rng := RandomNumberGenerator.new()


func setup(cards: Array, seed_value: int = 1) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	_rng.seed = seed_value

	for card in cards:
		if card != null and card.has_method("duplicate_definition"):
			draw_pile.append(card.duplicate_definition())

	_shuffle(draw_pile)


func draw(count: int) -> Array:
	var drawn: Array = []
	for _i in range(max(count, 0)):
		if draw_pile.is_empty():
			_recycle_discard_pile()
		if draw_pile.is_empty():
			break

		var card: CardDefinition = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
	return drawn


func discard_card_from_hand(hand_index: int) -> CardDefinition:
	if hand_index < 0 or hand_index >= hand.size():
		return null

	var card: CardDefinition = hand.pop_at(hand_index)
	discard_pile.append(card)
	return card


func discard_hand() -> void:
	while not hand.is_empty():
		discard_pile.append(hand.pop_back())


func card_count() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size()


func _recycle_discard_pile() -> void:
	if discard_pile.is_empty():
		return

	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	_shuffle(draw_pile)


func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp
