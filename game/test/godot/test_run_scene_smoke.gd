extends SceneTree

const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const CARD_SELECTED_LIFT := 12


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
	failed = not _test_run_scene_loads_attack_card_fx_assets(run_scene) or failed
	failed = not _test_run_scene_loads_enemy_and_player_hit_fx_assets(run_scene) or failed
	failed = not _test_run_scene_non_adjacent_click_only_selects(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not _test_run_scene_supports_touch_cell_activation(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not _test_run_scene_exit_responds_after_boss_defeat(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_supports_combat_keyboard_selection(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_supports_end_turn_keyboard_selection(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_shows_level_reward_choices(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_shows_treasure_reward_choices(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_applies_healing_and_xp_pickups(run_scene) or failed
	_reset_run_scene(run_scene)
	await process_frame
	failed = not await _test_run_scene_shows_run_end_on_defeat(run_scene) or failed
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


func _test_run_scene_loads_attack_card_fx_assets(run_scene) -> bool:
	var attack_fx_cards := [
		"whip",
		"magic_wand",
		"knife",
		"axe",
		"cross",
		"king_bible",
		"fire_wand",
		"garlic",
		"santa_water",
		"runetracer",
		"lightning_ring",
		"pentagram",
		"peachone",
		"ebony_wings",
		"song_of_mana",
		"bone",
		"cherry_bomb",
	]
	var ok := true
	for card_id in attack_fx_cards:
		for frame_index in range(4):
			var texture: Texture2D = run_scene.visual_assets.card_attack_fx_texture(card_id, frame_index)
			ok = _assert_ne(texture, null, "attack card fx texture %s frame %s" % [card_id, frame_index]) and ok
			if texture != null:
				ok = _assert_eq(texture.get_width() > 0, true, "attack card fx width %s frame %s" % [card_id, frame_index]) and ok
				ok = _assert_eq(texture.get_height() > 0, true, "attack card fx height %s frame %s" % [card_id, frame_index]) and ok
	return ok


func _test_run_scene_loads_enemy_and_player_hit_fx_assets(run_scene) -> bool:
	var enemy_fx_ids := [
		"grunt",
		"bat",
		"guard",
		"brute",
		"boss_guard",
		"stage_boss",
	]
	var ok := true
	for visual_id in enemy_fx_ids:
		for frame_index in range(4):
			var enemy_texture: Texture2D = run_scene.visual_assets.enemy_attack_fx_texture(visual_id, frame_index)
			ok = _assert_ne(enemy_texture, null, "enemy attack fx texture %s frame %s" % [visual_id, frame_index]) and ok
			if enemy_texture != null:
				ok = _assert_eq(enemy_texture.get_width() > 0, true, "enemy attack fx width %s frame %s" % [visual_id, frame_index]) and ok
				ok = _assert_eq(enemy_texture.get_height() > 0, true, "enemy attack fx height %s frame %s" % [visual_id, frame_index]) and ok
	for frame_index in range(4):
		var player_texture: Texture2D = run_scene.visual_assets.player_hurt_fx_texture(frame_index)
		ok = _assert_ne(player_texture, null, "player hurt fx texture frame %s" % frame_index) and ok
		if player_texture != null:
			ok = _assert_eq(player_texture.get_width() > 0, true, "player hurt fx width frame %s" % frame_index) and ok
			ok = _assert_eq(player_texture.get_height() > 0, true, "player hurt fx height frame %s" % frame_index) and ok
	return ok


func _test_run_scene_non_adjacent_click_only_selects(run_scene) -> bool:
	var start_position: Vector2i = run_scene.run_state.dungeon_map.player_position
	var remote_pickup_position := Vector2i(8, 1)

	run_scene._on_cell_activated(remote_pickup_position)

	var selected_button := _map_cell_button(run_scene, remote_pickup_position)
	var player_button := _map_cell_button(run_scene, start_position)
	var selected_glyph := _map_cell_glyph(selected_button)
	var player_glyph := _map_cell_glyph(player_button)
	var player_visual := _map_cell_visual(player_button)
	var selected_style: StyleBoxFlat = selected_button.get_theme_stylebox("normal") as StyleBoxFlat
	var player_style: StyleBoxFlat = player_button.get_theme_stylebox("normal") as StyleBoxFlat

	var ok := true
	ok = _assert_eq(run_scene.run_state.dungeon_map.player_position, start_position, "remote click does not move player") and ok
	ok = _assert_eq(run_scene.selected_position, remote_pickup_position, "remote click only changes selected tile") and ok
	ok = _assert_eq(selected_button.text, "", "map cell button text does not affect grid sizing") and ok
	ok = _assert_eq(selected_button.icon, null, "map cell button icon does not affect grid sizing") and ok
	ok = _assert_ne(selected_glyph, null, "remote selected pickup has fixed glyph layer") and ok
	if selected_glyph != null:
		ok = _assert_eq(selected_glyph.text, "宝", "remote selected pickup keeps pickup marker") and ok
	ok = _assert_eq(selected_style.bg_color, Color(0.18, 0.50, 0.32), "remote selected pickup keeps tile color") and ok
	ok = _assert_eq(selected_style.border_color, Color(0.92, 0.82, 0.38), "remote selected pickup uses selected border") and ok
	ok = _assert_eq(player_button.text, "", "player cell button text stays empty") and ok
	ok = _assert_ne(player_glyph, null, "player cell has fixed glyph layer") and ok
	if player_glyph != null:
		ok = _assert_eq(player_glyph.text, "我", "player marker stays on actual player") and ok
	ok = _assert_ne(player_visual, null, "player cell has fixed visual layer") and ok
	if player_visual != null:
		ok = _assert_ne(player_visual.texture, null, "player marker uses generated map art") and ok
	ok = _assert_eq(player_button.get_combined_minimum_size(), Vector2(48, 48), "player art does not resize map cell") and ok
	ok = _assert_eq(player_style.bg_color, Color(0.18, 0.48, 0.82), "player keeps player color") and ok
	_press_key(run_scene, KEY_RIGHT)
	ok = _assert_eq(run_scene.run_state.dungeon_map.player_position, start_position + Vector2i.RIGHT, "keyboard moves from actual player position") and ok
	return ok


func _test_run_scene_exit_responds_after_boss_defeat(run_scene) -> bool:
	var status_label: Label = run_scene.find_child("StatusLabel", true, false)
	var stage_label: Label = run_scene.find_child("StageLabel", true, false)
	var map_grid: GridContainer = run_scene.find_child("MapGrid", true, false)
	var map = run_scene.run_state.dungeon_map
	map.mark_enemy_defeated(_stage_1_boss_id(map))
	map.player_position = Vector2i(13, 1)
	run_scene.selected_position = map.player_position
	run_scene._refresh()

	run_scene._try_move(Vector2i.RIGHT)

	var ok := true
	ok = _assert_eq(map.is_exit_unlocked(), true, "boss defeat unlocks exit in scene") and ok
	ok = _assert_eq(run_scene.run_state.current_stage.id, "stage_2", "exit advances scene to stage 2") and ok
	ok = _assert_eq(run_scene.selected_position, run_scene.run_state.dungeon_map.player_position, "stage advance selects new player position") and ok
	ok = _assert_eq(status_label.text.contains("进入第二关"), true, "stage advance shows status") and ok
	ok = _assert_eq(stage_label.text.contains("第二关"), true, "stage label updates to stage 2") and ok
	ok = _assert_eq(map_grid.columns, 18, "stage 2 rebuilds map columns") and ok
	ok = _assert_eq(map_grid.get_child_count(), 180, "stage 2 rebuilds map cells") and ok
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
	run_scene.selected_reward_index = 0
	run_scene.combat_focus = "hand"
	run_scene.combat_log = ""
	run_scene.combat_animation_locked = false
	run_scene.status_message = "探索中。"
	var combat_fx_layer: Control = run_scene.find_child("CardUseFxLayer", true, false)
	if combat_fx_layer != null:
		for child in combat_fx_layer.get_children():
			child.queue_free()
	run_scene._refresh()


func _test_run_scene_shows_level_reward_choices(run_scene) -> bool:
	run_scene.controller.run_state.xp = 7
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	_defeat_all_active_enemies(run_scene)
	run_scene._finish_combat_victory()
	await process_frame

	var reward_panel: VBoxContainer = run_scene.find_child("RewardPanel", true, false)
	var reward_title_label: Label = run_scene.find_child("RewardTitleLabel", true, false)
	var reward_choice_row: HBoxContainer = run_scene.find_child("RewardChoiceRow", true, false)
	var map_panel: VBoxContainer = run_scene.find_child("MapPanel", true, false)
	var combat_panel: VBoxContainer = run_scene.find_child("CombatPanel", true, false)
	var before_deck_size: int = run_scene.run_state.deck_card_ids.size()
	var first_choice_button: Button = reward_choice_row.get_child(0)

	var ok := true
	ok = _assert_eq(run_scene.mode, "reward", "level-up victory enters reward mode") and ok
	ok = _assert_eq(reward_panel.visible, true, "reward panel visible") and ok
	ok = _assert_eq(map_panel.visible, false, "map hidden during reward choice") and ok
	ok = _assert_eq(combat_panel.visible, false, "combat hidden during reward choice") and ok
	ok = _assert_eq(reward_title_label.text.contains("升级奖励"), true, "reward title is Chinese") and ok
	ok = _assert_eq(reward_choice_row.get_child_count(), 3, "reward shows three choices") and ok
	ok = _assert_eq(_node_text_contains(first_choice_button, "加入"), true, "reward choice adds to deck") and ok
	ok = _assert_eq(_visible_text_has_english(reward_panel), false, "reward visible text uses Chinese") and ok

	_press_key(run_scene, KEY_RIGHT)
	ok = _assert_eq(run_scene.selected_reward_index, 1, "right key selects next reward") and ok
	var selected_button: Button = reward_choice_row.get_child(1)
	var selected_style: StyleBoxFlat = selected_button.get_theme_stylebox("normal") as StyleBoxFlat
	ok = _assert_eq(selected_style.border_color, Color(0.92, 0.82, 0.38), "selected reward is highlighted") and ok

	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.mode, "exploration", "reward choice returns to exploration") and ok
	ok = _assert_eq(run_scene.run_state.deck_card_ids.size(), before_deck_size + 1, "reward choice adds card to run deck") and ok
	ok = _assert_eq(run_scene.status_message.contains("获得卡牌"), true, "reward result updates status") and ok
	return ok


func _test_run_scene_shows_treasure_reward_choices(run_scene) -> bool:
	var map = run_scene.run_state.dungeon_map
	map.player_position = Vector2i(7, 1)
	run_scene.selected_position = map.player_position
	run_scene._refresh()

	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var reward_panel: VBoxContainer = run_scene.find_child("RewardPanel", true, false)
	var reward_title_label: Label = run_scene.find_child("RewardTitleLabel", true, false)
	var reward_choice_row: HBoxContainer = run_scene.find_child("RewardChoiceRow", true, false)
	var before_deck_size: int = run_scene.run_state.deck_card_ids.size()

	var ok := true
	ok = _assert_eq(run_scene.mode, "reward", "treasure pickup enters reward mode") and ok
	ok = _assert_eq(reward_panel.visible, true, "treasure reward panel visible") and ok
	ok = _assert_eq(reward_title_label.text, "宝箱奖励", "treasure reward title") and ok
	ok = _assert_eq(reward_choice_row.get_child_count(), 3, "treasure reward shows three choices") and ok
	ok = _assert_eq(run_scene.run_state.dungeon_map.active_pickup_count(), 2, "treasure pickup is removed from map") and ok
	ok = _assert_eq(run_scene.status_message.contains("发现宝箱奖励"), true, "treasure reward status") and ok
	ok = _assert_eq(_visible_text_has_english(reward_panel), false, "treasure reward text uses Chinese") and ok

	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.mode, "exploration", "treasure reward choice returns to exploration") and ok
	ok = _assert_eq(run_scene.run_state.deck_card_ids.size(), before_deck_size + 1, "treasure reward adds card to run deck") and ok
	return ok


func _test_run_scene_applies_healing_and_xp_pickups(run_scene) -> bool:
	var stats_label: Label = run_scene.find_child("StatsLabel", true, false)
	var reward_panel: VBoxContainer = run_scene.find_child("RewardPanel", true, false)
	var reward_choice_row: HBoxContainer = run_scene.find_child("RewardChoiceRow", true, false)
	var map = run_scene.run_state.dungeon_map
	run_scene.run_state.health = 22
	map.player_position = Vector2i(10, 3)
	run_scene.selected_position = map.player_position
	run_scene._refresh()

	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var ok := true
	ok = _assert_eq(run_scene.mode, "exploration", "healing pickup stays in exploration") and ok
	ok = _assert_eq(run_scene.run_state.health, 32, "healing pickup updates health") and ok
	ok = _assert_eq(run_scene.status_message.contains("恢复 10 生命"), true, "healing pickup status") and ok
	ok = _assert_eq(stats_label.text.contains("生命 32/40"), true, "healing pickup stats update") and ok

	map.player_position = Vector2i(3, 5)
	run_scene.selected_position = map.player_position
	run_scene.run_state.xp = 5
	run_scene._refresh()
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var before_deck_size: int = run_scene.run_state.deck_card_ids.size()
	ok = _assert_eq(run_scene.mode, "reward", "xp gem level-up enters reward mode") and ok
	ok = _assert_eq(run_scene.run_state.level, 2, "xp gem can level up") and ok
	ok = _assert_eq(reward_panel.visible, true, "xp gem reward panel visible") and ok
	ok = _assert_eq(reward_choice_row.get_child_count(), 3, "xp gem reward shows three choices") and ok
	ok = _assert_eq(run_scene.status_message.contains("获得 5 经验"), true, "xp gem status shows xp") and ok

	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.mode, "exploration", "xp gem reward returns to exploration") and ok
	ok = _assert_eq(run_scene.run_state.deck_card_ids.size(), before_deck_size + 1, "xp gem reward adds card") and ok
	return ok


func _test_run_scene_shows_run_end_on_defeat(run_scene) -> bool:
	run_scene.run_state.health = 1
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var ok := true
	run_scene._on_end_turn_pressed()
	await process_frame
	ok = _assert_eq(run_scene.combat_animation_locked, true, "defeat waits for enemy turn vfx") and ok
	await _wait_for_combat_animation(run_scene)

	var run_end_panel: VBoxContainer = run_scene.find_child("RunEndPanel", true, false)
	var run_end_title_label: Label = run_scene.find_child("RunEndTitleLabel", true, false)
	var restart_button: Button = run_scene.find_child("RestartButton", true, false)

	ok = _assert_eq(run_scene.mode, "run_end", "combat defeat enters run end mode") and ok
	ok = _assert_eq(run_end_panel.visible, true, "run end panel visible") and ok
	ok = _assert_eq(run_end_title_label.text, "冒险结束", "defeat run end title") and ok
	ok = _assert_eq(restart_button.text, "重新开始", "run end has restart button") and ok
	ok = _assert_eq(_visible_text_has_english(run_end_panel), false, "run end visible text uses Chinese") and ok
	return ok


func _test_run_scene_supports_combat_keyboard_selection(run_scene) -> bool:
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var combat_hand_row: HBoxContainer = run_scene.find_child("CombatHandRow", true, false)
	var combat_hand_title_label: Label = run_scene.find_child("CombatHandTitleLabel", true, false)
	var combat_selected_label: Label = run_scene.find_child("CombatSelectedLabel", true, false)
	run_scene.active_combat.enemies[0].max_health = 100
	run_scene.active_combat.enemies[0].health = 100
	run_scene.active_combat.mana = 10
	run_scene.active_combat.max_mana = 10
	run_scene._refresh()

	var selected_card_name: String = run_scene.active_combat.deck.hand[0].display_name
	var ok := true
	ok = _assert_eq(run_scene.selected_hand_index, 0, "combat starts with first card selected") and ok
	ok = _assert_eq(run_scene.combat_focus, "hand", "combat starts focused on hand") and ok
	ok = _assert_eq(combat_hand_title_label.text, "手牌（5）", "combat hand title is compact") and ok
	ok = _assert_eq(combat_selected_label.text.contains("已选：%s" % selected_card_name), true, "combat hud shows selected card") and ok
	ok = _assert_eq(_card_slot(combat_hand_row, 0).get_theme_constant("margin_top"), 0, "selected card floats up") and ok
	ok = _assert_eq(_card_slot(combat_hand_row, 1).get_theme_constant("margin_top"), CARD_SELECTED_LIFT, "unselected card stays lower") and ok
	ok = _assert_eq(_card_slot(combat_hand_row, 1).rotation_degrees < 0.0, true, "unselected hand cards fan out") and ok
	var animated_card_button := _card_button(combat_hand_row, 0)
	var animated_card_art: TextureRect = animated_card_button.find_child("CardArt", true, false)
	var animated_card_texture := animated_card_art.texture if animated_card_art != null else null
	var animated_enemy_portrait: TextureRect = run_scene.find_child("EnemyPortrait", true, false)
	var animated_enemy_texture := animated_enemy_portrait.texture if animated_enemy_portrait != null else null
	var animated_player_portrait: TextureRect = run_scene.find_child("PlayerCombatPortrait", true, false)
	var animated_player_texture := animated_player_portrait.texture if animated_player_portrait != null else null
	run_scene._process(0.20)
	ok = _assert_ne(animated_card_art, null, "combat card has generated art") and ok
	if animated_card_art != null:
		ok = _assert_ne(animated_card_texture, null, "combat card art has generated texture") and ok
		ok = _assert_eq(animated_card_art.texture != animated_card_texture, true, "combat card art advances animation frame") and ok
	ok = _assert_ne(animated_enemy_portrait, null, "combat enemy has generated portrait") and ok
	if animated_enemy_portrait != null:
		ok = _assert_eq(animated_enemy_portrait.texture != animated_enemy_texture, true, "combat enemy portrait advances animation frame") and ok
	ok = _assert_ne(animated_player_portrait, null, "combat player has generated portrait") and ok
	if animated_player_portrait != null:
		ok = _assert_eq(animated_player_portrait.texture != animated_player_texture, true, "combat player portrait advances animation frame") and ok

	var attack_index := _first_attack_card_index(run_scene.active_combat.deck.hand)
	ok = _assert_eq(attack_index >= 0, true, "combat hand has attack card") and ok
	if attack_index >= 0:
		var attack_button := _card_button(combat_hand_row, attack_index)
		ok = _assert_eq(attack_button.tooltip_text.contains("预览总伤害："), true, "attack card keeps preview damage details") and ok
		ok = _assert_eq(_node_text_contains(attack_button, "倍率 100%"), true, "card shows base multiplier") and ok
		run_scene.active_combat.combo.chain = 1
		run_scene.active_combat.combo.last_cost = 0
		run_scene._refresh()
		attack_button = _card_button(combat_hand_row, attack_index)
		var attack_card = run_scene.active_combat.deck.hand[attack_index]
		var expected_preview_damage: int = run_scene._preview_card_damage(attack_card)
		var combo_style: StyleBoxFlat = attack_button.get_theme_stylebox("normal") as StyleBoxFlat
		ok = _assert_eq(attack_button.tooltip_text.contains("预览总伤害：%s" % expected_preview_damage), true, "combo card keeps scaled preview damage details") and ok
		ok = _assert_eq(_node_text_contains(attack_button, "倍率 200%"), true, "combo card shows combo multiplier") and ok
		ok = _assert_eq(combo_style.border_color, Color(0.95, 0.72, 0.20), "combo multiplier highlights card") and ok
		var skipped_cost_index := _first_card_cost_index(run_scene.active_combat.deck.hand, 2)
		ok = _assert_eq(skipped_cost_index >= 0, true, "combat hand has a skipped cost card") and ok
		if skipped_cost_index >= 0:
			var skipped_cost_button := _card_button(combat_hand_row, skipped_cost_index)
			var skipped_cost_style: StyleBoxFlat = skipped_cost_button.get_theme_stylebox("normal") as StyleBoxFlat
			ok = _assert_eq(_node_text_contains(skipped_cost_button, "倍率 100%"), true, "skipped cost does not gain combo multiplier") and ok
			ok = _assert_eq(skipped_cost_style.border_color, Color(0.08, 0.09, 0.10), "skipped cost does not highlight card") and ok
		run_scene.active_combat.combo.reset()
		run_scene._refresh()

	_press_key(run_scene, KEY_RIGHT)
	ok = _assert_eq(run_scene.selected_hand_index, 1, "right key selects next card") and ok
	ok = _assert_eq(_card_slot(combat_hand_row, 1).get_theme_constant("margin_top"), 0, "right-selected card floats up") and ok
	ok = _assert_eq(_card_slot(combat_hand_row, 0).get_theme_constant("margin_top"), CARD_SELECTED_LIFT, "previous card lowers after selection moves") and ok
	_press_key(run_scene, KEY_D)
	ok = _assert_eq(run_scene.selected_hand_index, 2, "D key selects next card") and ok
	_press_key(run_scene, KEY_LEFT)
	ok = _assert_eq(run_scene.selected_hand_index, 1, "left key selects previous card") and ok
	_press_key(run_scene, KEY_A)
	ok = _assert_eq(run_scene.selected_hand_index, 0, "A key selects previous card") and ok

	_press_key(run_scene, KEY_DOWN)
	ok = _assert_eq(run_scene.combat_focus, "end_turn", "down key selects end turn") and ok
	ok = _assert_eq(combat_selected_label.text.contains("已选：结束回合"), true, "combat hud shows end turn selection") and ok
	_press_key(run_scene, KEY_UP)
	ok = _assert_eq(run_scene.combat_focus, "hand", "up key returns to hand") and ok
	ok = _assert_eq(run_scene.selected_hand_index, 0, "returning to hand keeps selected card") and ok

	run_scene._on_card_hovered(2)
	ok = _assert_eq(run_scene.selected_hand_index, 2, "mouse hover syncs selected card") and ok
	ok = _assert_eq(run_scene.combat_focus, "hand", "mouse hover returns focus to hand") and ok

	var hand_size_before_space: int = run_scene.active_combat.deck.hand.size()
	var space_card_name: String = run_scene.active_combat.deck.hand[run_scene.selected_hand_index].display_name
	_press_key(run_scene, KEY_SPACE)
	await process_frame
	ok = _assert_eq(run_scene.combat_animation_locked, true, "space play waits for combat vfx") and ok
	await _wait_for_combat_animation(run_scene)
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), hand_size_before_space - 1, "space plays selected card") and ok
	ok = _assert_eq(run_scene.combat_log.contains(space_card_name), true, "space play log uses selected card") and ok

	run_scene.active_combat.mana = 10
	run_scene._on_card_hovered(0)
	var hand_size_before_enter: int = run_scene.active_combat.deck.hand.size()
	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.combat_animation_locked, true, "enter play waits for combat vfx") and ok
	await _wait_for_combat_animation(run_scene)
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), hand_size_before_enter - 1, "enter plays selected card") and ok
	ok = _assert_eq(combat_hand_row.get_child_count() >= 3, true, "combat hand stays interactive after keyboard play") and ok
	return ok


