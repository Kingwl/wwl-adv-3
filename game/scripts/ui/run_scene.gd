class_name RunScene
extends Control

const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")

const CELL_SIZE := Vector2(48, 48)
const COLOR_WALL := Color(0.12, 0.13, 0.15)
const COLOR_FLOOR := Color(0.24, 0.25, 0.27)
const COLOR_PLAYER := Color(0.18, 0.48, 0.82)
const COLOR_ENEMY := Color(0.63, 0.22, 0.20)
const COLOR_ELITE := Color(0.78, 0.38, 0.14)
const COLOR_BOSS := Color(0.50, 0.18, 0.55)
const COLOR_PICKUP := Color(0.18, 0.50, 0.32)
const COLOR_RUN_END := Color(0.18, 0.19, 0.22)
const COLOR_RUN_END_BORDER := Color(0.80, 0.66, 0.24)
const COLOR_EXIT_LOCKED := Color(0.42, 0.40, 0.33)
const COLOR_EXIT_OPEN := Color(0.80, 0.66, 0.24)
const COLOR_SELECTED := Color(0.92, 0.82, 0.38)
const COLOR_ENEMY_PANEL := Color(0.24, 0.07, 0.07)
const COLOR_ENEMY_BORDER := Color(0.76, 0.20, 0.18)
const COLOR_COMBO_HIGHLIGHT := Color(0.95, 0.72, 0.20)
const CARD_SIZE := Vector2(150, 170)
const CARD_SELECTED_LIFT := 10
const CARD_SLOT_SIZE := Vector2(CARD_SIZE.x, CARD_SIZE.y + CARD_SELECTED_LIFT)
const REWARD_CHOICE_SIZE := Vector2(220, 240)
const UI_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"
const COMBAT_FOCUS_HAND := "hand"
const COMBAT_FOCUS_END_TURN := "end_turn"

var controller: RunController = RunController.new()
var run_state: RunState = RunState.new()
var selected_position: Vector2i = Vector2i.ZERO
var mode: String = "exploration"
var active_encounter_id: String = ""
var active_encounter_position: Vector2i = Vector2i.ZERO
var active_combat: CombatState
var combat_log: String = ""
var status_message: String = "探索中。"
var combat_focus: String = COMBAT_FOCUS_HAND
var selected_hand_index: int = -1
var selected_reward_index: int = 0

var map_panel: VBoxContainer
var side_panel: VBoxContainer
var combat_panel: VBoxContainer
var reward_panel: VBoxContainer
var run_end_panel: VBoxContainer
var map_grid: GridContainer
var stage_label: Label
var stats_label: Label
var selected_label: Label
var status_label: Label
var action_button: Button
var combat_title_label: Label
var combat_enemy_panel: PanelContainer
var combat_enemy_label: Label
var combat_enemy_rows: VBoxContainer
var combat_hand_title_label: Label
var combat_hand_row: HBoxContainer
var combat_log_label: Label
var end_turn_button: Button
var reward_title_label: Label
var reward_summary_label: Label
var reward_choice_row: HBoxContainer
var run_end_title_label: Label
var run_end_summary_label: Label
var restart_button: Button
var cell_buttons: Dictionary = {}


func _ready() -> void:
	_apply_ui_font()
	controller.setup(1001)
	controller.start_stage_1()
	_sync_from_controller()
	selected_position = run_state.dungeon_map.player_position
	_build_layout()
	_refresh()


func _apply_ui_font() -> void:
	var font := _load_ui_font()
	if font == null:
		push_warning("Could not load UI font: %s" % UI_FONT_PATH)
		return

	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 16
	theme = ui_theme


func _load_ui_font() -> FontFile:
	var imported_font := load(UI_FONT_PATH) as FontFile
	if imported_font != null:
		return imported_font

	var dynamic_font := FontFile.new()
	if dynamic_font.load_dynamic_font(UI_FONT_PATH) == OK:
		return dynamic_font
	return null


func _sync_from_controller() -> void:
	run_state = controller.run_state
	mode = controller.mode
	active_encounter_id = controller.active_encounter_id
	active_encounter_position = controller.active_encounter_position
	active_combat = controller.active_combat


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.is_pressed() or key_event.is_echo():
		return

	if mode == "combat":
		_handle_combat_key(key_event.keycode)
	elif mode == "reward":
		_handle_reward_key(key_event.keycode)
	elif mode == "run_end":
		_handle_run_end_key(key_event.keycode)
	elif mode == "exploration":
		_handle_exploration_key(key_event.keycode)


func _handle_exploration_key(keycode: int) -> void:
	if keycode == KEY_UP or keycode == KEY_W:
		_try_move(Vector2i.UP)
	elif keycode == KEY_DOWN or keycode == KEY_S:
		_try_move(Vector2i.DOWN)
	elif keycode == KEY_LEFT or keycode == KEY_A:
		_try_move(Vector2i.LEFT)
	elif keycode == KEY_RIGHT or keycode == KEY_D:
		_try_move(Vector2i.RIGHT)


func _handle_combat_key(keycode: int) -> void:
	if keycode == KEY_LEFT or keycode == KEY_A:
		_move_card_selection(-1)
	elif keycode == KEY_RIGHT or keycode == KEY_D:
		_move_card_selection(1)
	elif keycode == KEY_DOWN or keycode == KEY_S:
		_select_end_turn()
	elif keycode == KEY_UP or keycode == KEY_W:
		_select_hand()
	elif keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		_activate_combat_selection()


func _handle_reward_key(keycode: int) -> void:
	if keycode == KEY_LEFT or keycode == KEY_A:
		_move_reward_selection(-1)
	elif keycode == KEY_RIGHT or keycode == KEY_D:
		_move_reward_selection(1)
	elif keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		_activate_reward_selection()


