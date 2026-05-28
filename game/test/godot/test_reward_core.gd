extends SceneTree

const RewardGenerator = preload("res://scripts/core/rewards/reward_generator.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const StageFixtureCatalog = preload("res://scripts/core/dungeon/stage_fixture_catalog.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")


func _init() -> void:
	var failed := false
	failed = not _test_card_catalog_resolves_run_deck_ids() or failed
	failed = not _test_stage_1_card_rewards_are_seeded_and_diverse() or failed
	failed = not _test_reward_choice_adds_card_to_run_deck() or failed
	failed = not _test_run_combat_uses_current_run_deck() or failed
	failed = not _test_level_up_enters_reward_mode_until_choice_applied() or failed
	failed = not _test_multiple_level_ups_queue_multiple_rewards() or failed
	quit(1 if failed else 0)


func _test_card_catalog_resolves_run_deck_ids() -> bool:
	var starter_ids := StarterCardCatalog.starter_deck_card_ids()
	var reward_ids := StarterCardCatalog.stage_1_reward_card_ids()
	var deck_cards := StarterCardCatalog.create_cards_from_ids(["strike", "slash", "insight"])

	var ok := true
	ok = _assert_eq(starter_ids.size(), 8, "starter deck id count") and ok
	ok = _assert_eq(reward_ids.size(), 7, "stage 1 reward id count") and ok
	ok = _assert_eq(deck_cards.size(), 3, "deck cards resolve from ids") and ok
	ok = _assert_eq(deck_cards[1].display_name, "劈砍", "slash resolves to Chinese card") and ok
	ok = _assert_eq(StarterCardCatalog.create_card_by_id("missing") == null, true, "missing card returns null") and ok
	return ok


func _test_stage_1_card_rewards_are_seeded_and_diverse() -> bool:
	var first_choices := RewardGenerator.create_stage_1_card_choices(1001, 1, 2, 0)
	var second_choices := RewardGenerator.create_stage_1_card_choices(1001, 1, 2, 0)
	var different_offer := RewardGenerator.create_stage_1_card_choices(1001, 1, 2, 1)
	var ids := {}
	var categories := {}

	var ok := true
	ok = _assert_eq(first_choices.size(), 3, "reward choice count") and ok
	ok = _assert_eq(_choice_card_ids(first_choices), _choice_card_ids(second_choices), "same seed gives same choices") and ok
	ok = _assert_eq(_choice_card_ids(first_choices) == _choice_card_ids(different_offer), false, "different offer index changes choices") and ok
	for choice in first_choices:
		var card_id := str(choice["card_id"])
		ok = _assert_eq(ids.has(card_id), false, "reward choices do not repeat cards") and ok
		ids[card_id] = true
		categories[str(choice["category"])] = true
		ok = _assert_eq(str(choice["display_name"]).is_empty(), false, "reward choice has display name") and ok
		ok = _assert_eq(str(choice["description"]).is_empty(), false, "reward choice has description") and ok
	ok = _assert_eq(categories.size(), 3, "reward choices include attack defense and draw") and ok
	return ok


func _test_reward_choice_adds_card_to_run_deck() -> bool:
	var run_state := RunState.new()
	run_state.setup(42)
	var choices := RewardGenerator.create_stage_1_card_choices(42, 1, 2, 0)
	var before_count := run_state.deck_card_ids.size()
	var apply_result := RewardGenerator.apply_choice(run_state, choices[0])
	var invalid_result := RewardGenerator.apply_choice(run_state, {
		"type": RewardGenerator.REWARD_TYPE_CARD,
		"card_id": "missing",
	})

	var ok := true
	ok = _assert_eq(apply_result["type"], RewardGenerator.EVENT_REWARD_APPLIED, "reward apply event") and ok
	ok = _assert_eq(run_state.deck_card_ids.size(), before_count + 1, "reward adds one card id") and ok
	ok = _assert_eq(run_state.deck_card_ids.back(), choices[0]["card_id"], "reward adds selected card") and ok
	ok = _assert_eq(invalid_result["type"], RewardGenerator.EVENT_REWARD_REJECTED, "invalid reward is rejected") and ok
	ok = _assert_eq(run_state.deck_card_ids.size(), before_count + 1, "invalid reward does not change deck") and ok
	return ok


func _test_run_combat_uses_current_run_deck() -> bool:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, 40, 3)
	controller.run_state.deck_card_ids = ["heavy_hammer"]
	controller.start_stage_1()

	controller.move_player(Vector2i.RIGHT)
	controller.move_player(Vector2i.RIGHT)
	var encounter_result := controller.move_player(Vector2i.RIGHT)
	var combat_card_ids := _combat_deck_card_ids(controller)

	var ok := true
	ok = _assert_eq(encounter_result["type"], RunController.EVENT_COMBAT_STARTED, "combat starts") and ok
	ok = _assert_eq(combat_card_ids, ["heavy_hammer"], "combat deck uses run deck card ids") and ok
	return ok