func _test_run_scene_supports_end_turn_keyboard_selection(run_scene) -> bool:
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	run_scene._try_move(Vector2i.RIGHT)
	await process_frame

	var card_use_fx_layer: Control = run_scene.find_child("CardUseFxLayer", true, false)
	var ok := true
	run_scene.active_combat.mana = 0
	run_scene.selected_hand_index = 0
	run_scene.combat_focus = "hand"
	run_scene._refresh()
	var turn_before_auto_end: int = run_scene.active_combat.turn
	var fx_count_before_auto_end := card_use_fx_layer.get_child_count() if card_use_fx_layer != null else 0
	_press_key(run_scene, KEY_SPACE)
	await process_frame
	ok = _assert_eq(run_scene.combat_animation_locked, true, "auto end waits for enemy turn vfx") and ok
	ok = _assert_ne(card_use_fx_layer, null, "enemy turn has vfx layer") and ok
	if card_use_fx_layer != null:
		ok = _assert_eq(card_use_fx_layer.get_child_count() > fx_count_before_auto_end, true, "enemy turn spawns attack and player-hit vfx") and ok
	await _wait_for_combat_animation(run_scene)
	ok = _assert_eq(run_scene.active_combat.turn, turn_before_auto_end + 1, "unaffordable selected card auto ends turn") and ok
	ok = _assert_eq(run_scene.active_combat.mana, run_scene.active_combat.max_mana, "auto end starts next player turn") and ok
	ok = _assert_eq(run_scene.combat_log.contains("法力不足，自动结束回合"), true, "auto end log explains mana") and ok

	var turn_before_manual_end: int = run_scene.active_combat.turn
	_press_key(run_scene, KEY_S)
	ok = _assert_eq(run_scene.combat_focus, "end_turn", "S key selects end turn") and ok
	_press_key(run_scene, KEY_ENTER)
	await process_frame
	ok = _assert_eq(run_scene.combat_animation_locked, true, "manual end waits for enemy turn vfx") and ok
	await _wait_for_combat_animation(run_scene)
	ok = _assert_eq(run_scene.active_combat.turn, turn_before_manual_end + 1, "enter confirms selected end turn") and ok
	ok = _assert_eq(run_scene.combat_log.contains("手动结束回合"), true, "manual end turn log") and ok
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
	var combat_selected_label: Label = run_scene.find_child("CombatSelectedLabel", true, false)
	var combat_mana_label: Label = run_scene.find_child("CombatManaLabel", true, false)
	var combat_combo_label: Label = run_scene.find_child("CombatComboLabel", true, false)
	var combat_title_label: Label = run_scene.find_child("CombatTitleLabel", true, false)
	var combat_enemy_label: Label = run_scene.find_child("EnemyState", true, false)
	var enemy_rows: BoxContainer = run_scene.find_child("EnemyRows", true, false)
	var card_use_fx_layer: Control = run_scene.find_child("CardUseFxLayer", true, false)
	var player_state_panel: PanelContainer = run_scene.find_child("PlayerStatePanel", true, false)
	var player_hud_panel: PanelContainer = run_scene.find_child("PlayerHudPanel", true, false)
	var player_health_bar: ProgressBar = run_scene.find_child("PlayerHealthBar", true, false)
	var action_hud: PanelContainer = run_scene.find_child("CombatActionHud", true, false)
	var stats_label: Label = run_scene.find_child("StatsLabel", true, false)

	var ok := true
	ok = _assert_eq(run_scene.mode, "combat", "run scene enters combat") and ok
	ok = _assert_eq(run_scene.active_encounter_id, "enemy_01", "active encounter id") and ok
	ok = _assert_eq(status_label.text, "遭遇已开始。", "combat start does not leak internal id") and ok
	ok = _assert_eq(combat_panel.visible, true, "combat panel visible") and ok
	var selected_card_summary: String = run_scene._selected_card_summary()
	ok = _assert_eq(combat_hand_title_label.text, "手牌（5）", "combat hand title") and ok
	ok = _assert_eq(combat_selected_label.text, "已选：%s" % selected_card_summary, "combat selected hud") and ok
	ok = _assert_eq(combat_mana_label.text, "法力 3/3", "combat mana hud") and ok
	ok = _assert_eq(combat_combo_label.text, "连击 0", "combat combo hud") and ok
	ok = _assert_eq(combat_hand_row.get_child_count(), 5, "combat hand buttons") and ok
	ok = _assert_eq(combat_title_label.text, "遭遇：走卒", "combat title") and ok
	ok = _assert_eq(combat_enemy_label.text, "战斗阵列", "combat enemy panel title") and ok
	ok = _assert_ne(card_use_fx_layer, null, "combat has card use vfx layer") and ok
	ok = _assert_eq(enemy_rows.get_child_count(), 2, "combat enemy panel splits rows") and ok
	ok = _assert_eq(enemy_rows.get_child(0).name, "EnemyRow_01", "rear row renders above front row") and ok
	ok = _assert_eq(enemy_rows.get_child(1).name, "EnemyRow_00", "front row renders at the bottom") and ok
	ok = _assert_eq(run_scene._enemy_row_name(2), "第3排", "enemy row labels support more than two rows") and ok
	var rear_cards: HBoxContainer = enemy_rows.get_child(0).find_child("EnemyCards_01", true, false)
	var front_cards: HBoxContainer = enemy_rows.get_child(1).find_child("EnemyCards_00", true, false)
	ok = _assert_eq(front_cards.get_child_count(), 1, "front row has separate enemy card") and ok
	ok = _assert_eq(rear_cards.get_child_count(), 1, "rear row has separate enemy card") and ok
	var target_state: Label = front_cards.get_child(0).find_child("EnemyStateLabel", true, false)
	var rear_state: Label = rear_cards.get_child(0).find_child("EnemyStateLabel", true, false)
	ok = _assert_eq(target_state.text.contains("当前目标"), true, "single-target card auto target is marked") and ok
	ok = _assert_eq(target_state.text.contains("攻 4"), true, "front enemy shows attack intent") and ok
	ok = _assert_eq(rear_state.text, "待命", "rear row is waiting") and ok
	ok = _assert_eq(player_state_panel, null, "combat has no player state panel") and ok
	ok = _assert_ne(player_hud_panel, null, "combat has player hud rail") and ok
	ok = _assert_ne(action_hud, null, "combat has action hud rail") and ok
	ok = _assert_ne(player_health_bar, null, "player hud uses health bar") and ok
	if player_health_bar != null:
		ok = _assert_eq(player_health_bar.value, 40.0, "player health bar is synced") and ok
	ok = _assert_eq(_visible_text_has_english(combat_hand_row), false, "combat hand text uses Chinese") and ok
	ok = _assert_eq(_visible_text_has_english(run_scene), false, "combat visible text uses Chinese") and ok

	run_scene._on_card_pressed(0)
	await process_frame

	ok = _assert_eq(run_scene.combat_animation_locked, true, "card press waits for combat vfx before final refresh") and ok
	ok = _assert_eq(card_use_fx_layer.get_child_count() > 0, true, "playing a card spawns vfx nodes") and ok
	await _wait_for_combat_animation(run_scene)
	ok = _assert_eq(run_scene.active_combat.mana, 2, "playing first card spends mana") and ok
	ok = _assert_eq(run_scene.active_combat.deck.hand.size(), 4, "playing first card removes hand card") and ok

	var winning_attack_index := _first_attack_card_index(run_scene.active_combat.deck.hand)
	ok = _assert_eq(winning_attack_index >= 0, true, "combat has a winning attack card") and ok
	if winning_attack_index >= 0:
		var target_index: int = run_scene.active_combat.primary_target_index()
		ok = _assert_eq(target_index >= 0, true, "combat has a target for winning card") and ok
		for i in range(run_scene.active_combat.enemies.size()):
			run_scene.active_combat.enemies[i].health = 0
		if target_index >= 0:
			run_scene.active_combat.enemies[target_index].health = 1
		run_scene.active_combat.mana = 10
		run_scene.selected_hand_index = winning_attack_index
		run_scene.combat_focus = "hand"
		run_scene._refresh()
		run_scene._on_card_pressed(winning_attack_index)
		await process_frame
		ok = _assert_eq(run_scene.combat_animation_locked, true, "combat victory waits for card vfx") and ok
		ok = _assert_eq(run_scene.mode, "combat", "combat remains visible while victory vfx plays") and ok
		await _wait_for_combat_animation(run_scene)
	await process_frame

	ok = _assert_eq(run_scene.mode, "exploration", "run scene returns to exploration") and ok
	ok = _assert_eq(run_scene.run_state.dungeon_map.active_enemy_count(), 11, "victory removes map enemy") and ok
	ok = _assert_eq(run_scene.run_state.xp, 3, "victory grants visible xp") and ok
	ok = _assert_eq(status_label.text.contains("获得 3 经验"), true, "victory status shows xp reward") and ok
	ok = _assert_eq(stats_label.text.contains("经验 3/10"), true, "stats label shows updated xp") and ok
	return ok