func _handle_run_end_key(keycode: int) -> void:
	if keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER or keycode == KEY_R:
		_restart_run()


func _build_layout() -> void:
	var root := MarginContainer.new()
	root.name = "RunRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var main_row := HBoxContainer.new()
	main_row.name = "MainRow"
	main_row.add_theme_constant_override("separation", 24)
	root.add_child(main_row)

	map_panel = VBoxContainer.new()
	map_panel.name = "MapPanel"
	map_panel.add_theme_constant_override("separation", 12)
	main_row.add_child(map_panel)

	stage_label = Label.new()
	stage_label.name = "StageLabel"
	stage_label.add_theme_font_size_override("font_size", 24)
	map_panel.add_child(stage_label)

	map_grid = GridContainer.new()
	map_grid.name = "MapGrid"
	map_grid.columns = run_state.dungeon_map.width
	map_grid.add_theme_constant_override("h_separation", 3)
	map_grid.add_theme_constant_override("v_separation", 3)
	map_panel.add_child(map_grid)

	side_panel = VBoxContainer.new()
	side_panel.name = "SidePanel"
	side_panel.custom_minimum_size = Vector2(330, 0)
	side_panel.add_theme_constant_override("separation", 14)
	main_row.add_child(side_panel)

	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(stats_label)

	selected_label = Label.new()
	selected_label.name = "SelectedLabel"
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(selected_label)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(status_label)

	action_button = Button.new()
	action_button.name = "ActionButton"
	action_button.text = "自动遭遇"
	action_button.disabled = true
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.pressed.connect(_on_action_pressed)
	side_panel.add_child(action_button)

	var movement_row := HBoxContainer.new()
	movement_row.name = "MovementRow"
	movement_row.add_theme_constant_override("separation", 8)
	side_panel.add_child(movement_row)
	_add_move_button(movement_row, "上", Vector2i.UP)
	_add_move_button(movement_row, "下", Vector2i.DOWN)
	_add_move_button(movement_row, "左", Vector2i.LEFT)
	_add_move_button(movement_row, "右", Vector2i.RIGHT)

	var debug_label := Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "图例：我 玩家 / 敌 敌人 / 精 精英 / 首 首领 / 宝 宝箱 / 疗 治疗 / 晶 经验宝石 / 锻 锻造 / 出 出口"
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(debug_label)

	_build_combat_panel(main_row)
	_build_reward_panel(main_row)
	_build_run_end_panel(main_row)
	_create_cells()


func _build_combat_panel(parent: Control) -> void:
	combat_panel = VBoxContainer.new()
	combat_panel.name = "CombatPanel"
	combat_panel.custom_minimum_size = Vector2(1120, 0)
	combat_panel.add_theme_constant_override("separation", 18)
	combat_panel.visible = false
	parent.add_child(combat_panel)

	combat_title_label = Label.new()
	combat_title_label.name = "CombatTitleLabel"
	combat_title_label.add_theme_font_size_override("font_size", 28)
	combat_panel.add_child(combat_title_label)

	combat_enemy_panel = _create_combat_state_panel("EnemyStatePanel", COLOR_ENEMY_PANEL, COLOR_ENEMY_BORDER)
	var enemy_content := VBoxContainer.new()
	enemy_content.name = "EnemyQueueContent"
	enemy_content.add_theme_constant_override("separation", 10)
	combat_enemy_panel.add_child(enemy_content)
	combat_enemy_label = Label.new()
	combat_enemy_label.name = "EnemyState"
	combat_enemy_label.text = "敌方队列"
	combat_enemy_label.add_theme_font_size_override("font_size", 18)
	enemy_content.add_child(combat_enemy_label)
	combat_enemy_rows = VBoxContainer.new()
	combat_enemy_rows.name = "EnemyRows"
	combat_enemy_rows.add_theme_constant_override("separation", 10)
	enemy_content.add_child(combat_enemy_rows)
	combat_panel.add_child(combat_enemy_panel)

	combat_hand_title_label = Label.new()
	combat_hand_title_label.name = "CombatHandTitleLabel"
	combat_hand_title_label.text = "手牌"
	combat_hand_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_hand_title_label.add_theme_font_size_override("font_size", 22)
	combat_panel.add_child(combat_hand_title_label)

	combat_hand_row = HBoxContainer.new()
	combat_hand_row.name = "CombatHandRow"
	combat_hand_row.add_theme_constant_override("separation", 12)
	combat_panel.add_child(combat_hand_row)

	end_turn_button = Button.new()
	end_turn_button.name = "EndTurnButton"
	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(180, 42)
	end_turn_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	combat_panel.add_child(end_turn_button)

	combat_log_label = Label.new()
	combat_log_label.name = "CombatLogLabel"
	combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_panel.add_child(combat_log_label)


func _build_reward_panel(parent: Control) -> void:
	reward_panel = VBoxContainer.new()
	reward_panel.name = "RewardPanel"
	reward_panel.custom_minimum_size = Vector2(920, 0)
	reward_panel.add_theme_constant_override("separation", 18)
	reward_panel.visible = false
	parent.add_child(reward_panel)

	reward_title_label = Label.new()
	reward_title_label.name = "RewardTitleLabel"
	reward_title_label.add_theme_font_size_override("font_size", 30)
	reward_panel.add_child(reward_title_label)

	reward_summary_label = Label.new()
	reward_summary_label.name = "RewardSummaryLabel"
	reward_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_summary_label.add_theme_font_size_override("font_size", 18)
	reward_panel.add_child(reward_summary_label)

	reward_choice_row = HBoxContainer.new()
	reward_choice_row.name = "RewardChoiceRow"
	reward_choice_row.add_theme_constant_override("separation", 14)
	reward_panel.add_child(reward_choice_row)


