extends SceneTree


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var failed := false
	var packed_scene: PackedScene = load("res://scenes/run.tscn")
	var run_scene = packed_scene.instantiate()
	root.add_child(run_scene)
	await process_frame
	await process_frame

	failed = not _test_run_scene_loads_stage_1(run_scene) or failed
	failed = not _test_run_scene_supports_touch_cell_activation(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_supports_combat_keyboard_selection(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_enters_and_wins_combat(run_scene) or failed

	run_scene.queue_free()
	quit(1 if failed else 0)


func _test_run_scene_loads_stage_1(run_scene) -> bool:
	var map_grid: GridContainer = run_scene.find_child("MapGrid", true, false)
	var stage_label: Label = run_scene.find_child("StageLabel", true, false)
	var stats_label: Label = run_scene.find_child("StatsLabel", true, false)
	var action_button: Button = run_scene.find_child("ActionButton", true, false)

	var ok := true
	ok = _assert_ne(map_grid, null, "map grid exists") and ok
	ok = _assert_ne(stage_label, null, "stage label exists") and ok
	ok = _assert_ne(stats_label, null, "stats label exists") and ok
	ok = _assert_ne(action_button, null, "action button exists") and ok
	ok = _assert_ne(run_scene.theme.default_font, null, "run scene has bundled UI font") and ok
	ok = _assert_eq(run_scene.run_state.current_stage.id, "stage_1", "run scene starts stage 1") and ok
	ok = _assert_eq(stage_label.text, "第一关：旧井入口  种子：1001", "stage label uses Chinese") and ok
	ok = _assert_eq(stats_label.text.contains("经验"), true, "stats label uses Chinese xp text") and ok
	ok = _assert_eq(run_scene.run_state.dungeon_map.active_enemy_count(), 12, "run scene enemy count") and ok
	ok = _assert_eq(run_scene.run_state.dungeon_map.active_pickup_count(), 3, "run scene pickup count") and ok
	ok = _assert_eq(map_grid.columns, 16, "run scene map columns") and ok
	ok = _assert_eq(map_grid.get_child_count(), 160, "run scene map cell count") and ok
	ok = _assert_eq(action_button.disabled, true, "action button starts disabled") and ok
	ok = _assert_eq(_visible_text_has_english(run_scene), false, "exploration visible text uses Chinese") and ok
	return ok


func _test_run_scene_supports_touch_cell_activation(run_scene) -> bool:
	var map_grid: GridContainer = run_scene.find_child("MapGrid", true, false)
	var first_cell: Button = map_grid.get_child(0)
	var touch_maps_to_mouse: bool = ProjectSettings.get_setting(
		"input_devices/pointing/emulate_mouse_from_touch",
		false
	)

	var start_position: Vector2i = run_scene.run_state.dungeon_map.player_position
	var first_step := start_position + Vector2i.RIGHT
	var second_step := first_step + Vector2i.RIGHT
	var enemy_position := second_step + Vector2i.RIGHT

	run_scene._on_cell_activated(first_step)
	run_scene._on_cell_activated(second_step)
	run_scene._on_cell_activated(enemy_position)

	var ok := true
	ok = _assert_eq(touch_maps_to_mouse, true, "touch maps to button press") and ok
	ok = _assert_eq(first_cell.custom_minimum_size, Vector2(48, 48), "map cell touch target size") and ok
	ok = _assert_eq(run_scene.mode, "combat", "touching adjacent enemy enters combat") and ok
	ok = _assert_eq(run_scene.active_encounter_id, "enemy_01", "touch enemy encounter id") and ok
	return ok


func _reset_run_scene(run_scene) -> void:
	run_scene.controller.setup(1001)
	run_scene.controller.start_stage_1()
	run_scene._sync_from_controller()
	run_scene.selected_position = run_scene.run_state.dungeon_map.player_position
	run_scene.selected_hand_index = -1
	run_scene.combat_log = ""
	run_scene._refresh()


func _test_run_scene_supports_combat_keyboard_selection(run_scene) -> bool:
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var combat_hand_row: HBoxContainer = run_scene.find_child("CombatHandRow", true, false)
	var combat_hand_title_label: Label = run_scene.find_child("CombatHandTitleLabel", true, false)
	run_scene.active_combat.enemies[0].max_health = 100
	run_scene.active_combat.enemies[0].health = 100
	run_scene.active_combat.mana = 10
	run_scene.active_combat.max_mana = 10
	run_scene._refresh()

	var selected_card_name: String = run_scene.active_combat.deck.hand[0].display_name
	var ok := true
	ok = _assert_eq(run_scene.selected_hand_index, 0, "combat starts with first card selected") and ok
	ok = _assert_eq(combat_hand_title_label.text.contains("已选：%s" % selected_card_name), true, "combat title shows selected card") and ok

	_press_key(run_scene, KEY_RIGHT)
	ok = _assert_eq(run_scene.selected_hand_index, 1, "right key selects next card") and ok
	_press_key(run_scene, KEY_D)
	ok = _assert_eq(run_scene.selected_hand_index, 2, "D key selects next card") and ok
	_press_key(run_scene, KEY_LEFT)
	ok = _assert_eq(run_scene.selected_hand_index, 1, "left key selects previous card") and ok
	_press_key(run_scene, KEY_A)
	ok = _assert_eq(run_scene.selected_hand_index, 0, "A key selects previous card") and ok

	run_scene._on_card_hovered(2)
	ok = _assert_eq(run_scene.selected_hand_index, 2, "mouse hover syncs selected card") and ok

	var hand_size_before_space: int = run_scene.active_combat.deck.hand.size()
	var space_card_name: String = run_scene.active_combat.deck.hand[run_scene.selected_hand_index].display_name
	_press_key(run_scene, KEY_SPACE)
	await process_frame
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), hand_size_before_space - 1, "space plays selected card") and ok
	ok = _assert_eq(run_scene.combat_log.contains(space_card_name), true, "space play log uses selected card") and ok

	run_scene.active_combat.mana = 10
	run_scene._on_card_hovered(0)
	var hand_size_before_enter: int = run_scene.active_combat.deck.hand.size()
	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), hand_size_before_enter - 1, "enter plays selected card") and ok
	ok = _assert_eq(combat_hand_row.get_child_count() >= 3, true, "combat hand stays interactive after keyboard play") and ok
	return ok