func _test_level_up_enters_reward_mode_until_choice_applied() -> bool:
	var controller := _start_first_enemy_combat_with_xp(7)
	controller.active_combat.enemies[0].health = 0
	var victory_result := controller.finish_active_combat_victory()
	var move_result := controller.move_player(Vector2i.RIGHT)
	var reward_choices: Array = controller.pending_reward_choices.duplicate(true)
	var before_count := controller.run_state.deck_card_ids.size()
	var reward_result := controller.apply_reward_choice_index(0)

	var ok := true
	ok = _assert_eq(victory_result["type"], RunController.EVENT_COMBAT_WON, "level-up victory event") and ok
	ok = _assert_eq(controller.mode, RunController.MODE_EXPLORATION, "reward choice returns to exploration") and ok
	ok = _assert_eq(victory_result["level_events"].size(), 1, "victory has one level event") and ok
	ok = _assert_eq(reward_choices.size(), 3, "level-up creates three reward choices") and ok
	ok = _assert_eq(move_result["type"], RunController.EVENT_COMMAND_REJECTED, "movement is blocked while reward is pending") and ok
	ok = _assert_eq(move_result["reason"], "not_in_exploration", "reward mode blocks exploration commands") and ok
	ok = _assert_eq(reward_result["type"], RunController.EVENT_REWARD_APPLIED, "controller applies reward") and ok
	ok = _assert_eq(controller.run_state.reward_offer_index, 1, "controller advances reward offer index") and ok
	ok = _assert_eq(controller.run_state.deck_card_ids.size(), before_count + 1, "reward adds card to run deck") and ok
	ok = _assert_eq(controller.run_state.deck_card_ids.back(), reward_choices[0]["card_id"], "controller reward mutates run deck") and ok
	return ok


func _test_multiple_level_ups_queue_multiple_rewards() -> bool:
	var controller := _start_first_enemy_combat_with_xp(27)
	controller.active_combat.enemies[0].health = 0
	var victory_result := controller.finish_active_combat_victory()
	var first_choices: Array = controller.pending_reward_choices.duplicate(true)
	var first_reward := controller.apply_reward_choice_index(0)
	var second_choices: Array = controller.pending_reward_choices.duplicate(true)
	var second_reward := controller.apply_reward_choice_index(0)

	var ok := true
	ok = _assert_eq(victory_result["level_events"].size(), 2, "large xp gain queues two level rewards") and ok
	ok = _assert_eq(first_choices.size(), 3, "first queued reward has choices") and ok
	ok = _assert_eq(first_reward["type"], RunController.EVENT_REWARD_APPLIED, "first queued reward applies") and ok
	ok = _assert_eq(controller.mode, RunController.MODE_EXPLORATION, "second reward returns to exploration after selection") and ok
	ok = _assert_eq(second_choices.size(), 3, "second queued reward has choices") and ok
	ok = _assert_eq(_choice_card_ids(first_choices) == _choice_card_ids(second_choices), false, "queued rewards use different offer index") and ok
	ok = _assert_eq(second_reward["type"], RunController.EVENT_REWARD_APPLIED, "second queued reward applies") and ok
	ok = _assert_eq(controller.run_state.reward_offer_index, 2, "two reward choices advance offer index twice") and ok
	return ok


func _choice_card_ids(choices: Array) -> Array:
	var ids: Array = []
	for choice in choices:
		ids.append(choice["card_id"])
	return ids


func _combat_deck_card_ids(controller: RunController) -> Array:
	var ids: Array = []
	for card in controller.active_combat.deck.hand:
		ids.append(card.id)
	for card in controller.active_combat.deck.draw_pile:
		ids.append(card.id)
	for card in controller.active_combat.deck.discard_pile:
		ids.append(card.id)
	ids.sort()
	return ids


func _start_first_enemy_combat_with_xp(xp: int) -> RunController:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, 40, 3)
	controller.run_state.xp = xp
	controller.start_stage_1()
	controller.move_player(Vector2i.RIGHT)
	controller.move_player(Vector2i.RIGHT)
	controller.move_player(Vector2i.RIGHT)
	return controller


func _assert_eq(actual, expected, label: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return false
	return true