func _build_run_end_panel(parent: Control) -> void:
	run_end_panel = VBoxContainer.new()
	run_end_panel.name = "RunEndPanel"
	run_end_panel.custom_minimum_size = Vector2(720, 0)
	run_end_panel.add_theme_constant_override("separation", 18)
	run_end_panel.visible = false
	parent.add_child(run_end_panel)

	var frame := PanelContainer.new()
	frame.name = "RunEndFrame"
	frame.custom_minimum_size = Vector2(620, 260)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_RUN_END
	style.border_color = COLOR_RUN_END_BORDER
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	frame.add_theme_stylebox_override("panel", style)
	run_end_panel.add_child(frame)

	var content := VBoxContainer.new()
	content.name = "RunEndContent"
	content.add_theme_constant_override("separation", 14)
	frame.add_child(content)

	run_end_title_label = Label.new()
	run_end_title_label.name = "RunEndTitleLabel"
	run_end_title_label.add_theme_font_size_override("font_size", 32)
	content.add_child(run_end_title_label)

	run_end_summary_label = Label.new()
	run_end_summary_label.name = "RunEndSummaryLabel"
	run_end_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_end_summary_label.add_theme_font_size_override("font_size", 18)
	content.add_child(run_end_summary_label)

	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(180, 42)
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.pressed.connect(_restart_run)
	content.add_child(restart_button)


func _create_combat_state_panel(panel_name: String, fill_color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = Vector2(620, 132)
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_combat_state_label(label_name: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.name = label_name
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(580, 104)
	label.add_theme_font_size_override("normal_font_size", 18)
	return label


func _add_move_button(parent: Control, label: String, direction: Vector2i) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(56, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _try_move(direction))
	parent.add_child(button)


func _create_cells() -> void:
	for child in map_grid.get_children():
		map_grid.remove_child(child)
		child.queue_free()
	cell_buttons.clear()
	map_grid.columns = run_state.dungeon_map.width
	for y in range(run_state.dungeon_map.height):
		for x in range(run_state.dungeon_map.width):
			var position := Vector2i(x, y)
			var button := Button.new()
			button.name = "Cell_%02d_%02d" % [x, y]
			button.custom_minimum_size = CELL_SIZE
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(_on_cell_activated.bind(position))
			cell_buttons[position] = button
			map_grid.add_child(button)


func _refresh() -> void:
	var map: DungeonMapState = run_state.dungeon_map
	var in_combat := mode == RunController.MODE_COMBAT
	var in_reward := mode == RunController.MODE_REWARD
	var in_run_end := mode == RunController.MODE_RUN_END
	_ensure_map_cells()
	map_panel.visible = not in_combat and not in_reward and not in_run_end
	side_panel.visible = not in_combat and not in_reward and not in_run_end
	combat_panel.visible = in_combat
	reward_panel.visible = in_reward
	run_end_panel.visible = in_run_end

	stage_label.text = "%s  种子：%s" % [run_state.current_stage.display_name, str(run_state.current_stage.seed)]
	stats_label.text = "生命 %s/%s\n等级 %s  经验 %s/%s\n敌人 %s/%s  拾取物 %s/%s\n出口 %s" % [
		run_state.health,
		run_state.max_health,
		run_state.level,
		run_state.xp,
		run_state.next_level_xp,
		map.active_enemy_count(),
		run_state.current_stage.enemy_budget,
		map.active_pickup_count(),
		run_state.current_stage.pickup_budget,
		"已解锁" if map.is_exit_unlocked() else "锁定",
	]

	for position in cell_buttons.keys():
		_refresh_cell(position)

	if in_combat:
		_refresh_combat()
	elif in_reward:
		_refresh_reward()
	elif in_run_end:
		_refresh_run_end()
	else:
		_refresh_selected()


func _ensure_map_cells() -> void:
	if map_grid == null or run_state.dungeon_map == null:
		return
	var expected_count := run_state.dungeon_map.width * run_state.dungeon_map.height
	if map_grid.columns != run_state.dungeon_map.width or cell_buttons.size() != expected_count:
		_create_cells()


func _refresh_combat() -> void:
	_clear_combat_hand()
	_clear_enemy_rows()
	if active_combat == null:
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		combat_title_label.text = "战斗"
		combat_enemy_label.text = "敌方队列"
		_add_empty_enemy_row()
		combat_hand_title_label.text = "手牌"
		end_turn_button.disabled = true
		_style_end_turn_button(false)
		return

	_clamp_selected_hand_index()
	var selected_card_summary := _selected_card_summary()
	var target_enemy := _current_target_enemy()
	combat_title_label.text = "遭遇：%s" % (target_enemy.display_name if target_enemy != null else "敌人")
	combat_enemy_label.text = "敌方队列"
	_refresh_enemy_rows()
	combat_hand_title_label.text = "手牌（%s）  已选：%s  生命 %s/%s | 护甲 %s | 法力 %s/%s | 连击 %s" % [
		active_combat.deck.hand.size(),
		selected_card_summary,
		active_combat.player.health,
		active_combat.player.max_health,
		active_combat.player.block,
		active_combat.mana,
		active_combat.max_mana,
		active_combat.combo.chain,
	]
	combat_log_label.text = combat_log
	end_turn_button.disabled = active_combat.is_victory() or active_combat.is_defeat()
	_style_end_turn_button(combat_focus == COMBAT_FOCUS_END_TURN)

	for i in range(active_combat.deck.hand.size()):
		var card = active_combat.deck.hand[i]
		var is_selected := combat_focus == COMBAT_FOCUS_HAND and i == selected_hand_index
		var has_combo_multiplier := _preview_card_multiplier_basis_points(card) > 100
		var slot := MarginContainer.new()
		slot.name = "CardSlot_%02d_%s" % [i, card.id]
		slot.custom_minimum_size = CARD_SLOT_SIZE
		_style_card_slot(slot, is_selected)
		var button := Button.new()
		button.name = "Card_%02d_%s" % [i, card.id]
		button.custom_minimum_size = CARD_SIZE
		button.text = _card_button_text(card)
		button.add_theme_font_size_override("font_size", 16)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = card.cost > active_combat.mana or active_combat.is_victory() or active_combat.is_defeat()
		button.mouse_entered.connect(_on_card_hovered.bind(i))
		button.pressed.connect(_on_card_pressed.bind(i))
		_style_card_button(button, card, has_combo_multiplier)
		slot.add_child(button)
		combat_hand_row.add_child(slot)


func _refresh_reward() -> void:
	_clear_reward_choices()
	var choices: Array = controller.pending_reward_choices
	_clamp_selected_reward_index()
	reward_title_label.text = controller.active_reward_title
	if reward_title_label.text == "":
		reward_title_label.text = "奖励"
	reward_summary_label.text = "生命 %s/%s  等级 %s  经验 %s/%s  牌组 %s 张" % [
		run_state.health,
		run_state.max_health,
		run_state.level,
		run_state.xp,
		run_state.next_level_xp,
		run_state.deck_card_ids.size(),
	]
	if choices.is_empty():
		reward_summary_label.text = "暂无可选奖励。"
		return

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.name = "RewardChoice_%02d_%s" % [i, str(choice.get("card_id", ""))]
		button.custom_minimum_size = REWARD_CHOICE_SIZE
		button.text = _reward_choice_text(choice)
		button.add_theme_font_size_override("font_size", 18)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_entered.connect(_on_reward_choice_hovered.bind(i))
		button.pressed.connect(_on_reward_choice_pressed.bind(i))
		_style_reward_choice_button(button, choice, i == selected_reward_index)
		reward_choice_row.add_child(button)


func _refresh_run_end() -> void:
	run_end_title_label.text = controller.active_run_end_title
	if run_end_title_label.text == "":
		run_end_title_label.text = "冒险结束"
	var summary := controller.active_run_end_summary
	if summary == "":
		summary = status_message
	run_end_summary_label.text = "%s\n生命 %s/%s  等级 %s  经验 %s/%s\n已到达：%s  牌组 %s 张" % [
		summary,
		run_state.health,
		run_state.max_health,
		run_state.level,
		run_state.xp,
		run_state.next_level_xp,
		run_state.current_stage.display_name,
		run_state.deck_card_ids.size(),
	]


func _refresh_cell(position: Vector2i) -> void:
	var button: Button = cell_buttons[position]
	var map: DungeonMapState = run_state.dungeon_map
	var tile: DungeonTile = map.get_tile(position)
	button.text = _cell_text(position, tile)
	button.tooltip_text = _tile_description(tile)
	button.disabled = tile.tile_type == DungeonTile.TileType.WALL

	var color := _tile_color(tile)
	if position == map.player_position:
		color = COLOR_PLAYER
	var is_selected := position == selected_position
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.56, 0.58))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_set_button_color(button, color, is_selected)