func _test_run_scene_enters_and_wins_combat(run_scene) -> bool:
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	var status_label: Label = run_scene.find_child("StatusLabel", true, false)
	await process_frame

	var combat_panel: VBoxContainer = run_scene.find_child("CombatPanel", true, false)
	var combat_hand_row: HBoxContainer = run_scene.find_child("CombatHandRow", true, false)
	var combat_hand_title_label: Label = run_scene.find_child("CombatHandTitleLabel", true, false)
	var combat_title_label: Label = run_scene.find_child("CombatTitleLabel", true, false)
	var player_state_panel: PanelContainer = run_scene.find_child("PlayerStatePanel", true, false)

	var ok := true
	ok = _assert_eq(run_scene.mode, "combat", "run scene enters combat") and ok
	ok = _assert_eq(run_scene.active_encounter_id, "enemy_01", "active encounter id") and ok
	ok = _assert_eq(status_label.text, "遭遇已开始。", "combat start does not leak internal id") and ok
	ok = _assert_eq(combat_panel.visible, true, "combat panel visible") and ok
	var selected_card_name: String = run_scene.active_combat.deck.hand[0].display_name
	ok = _assert_eq(combat_hand_title_label.text, "手牌（5）  已选：%s  生命 40/40 | 护甲 0 | 法力 3/3 | 连击 0" % selected_card_name, "combat hand title") and ok
	ok = _assert_eq(combat_hand_row.get_child_count(), 5, "combat hand buttons") and ok
	ok = _assert_eq(combat_title_label.text, "遭遇：敌人", "combat title") and ok
	ok = _assert_eq(player_state_panel, null, "combat has no player state panel") and ok
	ok = _assert_eq(_visible_text_has_english(combat_hand_row), false, "combat hand text uses Chinese") and ok
	ok = _assert_eq(_visible_text_has_english(run_scene), false, "combat visible text uses Chinese") and ok

	run_scene._on_card_pressed(0)
	await process_frame

	ok = _assert_eq(run_scene.active_combat.mana, 2, "playing first card spends mana") and ok
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), 4, "playing first card removes hand card") and ok

	run_scene._finish_combat_victory()
	await process_frame

	ok = _assert_eq(run_scene.mode, "exploration", "run scene returns to exploration") and ok
	ok = _assert_eq(run_scene.run_state.dungeon_map.active_enemy_count(), 11, "victory removes map enemy") and ok
	return ok


func _press_key(run_scene, keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	run_scene._unhandled_key_input(event)


func _assert_eq(actual, expected, label: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return false
	return true


func _assert_ne(actual, expected, label: String) -> bool:
	if actual == expected:
		push_error("%s: expected value different from %s" % [label, str(expected)])
		return false
	return true


func _visible_text_has_english(node: Node) -> bool:
	if node is Button:
		if _string_has_english(node.text):
			return true
	if node is Label:
		if _string_has_english(node.text):
			return true
	for child in node.get_children():
		if _visible_text_has_english(child):
			return true
	return false


func _string_has_english(value: String) -> bool:
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false