func _press_key(run_scene, keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	run_scene._unhandled_key_input(event)


func _wait_for_combat_animation(run_scene) -> void:
	var deadline_msec := Time.get_ticks_msec() + 3000
	while run_scene.combat_animation_locked and Time.get_ticks_msec() < deadline_msec:
		await process_frame


func _card_slot(combat_hand_row: HBoxContainer, index: int) -> MarginContainer:
	return combat_hand_row.get_child(index) as MarginContainer


func _card_button(combat_hand_row: HBoxContainer, index: int) -> Button:
	return _card_slot(combat_hand_row, index).get_child(0) as Button


func _first_attack_card_index(cards: Array) -> int:
	for i in range(cards.size()):
		if cards[i].base_damage > 0:
			return i
	return -1


func _first_card_cost_index(cards: Array, cost: int) -> int:
	for i in range(cards.size()):
		if cards[i].cost == cost:
			return i
	return -1


func _defeat_all_active_enemies(run_scene) -> void:
	for enemy in run_scene.active_combat.enemies:
		enemy.health = 0


func _map_cell_button(run_scene, position: Vector2i) -> Button:
	var map_grid: GridContainer = run_scene.find_child("MapGrid", true, false)
	return map_grid.get_child(position.y * map_grid.columns + position.x) as Button


func _map_cell_glyph(button: Button) -> Label:
	return button.find_child("CellGlyph", false, false) as Label


func _map_cell_visual(button: Button) -> TextureRect:
	return button.find_child("CellVisual", false, false) as TextureRect


func _stage_1_boss_id(map) -> String:
	for enemy_id in map.enemy_positions.keys():
		var enemy_position: Vector2i = map.enemy_positions[enemy_id]
		var tile = map.get_tile(enemy_position)
		if tile != null and tile.tile_type == DungeonTile.TileType.BOSS:
			return enemy_id
	return ""


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


func _node_text_contains(node: Node, expected_text: String) -> bool:
	if node is Button:
		if (node as Button).text.contains(expected_text):
			return true
	if node is Label:
		if (node as Label).text.contains(expected_text):
			return true
	for child in node.get_children():
		if _node_text_contains(child, expected_text):
			return true
	return false


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