func _refresh_selected() -> void:
	var map: DungeonMapState = run_state.dungeon_map
	var tile: DungeonTile = map.get_tile(selected_position)
	if tile == null:
		selected_label.text = "未选择格子"
		action_button.disabled = true
		return

	selected_label.text = "选中 %s,%s\n%s\n对象：%s" % [
		selected_position.x,
		selected_position.y,
		_tile_description(tile),
		_tile_object_label(tile),
	]

	if mode == "combat":
		status_label.text = status_message
		action_button.text = "返回探索"
		action_button.disabled = false
		return

	var adjacent_enemy := tile.is_enemy_tile() and _is_adjacent(selected_position, map.player_position)
	if adjacent_enemy:
		status_label.text = "移动到敌人格会自动遭遇。"
		action_button.text = "自动遭遇"
		action_button.disabled = true
	else:
		status_label.text = status_message
		action_button.text = "自动遭遇"
		action_button.disabled = true


func _set_status_message(message: String) -> void:
	status_message = message
	if status_label != null:
		status_label.text = status_message


func _try_move(direction: Vector2i) -> void:
	var result := controller.move_player(direction)
	_sync_from_controller()
	if result.has("to"):
		selected_position = result["to"]
	elif result.has("position"):
		selected_position = result["position"]

	if result["type"] == RunController.EVENT_COMBAT_STARTED:
		selected_hand_index = 0
		combat_focus = COMBAT_FOCUS_HAND
		_set_status_message("遭遇已开始。")
		combat_log = "遭遇开始。"
	elif result["type"] == RunController.EVENT_STAGE_ADVANCED:
		selected_position = run_state.dungeon_map.player_position
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		_set_status_message("进入%s。" % str(result.get("stage_display_name", "下一关")))
	elif result["type"] == RunController.EVENT_RUN_WON:
		_set_status_message("原型通关。")
	elif result["type"] == DungeonMapState.EVENT_BLOCKED:
		selected_position = run_state.dungeon_map.player_position
		_set_status_message("无法移动：%s" % _movement_block_reason(result["reason"]))
	elif result["type"] == DungeonMapState.EVENT_PICKUP_COLLECTED:
		_set_status_message(_pickup_summary(result))
	elif result["type"] == DungeonMapState.EVENT_MOVED:
		_set_status_message("探索中。")
	_refresh()


func _on_cell_activated(position: Vector2i) -> void:
	selected_position = position
	if mode != "exploration":
		_refresh()
		return

	var map: DungeonMapState = run_state.dungeon_map
	var tile: DungeonTile = map.get_tile(position)
	if tile == null:
		_refresh()
		return

	if _is_adjacent(position, map.player_position):
		if tile.tile_type != DungeonTile.TileType.WALL:
			_try_move(position - map.player_position)
			return

	_refresh()


func _tile_object_label(tile: DungeonTile) -> String:
	if tile == null or tile.occupant_id == "":
		return "无"
	return _tile_description(tile)


func _tile_type_description(tile_type: int) -> String:
	if tile_type == DungeonTile.TileType.ENEMY:
		return "敌人"
	if tile_type == DungeonTile.TileType.ELITE:
		return "精英"
	if tile_type == DungeonTile.TileType.BOSS:
		return "首领"
	if tile_type == DungeonTile.TileType.TREASURE:
		return "宝箱"
	if tile_type == DungeonTile.TileType.HEALING:
		return "治疗"
	if tile_type == DungeonTile.TileType.XP_GEM:
		return "经验宝石"
	if tile_type == DungeonTile.TileType.FORGE:
		return "锻造"
	if tile_type == DungeonTile.TileType.SHRINE:
		return "祭坛"
	if tile_type == DungeonTile.TileType.HAZARD:
		return "陷阱"
	if tile_type == DungeonTile.TileType.EXIT:
		return "出口"
	return "目标"


func _movement_block_reason(reason: String) -> String:
	if reason == "wall":
		return "墙挡住了路"
	if reason == "out_of_bounds":
		return "地图边界"
	if reason == "non_cardinal_direction":
		return "只能四方向移动"
	if reason == "locked_exit":
		return "出口尚未解锁"
	if reason == "zero_direction":
		return "未选择方向"
	return "未知阻挡"


func _on_action_pressed() -> void:
	if mode == "combat":
		_refresh()
		return

	var result := controller.start_encounter_at(selected_position)
	_sync_from_controller()
	if result["type"] != RunController.EVENT_COMBAT_STARTED:
		return
	selected_hand_index = 0
	combat_focus = COMBAT_FOCUS_HAND
	combat_log = "遭遇开始。"
	_set_status_message("遭遇已开始。")
	_refresh()


func _on_card_pressed(hand_index: int) -> void:
	if active_combat == null:
		return
	if hand_index < 0 or hand_index >= active_combat.deck.hand.size():
		return

	selected_hand_index = hand_index
	combat_focus = COMBAT_FOCUS_HAND
	var result := controller.play_card(hand_index)
	_sync_from_controller()
	_clamp_selected_hand_index()
	if result["type"] == RunController.EVENT_COMMAND_REJECTED:
		combat_log = "无法出牌：%s" % _card_play_failure_reason(result["reason"])
		_refresh()
		return

	combat_log = "%s：造成 %s，获得护甲 %s，抽牌 %s。" % [
		result["card_display_name"],
		result["damage_dealt"],
		result["block_gained"],
		result["cards_drawn"],
	]
	if result["type"] == RunController.EVENT_COMBAT_WON:
		selected_position = result["position"]
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		selected_reward_index = 0
		_set_status_message(_combat_victory_summary(result))
		combat_log = ""
		_refresh()
		return
	if active_combat != null and not _has_playable_card():
		_end_turn_with_log("%s\n费用不足，自动结束回合。" % combat_log)
		return
	_refresh()


func _card_play_failure_reason(reason: String) -> String:
	if reason == "missing_player":
		return "战斗状态缺少玩家"
	if reason == "invalid_hand_index":
		return "手牌无效"
	if reason == "not_enough_mana":
		return "法力不足"
	if reason == "invalid_target":
		return "目标无效"
	return "未知原因"


func _combat_victory_summary(result: Dictionary) -> String:
	var parts := [
		"击败%s。" % str(result.get("defeated_name", "敌人")),
		"获得 %s 经验。" % int(result.get("xp_gained", 0)),
	]
	var level_events: Array = result.get("level_events", [])
	for raw_event in level_events:
		var event: Dictionary = raw_event
		parts.append("升级到 %s 级。" % int(event.get("level", 1)))
	return "".join(parts)


func _pickup_summary(result: Dictionary) -> String:
	var tile_type := int(result.get("tile_type", -1))
	if tile_type == DungeonTile.TileType.TREASURE:
		return "发现宝箱奖励。"
	if tile_type == DungeonTile.TileType.HEALING:
		return "恢复 %s 生命。" % int(result.get("health_recovered", 0))
	if tile_type == DungeonTile.TileType.XP_GEM:
		var parts := ["获得 %s 经验。" % int(result.get("xp_gained", 0))]
		var level_events: Array = result.get("level_events", [])
		for raw_event in level_events:
			var event: Dictionary = raw_event
			parts.append("升级到 %s 级。" % int(event.get("level", 1)))
		if mode == RunController.MODE_REWARD:
			parts.append("选择升级奖励。")
		return "".join(parts)
	return "收集了%s。" % _tile_type_description(tile_type)


func _current_target_enemy() -> CombatantState:
	if active_combat == null:
		return null
	var target_index := active_combat.primary_target_index()
	if target_index < 0 or target_index >= active_combat.enemies.size():
		return null
	return active_combat.enemies[target_index]


func _refresh_enemy_rows() -> void:
	var rows := active_combat.living_enemy_rows()
	if rows.is_empty():
		_add_empty_enemy_row()
		return

	var target_enemy := _current_target_enemy()
	for row_index in range(rows.size()):
		var row: Array = rows[row_index]
		var row_box := VBoxContainer.new()
		row_box.name = "EnemyRow_%02d" % row_index
		row_box.add_theme_constant_override("separation", 6)

		var row_label := Label.new()
		row_label.name = "EnemyRowLabel_%02d" % row_index
		var row_name := "前排" if row_index == 0 else "第%s排" % [row_index + 1]
		row_label.text = "%s  %s/%s" % [row_name, row.size(), CombatState.MAX_ENEMIES_PER_ROW]
		row_label.add_theme_font_size_override("font_size", 15)
		row_box.add_child(row_label)

		var enemy_cards := HBoxContainer.new()
		enemy_cards.name = "EnemyCards_%02d" % row_index
		enemy_cards.add_theme_constant_override("separation", 8)
		for enemy in row:
			enemy_cards.add_child(_create_enemy_card(enemy, row_index, enemy == target_enemy))
		row_box.add_child(enemy_cards)
		combat_enemy_rows.add_child(row_box)


func _add_empty_enemy_row() -> void:
	var empty_label := Label.new()
	empty_label.name = "EnemyEmptyLabel"
	empty_label.text = "无"
	empty_label.add_theme_font_size_override("font_size", 16)
	combat_enemy_rows.add_child(empty_label)


func _create_enemy_card(enemy: CombatantState, row_index: int, is_target: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "EnemyCard_%s" % enemy.id
	card.custom_minimum_size = Vector2(150, 134)
	_style_enemy_card(card, row_index, is_target)

	var content := VBoxContainer.new()
	content.name = "EnemyCardContent_%s" % enemy.id
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)

	var name_label := Label.new()
	name_label.name = "EnemyName"
	name_label.text = enemy.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	content.add_child(name_label)

	var health_label := Label.new()
	health_label.name = "EnemyHealth"
	health_label.text = "生命 %s/%s\n%s" % [
		enemy.health,
		enemy.max_health,
		_health_bar(enemy.health, enemy.max_health),
	]
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 13)
	content.add_child(health_label)

	var stats_label := Label.new()
	stats_label.name = "EnemyStats"
	stats_label.text = "护甲 %s  攻击 %s" % [enemy.block, enemy.attack_damage]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 13)
	content.add_child(stats_label)

	var state_label := Label.new()
	state_label.name = "EnemyStateLabel"
	state_label.text = _enemy_state_text(enemy, is_target)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 13)
	content.add_child(state_label)
	return card


func _enemy_state_text(enemy: CombatantState, is_target: bool) -> String:
	var parts: Array = []
	if is_target:
		parts.append("当前目标")
	parts.append(_enemy_intent_text(enemy))
	return "\n".join(parts)


func _enemy_intent_text(enemy: CombatantState) -> String:
	var intent := active_combat.enemy_intent_for(enemy)
	var intent_type := str(intent.get("type", CombatState.ENEMY_INTENT_WAIT))
	var amount := int(intent.get("amount", 0))
	if intent_type == CombatState.ENEMY_INTENT_ATTACK:
		return "意图：攻击 %s" % amount
	if intent_type == CombatState.ENEMY_INTENT_GUARD:
		return "意图：护甲 +%s" % amount
	return "待命"


func _on_end_turn_pressed() -> void:
	_end_turn_with_log("手动结束回合。")


func _end_turn_with_log(prefix: String) -> void:
	if active_combat == null:
		return
	var result := controller.end_turn()
	_sync_from_controller()
	_clamp_selected_hand_index()
	combat_focus = COMBAT_FOCUS_HAND
	combat_log = "%s\n敌人回合：受到 %s 点伤害。" % [prefix, result["damage_taken"]]
	if result["type"] == RunController.EVENT_COMBAT_LOST:
		combat_log = "玩家倒下。"
		_set_status_message(str(result.get("run_end_summary", "玩家倒下。")))
	_refresh()


func _finish_combat_victory() -> void:
	var result := controller.finish_active_combat_victory()
	_sync_from_controller()
	combat_log = ""
	if result["type"] == RunController.EVENT_COMBAT_WON:
		_set_status_message(_combat_victory_summary(result))
		selected_position = result["position"]
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		selected_reward_index = 0
	_refresh()


func _move_card_selection(delta: int) -> void:
	if active_combat == null or active_combat.deck.hand.is_empty():
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		return

	combat_focus = COMBAT_FOCUS_HAND
	var count := active_combat.deck.hand.size()
	if selected_hand_index < 0:
		selected_hand_index = 0
	else:
		selected_hand_index = (selected_hand_index + delta) % count
		if selected_hand_index < 0:
			selected_hand_index += count
	_refresh()


func _select_end_turn() -> void:
	if active_combat == null:
		return
	combat_focus = COMBAT_FOCUS_END_TURN
	_refresh()


func _select_hand() -> void:
	if active_combat == null:
		return
	combat_focus = COMBAT_FOCUS_HAND
	_clamp_selected_hand_index()
	_refresh()


func _activate_combat_selection() -> void:
	if combat_focus == COMBAT_FOCUS_END_TURN:
		_on_end_turn_pressed()
		return
	_play_selected_card()


func _move_reward_selection(delta: int) -> void:
	if mode != RunController.MODE_REWARD:
		return
	var count := controller.pending_reward_choices.size()
	if count <= 0:
		selected_reward_index = 0
		return
	selected_reward_index = (selected_reward_index + delta) % count
	if selected_reward_index < 0:
		selected_reward_index += count
	_refresh()


func _activate_reward_selection() -> void:
	_on_reward_choice_pressed(selected_reward_index)


func _on_reward_choice_hovered(choice_index: int) -> void:
	if mode != RunController.MODE_REWARD:
		return
	if choice_index < 0 or choice_index >= controller.pending_reward_choices.size():
		return
	if selected_reward_index == choice_index:
		return
	selected_reward_index = choice_index
	_refresh()


func _on_reward_choice_pressed(choice_index: int) -> void:
	if mode != RunController.MODE_REWARD:
		return
	selected_reward_index = choice_index
	var result := controller.apply_reward_choice_index(choice_index)
	_sync_from_controller()
	if result["type"] == RunController.EVENT_REWARD_APPLIED:
		var choice: Dictionary = result.get("choice", {})
		_set_status_message("获得卡牌：%s。" % str(choice.get("display_name", "奖励")))
		selected_reward_index = 0
	else:
		_set_status_message("无法选择奖励。")
	_refresh()


func _restart_run() -> void:
	controller.setup(1001)
	controller.start_stage_1()
	_sync_from_controller()
	selected_position = run_state.dungeon_map.player_position
	selected_hand_index = -1
	selected_reward_index = 0
	combat_focus = COMBAT_FOCUS_HAND
	combat_log = ""
	status_message = "探索中。"
	_refresh()


func _play_selected_card() -> void:
	_clamp_selected_hand_index()
	if selected_hand_index < 0:
		return
	if active_combat == null:
		return
	var card = active_combat.deck.hand[selected_hand_index]
	if card.cost > active_combat.mana:
		_end_turn_with_log("法力不足，自动结束回合。")
		return
	_on_card_pressed(selected_hand_index)


func _on_card_hovered(hand_index: int) -> void:
	if active_combat == null:
		return
	if hand_index < 0 or hand_index >= active_combat.deck.hand.size():
		return
	if selected_hand_index == hand_index:
		return
	combat_focus = COMBAT_FOCUS_HAND
	selected_hand_index = hand_index
	_refresh()


func _clamp_selected_hand_index() -> void:
	if active_combat == null or active_combat.deck.hand.is_empty():
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		return
	selected_hand_index = clampi(selected_hand_index, 0, active_combat.deck.hand.size() - 1)


func _clamp_selected_reward_index() -> void:
	var count := controller.pending_reward_choices.size()
	if count <= 0:
		selected_reward_index = 0
		return
	selected_reward_index = clampi(selected_reward_index, 0, count - 1)


func _selected_card_summary() -> String:
	if combat_focus == COMBAT_FOCUS_END_TURN:
		return "结束回合"
	if active_combat == null:
		return "无"
	if selected_hand_index < 0 or selected_hand_index >= active_combat.deck.hand.size():
		return "无"
	var card = active_combat.deck.hand[selected_hand_index]
	var multiplier_percent := _preview_card_multiplier_basis_points(card)
	if card.base_damage <= 0:
		return "%s | 无伤害 | 倍率 %s%%" % [card.display_name, multiplier_percent]
	return "%s | 预览伤害 %s | 倍率 %s%%" % [
		card.display_name,
		_preview_card_damage(card),
		multiplier_percent,
	]


func _clear_combat_hand() -> void:
	for child in combat_hand_row.get_children():
		combat_hand_row.remove_child(child)
		child.queue_free()


func _clear_enemy_rows() -> void:
	for child in combat_enemy_rows.get_children():
		combat_enemy_rows.remove_child(child)
		child.queue_free()


func _clear_reward_choices() -> void:
	for child in reward_choice_row.get_children():
		reward_choice_row.remove_child(child)
		child.queue_free()


func _card_button_text(card) -> String:
	var parts := [
		card.display_name,
		"",
		"费用：%s" % card.cost,
	]
	if card.base_damage > 0:
		parts.append("攻击：%s" % card.base_damage)
		parts.append("预览伤害：%s" % _preview_card_damage(card))
	if card.block > 0:
		parts.append("防御：%s" % card.block)
	if card.draw_count > 0:
		parts.append("抽牌：%s" % card.draw_count)
	if active_combat != null:
		parts.append("")
		parts.append("连击 → %s" % active_combat.combo.preview_chain_for(card))
		parts.append("倍率：%s%%" % _preview_card_multiplier_basis_points(card))
	return "\n".join(parts)


func _reward_choice_text(choice: Dictionary) -> String:
	return "\n".join([
		str(choice.get("display_name", "奖励")),
		"",
		_reward_category_label(str(choice.get("category", ""))),
		str(choice.get("description", "")),
		"",
		"加入牌组",
	])


func _reward_category_label(category: String) -> String:
	if category == "attack":
		return "攻击牌"
	if category == "defense":
		return "防御牌"
	if category == "draw":
		return "抽牌"
	return "卡牌"


func _preview_card_multiplier_basis_points(card) -> int:
	if active_combat == null or card == null:
		return 100
	return active_combat.combo.preview_multiplier_basis_points(card)


func _preview_card_damage(card) -> int:
	if card == null or card.base_damage <= 0:
		return 0
	return int((card.base_damage * _preview_card_multiplier_basis_points(card)) / 100)


func _has_playable_card() -> bool:
	if active_combat == null:
		return false
	for card in active_combat.deck.hand:
		if card.cost <= active_combat.mana:
			return true
	return false


func _style_end_turn_button(is_selected: bool) -> void:
	var color := Color(0.20, 0.20, 0.22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.08) if is_selected else color
	normal.border_color = Color(0.92, 0.78, 0.22) if is_selected else Color(0.08, 0.09, 0.10)
	normal.border_width_left = 4
	normal.border_width_top = 4
	normal.border_width_right = 4
	normal.border_width_bottom = 4
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.16, 0.16, 0.16)
	end_turn_button.add_theme_stylebox_override("normal", normal)
	end_turn_button.add_theme_stylebox_override("hover", hover)
	end_turn_button.add_theme_stylebox_override("pressed", pressed)
	end_turn_button.add_theme_stylebox_override("disabled", disabled)
	end_turn_button.add_theme_stylebox_override("focus", normal)
	end_turn_button.add_theme_color_override("font_color", Color.WHITE)
	end_turn_button.add_theme_color_override("font_hover_color", Color.WHITE)
	end_turn_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	end_turn_button.add_theme_color_override("font_disabled_color", Color(0.58, 0.58, 0.58))


func _style_card_slot(slot: MarginContainer, is_selected: bool) -> void:
	var top_margin := 0 if is_selected else CARD_SELECTED_LIFT
	slot.add_theme_constant_override("margin_top", top_margin)
	slot.add_theme_constant_override("margin_bottom", CARD_SELECTED_LIFT - top_margin)
	slot.add_theme_constant_override("margin_left", 0)
	slot.add_theme_constant_override("margin_right", 0)


func _style_card_button(button: Button, card, has_combo_multiplier: bool = false) -> void:
	var color := Color(0.18, 0.20, 0.24)
	if card.base_damage > 0:
		color = Color(0.42, 0.16, 0.14)
	elif card.block > 0:
		color = Color(0.15, 0.28, 0.44)
	elif card.draw_count > 0:
		color = Color(0.20, 0.36, 0.26)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.08) if has_combo_multiplier else color
	normal.border_color = COLOR_COMBO_HIGHLIGHT if has_combo_multiplier else Color(0.08, 0.09, 0.10)
	normal.border_width_left = 4
	normal.border_width_top = 4
	normal.border_width_right = 4
	normal.border_width_bottom = 4
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.18, 0.18, 0.18)
	if has_combo_multiplier:
		disabled.border_color = COLOR_COMBO_HIGHLIGHT.darkened(0.25)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.58, 0.58))


func _style_enemy_card(card: PanelContainer, row_index: int, is_target: bool) -> void:
	var color := COLOR_ENEMY_PANEL if row_index == 0 else COLOR_ENEMY_PANEL.darkened(0.20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.08) if is_target else color
	normal.border_color = COLOR_SELECTED if is_target else (COLOR_ENEMY_BORDER if row_index == 0 else COLOR_ENEMY_BORDER.darkened(0.32))
	normal.border_width_left = 3 if is_target else 2
	normal.border_width_top = 3 if is_target else 2
	normal.border_width_right = 3 if is_target else 2
	normal.border_width_bottom = 3 if is_target else 2
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", normal)


func _style_reward_choice_button(button: Button, choice: Dictionary, is_selected: bool) -> void:
	var color := Color(0.22, 0.23, 0.26)
	var category := str(choice.get("category", ""))
	if category == "attack":
		color = Color(0.42, 0.16, 0.14)
	elif category == "defense":
		color = Color(0.15, 0.28, 0.44)
	elif category == "draw":
		color = Color(0.20, 0.36, 0.26)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.08) if is_selected else color
	normal.border_color = COLOR_SELECTED if is_selected else Color(0.08, 0.09, 0.10)
	normal.border_width_left = 4
	normal.border_width_top = 4
	normal.border_width_right = 4
	normal.border_width_bottom = 4
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _health_bar(health: int, max_health: int) -> String:
	var segment_count: int = 10
	var safe_max: int = max_health
	if safe_max < 1:
		safe_max = 1
	var current_health: int = health
	if current_health < 0:
		current_health = 0
	var filled: int = int(ceil(float(current_health) / float(safe_max) * float(segment_count)))
	filled = clampi(filled, 0, segment_count)
	return "%s%s" % ["█".repeat(filled), "░".repeat(segment_count - filled)]


func _cell_text(position: Vector2i, tile: DungeonTile) -> String:
	if position == run_state.dungeon_map.player_position:
		return "我"
	if tile.tile_type == DungeonTile.TileType.WALL:
		return ""
	if tile.tile_type == DungeonTile.TileType.EXIT:
		return "出"
	if tile.tile_type == DungeonTile.TileType.ENEMY:
		return "敌"
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return "精"
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return "首"
	if tile.tile_type == DungeonTile.TileType.TREASURE:
		return "宝"
	if tile.tile_type == DungeonTile.TileType.HEALING:
		return "疗"
	if tile.tile_type == DungeonTile.TileType.XP_GEM:
		return "晶"
	if tile.tile_type == DungeonTile.TileType.FORGE:
		return "锻"
	if tile.tile_type == DungeonTile.TileType.SHRINE:
		return "祭"
	if tile.tile_type == DungeonTile.TileType.HAZARD:
		return "陷"
	return "."


func _tile_description(tile: DungeonTile) -> String:
	if tile.tile_type == DungeonTile.TileType.WALL:
		return "墙"
	if tile.tile_type == DungeonTile.TileType.FLOOR:
		return "地面"
	if tile.tile_type == DungeonTile.TileType.ENTRANCE:
		return "入口"
	if tile.tile_type == DungeonTile.TileType.EXIT:
		return "出口"
	if tile.tile_type == DungeonTile.TileType.TREASURE:
		return "宝箱"
	if tile.tile_type == DungeonTile.TileType.HEALING:
		return "治疗"
	if tile.tile_type == DungeonTile.TileType.XP_GEM:
		return "经验宝石"
	if tile.tile_type == DungeonTile.TileType.SHRINE:
		return "祭坛"
	if tile.tile_type == DungeonTile.TileType.FORGE:
		return "锻造"
	if tile.tile_type == DungeonTile.TileType.HAZARD:
		return "陷阱"
	if tile.tile_type == DungeonTile.TileType.ENEMY:
		return "敌人"
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return "精英"
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return "首领"
	return "未知"


func _tile_color(tile: DungeonTile) -> Color:
	if tile.tile_type == DungeonTile.TileType.WALL:
		return COLOR_WALL
	if tile.tile_type == DungeonTile.TileType.EXIT:
		return COLOR_EXIT_OPEN if run_state.dungeon_map.is_exit_unlocked() else COLOR_EXIT_LOCKED
	if tile.tile_type == DungeonTile.TileType.ENEMY:
		return COLOR_ENEMY
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return COLOR_ELITE
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return COLOR_BOSS
	if tile.is_pickup_tile():
		return COLOR_PICKUP
	return COLOR_FLOOR


func _set_button_color(button: Button, color: Color, is_selected: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = COLOR_SELECTED if is_selected else Color(0.12, 0.13, 0.15)
	normal.border_width_left = 3 if is_selected else 1
	normal.border_width_top = 3 if is_selected else 1
	normal.border_width_right = 3 if is_selected else 1
	normal.border_width_bottom = 3 if is_selected else 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := a - b
	return abs(delta.x) + abs(delta.y) == 1
