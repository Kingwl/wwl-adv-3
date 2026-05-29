class_name RunScene
extends Control

const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const VisualAssetCatalog = preload("res://scripts/visual/visual_asset_catalog.gd")

const CELL_SIZE := Vector2(48, 48)
const MAP_CELL_ICON_INSET := 5
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
const COLOR_COMBAT_STAGE := Color(0.11, 0.12, 0.13)
const COLOR_COMBAT_STAGE_BORDER := Color(0.36, 0.32, 0.24)
const COLOR_COMBAT_HUD := Color(0.15, 0.16, 0.18)
const COLOR_COMBAT_HUD_BORDER := Color(0.38, 0.40, 0.44)
const COLOR_ENEMY_PANEL := Color(0.14, 0.07, 0.06)
const COLOR_COMBO_HIGHLIGHT := Color(0.95, 0.72, 0.20)
const CARD_SIZE := Vector2(148, 132)
const CARD_SELECTED_LIFT := 12
const CARD_SLOT_SIZE := Vector2(CARD_SIZE.x + 10, CARD_SIZE.y + CARD_SELECTED_LIFT + 12)
const CARD_EXIT_ANIMATION_SECONDS := 0.34
const HAND_TRANSITION_ANIMATION_SECONDS := 0.30
const ENEMY_DEFEAT_ANIMATION_SECONDS := 0.48
const ENEMY_ENTRY_ANIMATION_SECONDS := 0.28
const HAND_FAN_SEPARATION := -12
const HAND_FAN_ROTATION_STEP := 4.0
const HAND_FAN_ROTATION_LIMIT := 9.0
const REWARD_CHOICE_SIZE := Vector2(210, 226)
const CARD_ART_SIZE := Vector2(96, 48)
const REWARD_CARD_ART_SIZE := Vector2(132, 88)
const ENEMY_CARD_SIZE := Vector2(148, 124)
const ENEMY_PORTRAIT_SIZE := Vector2(126, 62)
const UI_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"
const COMBAT_FOCUS_HAND := "hand"
const COMBAT_FOCUS_END_TURN := "end_turn"
const ANIMATION_FRAME_SECONDS := 0.14
const COMBAT_VFX_TIMEOUT_SECONDS := 1.8
const ANIMATION_META_TYPE := "visual_animation_type"
const ANIMATION_META_ASSET_ID := "visual_animation_asset_id"
const ANIMATION_META_ACTION := "visual_animation_action"
const ANIMATION_META_MAX_WIDTH := "visual_animation_max_width"
const ANIMATION_PLAYER := "player"
const ANIMATION_PLAYER_COMBAT := "player_combat"
const ANIMATION_ENEMY := "enemy"
const ANIMATION_CARD := "card"
const ANIMATION_CARD_FX := "card_fx"
const ANIMATION_ENEMY_ATTACK_FX := "enemy_attack_fx"
const ANIMATION_PLAYER_HIT_FX := "player_hit_fx"

var controller: RunController = RunController.new()
var visual_assets: VisualAssetCatalog = VisualAssetCatalog.new()
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
var combat_fx_serial: int = 0
var player_hurt_until_msec: int = 0
var combat_animation_locked: bool = false
var pending_enemy_entry_ids: Dictionary = {}
var pending_hand_entry_indices: Dictionary = {}

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
var combat_player_portrait: TextureRect
var combat_player_state_label: Label
var combat_player_health_bar: ProgressBar
var combat_title_label: Label
var combat_enemy_panel: PanelContainer
var combat_enemy_label: Label
var combat_enemy_scroll: ScrollContainer
var combat_enemy_rows: BoxContainer
var combat_stage_floor: HBoxContainer
var combat_mana_label: Label
var combat_combo_label: Label
var combat_selected_label: Label
var combat_hand_title_label: Label
var combat_hand_row: HBoxContainer
var combat_fx_layer: Control
var combat_log_label: Label
var end_turn_button: Button
var reward_title_label: Label
var reward_summary_label: Label
var reward_choice_row: HBoxContainer
var run_end_title_label: Label
var run_end_summary_label: Label
var restart_button: Button
var cell_buttons: Dictionary = {}
var animation_time := 0.0
var animation_frame := 0


func _ready() -> void:
	_apply_ui_font()
	controller.setup(1001)
	controller.start_stage_1()
	_sync_from_controller()
	selected_position = run_state.dungeon_map.player_position
	_build_layout()
	_refresh()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	animation_time += delta
	if animation_time < ANIMATION_FRAME_SECONDS:
		return
	var frame_steps := int(animation_time / ANIMATION_FRAME_SECONDS)
	animation_time -= frame_steps * ANIMATION_FRAME_SECONDS
	animation_frame += frame_steps
	_refresh_animated_assets()


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
	if combat_animation_locked:
		return
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
	_build_combat_fx_layer()
	_create_cells()


func _build_combat_fx_layer() -> void:
	combat_fx_layer = Control.new()
	combat_fx_layer.name = "CardUseFxLayer"
	combat_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	combat_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_fx_layer.z_index = 300
	add_child(combat_fx_layer)


func _build_combat_panel(parent: Control) -> void:
	combat_panel = VBoxContainer.new()
	combat_panel.name = "CombatPanel"
	combat_panel.custom_minimum_size = Vector2(1060, 0)
	combat_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	combat_panel.add_theme_constant_override("separation", 8)
	combat_panel.visible = false
	parent.add_child(combat_panel)

	var combat_header := HBoxContainer.new()
	combat_header.name = "CombatHeader"
	combat_header.add_theme_constant_override("separation", 10)
	combat_panel.add_child(combat_header)

	var header_spacer_left := Control.new()
	header_spacer_left.custom_minimum_size = Vector2(4, 1)
	combat_header.add_child(header_spacer_left)

	combat_title_label = Label.new()
	combat_title_label.name = "CombatTitleLabel"
	combat_title_label.add_theme_font_size_override("font_size", 22)
	combat_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_header.add_child(combat_title_label)

	var battle_row := HBoxContainer.new()
	battle_row.name = "CombatBattleRow"
	battle_row.add_theme_constant_override("separation", 10)
	combat_panel.add_child(battle_row)

	var player_hud := _create_combat_panel_frame(
		"PlayerHudPanel",
		Vector2(166, 342),
		COLOR_COMBAT_HUD,
		COLOR_COMBAT_HUD_BORDER,
		2
	)
	battle_row.add_child(player_hud)

	var player_stack := VBoxContainer.new()
	player_stack.name = "PlayerHudContent"
	player_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	player_stack.add_theme_constant_override("separation", 6)
	player_hud.add_child(player_stack)

	var player_title := Label.new()
	player_title.name = "PlayerHudTitle"
	player_title.text = "玩家"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 16)
	player_stack.add_child(player_title)

	combat_player_portrait = TextureRect.new()
	combat_player_portrait.name = "PlayerCombatPortrait"
	combat_player_portrait.custom_minimum_size = Vector2(112, 92)
	combat_player_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	combat_player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	combat_player_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_stack.add_child(combat_player_portrait)

	combat_player_health_bar = ProgressBar.new()
	combat_player_health_bar.name = "PlayerHealthBar"
	combat_player_health_bar.min_value = 0.0
	combat_player_health_bar.show_percentage = false
	combat_player_health_bar.custom_minimum_size = Vector2(124, 12)
	_style_progress_bar(combat_player_health_bar, Color(0.18, 0.68, 0.26), Color(0.05, 0.08, 0.06))
	player_stack.add_child(combat_player_health_bar)

	combat_player_state_label = Label.new()
	combat_player_state_label.name = "PlayerStateLabel"
	combat_player_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_player_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_player_state_label.add_theme_font_size_override("font_size", 13)
	player_stack.add_child(combat_player_state_label)

	combat_enemy_panel = _create_combat_panel_frame(
		"EnemyStatePanel",
		Vector2(690, 342),
		COLOR_COMBAT_STAGE,
		COLOR_COMBAT_STAGE_BORDER,
		2
	)
	combat_enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.add_child(combat_enemy_panel)

	var enemy_content := VBoxContainer.new()
	enemy_content.name = "EnemyQueueContent"
	enemy_content.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_content.add_theme_constant_override("separation", 4)
	combat_enemy_panel.add_child(enemy_content)

	combat_enemy_label = Label.new()
	combat_enemy_label.name = "EnemyState"
	combat_enemy_label.text = "战斗阵列"
	combat_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_enemy_label.add_theme_font_size_override("font_size", 16)
	enemy_content.add_child(combat_enemy_label)

	combat_enemy_scroll = ScrollContainer.new()
	combat_enemy_scroll.name = "EnemyRowsScroll"
	combat_enemy_scroll.custom_minimum_size = Vector2(640, 274)
	combat_enemy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_enemy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_enemy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	combat_enemy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	enemy_content.add_child(combat_enemy_scroll)

	combat_enemy_rows = VBoxContainer.new()
	combat_enemy_rows.name = "EnemyRows"
	combat_enemy_rows.custom_minimum_size = Vector2(620, 268)
	combat_enemy_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	combat_enemy_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_enemy_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_enemy_rows.add_theme_constant_override("separation", 4)
	combat_enemy_scroll.add_child(combat_enemy_rows)

	combat_stage_floor = HBoxContainer.new()
	combat_stage_floor.name = "CombatStageFloor"
	combat_stage_floor.custom_minimum_size = Vector2(640, 24)
	combat_stage_floor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_stage_floor.add_theme_constant_override("separation", 0)
	enemy_content.add_child(combat_stage_floor)

	var action_hud := _create_combat_panel_frame(
		"CombatActionHud",
		Vector2(176, 342),
		COLOR_COMBAT_HUD,
		COLOR_COMBAT_HUD_BORDER,
		2
	)
	battle_row.add_child(action_hud)

	var action_stack := VBoxContainer.new()
	action_stack.name = "CombatActionHudContent"
	action_stack.add_theme_constant_override("separation", 8)
	action_hud.add_child(action_stack)

	combat_mana_label = Label.new()
	combat_mana_label.name = "CombatManaLabel"
	combat_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_mana_label.add_theme_font_size_override("font_size", 17)
	action_stack.add_child(combat_mana_label)

	combat_combo_label = Label.new()
	combat_combo_label.name = "CombatComboLabel"
	combat_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_combo_label.add_theme_font_size_override("font_size", 15)
	action_stack.add_child(combat_combo_label)

	combat_selected_label = Label.new()
	combat_selected_label.name = "CombatSelectedLabel"
	combat_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_selected_label.add_theme_font_size_override("font_size", 13)
	action_stack.add_child(combat_selected_label)

	end_turn_button = Button.new()
	end_turn_button.name = "EndTurnButton"
	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(146, 36)
	end_turn_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	action_stack.add_child(end_turn_button)

	combat_log_label = Label.new()
	combat_log_label.name = "CombatLogLabel"
	combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log_label.add_theme_font_size_override("font_size", 12)
	action_stack.add_child(combat_log_label)

	combat_hand_title_label = Label.new()
	combat_hand_title_label.name = "CombatHandTitleLabel"
	combat_hand_title_label.text = "手牌"
	combat_hand_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_hand_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_hand_title_label.add_theme_font_size_override("font_size", 17)
	combat_panel.add_child(combat_hand_title_label)

	combat_hand_row = HBoxContainer.new()
	combat_hand_row.name = "CombatHandRow"
	combat_hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	combat_hand_row.add_theme_constant_override("separation", HAND_FAN_SEPARATION)
	combat_panel.add_child(combat_hand_row)


func _build_reward_panel(parent: Control) -> void:
	reward_panel = VBoxContainer.new()
	reward_panel.name = "RewardPanel"
	reward_panel.custom_minimum_size = Vector2(920, 0)
	reward_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	return _create_combat_panel_frame(panel_name, Vector2(620, 104), fill_color, border_color, 4)


func _create_combat_panel_frame(
	panel_name: String,
	minimum_size: Vector2,
	fill_color: Color,
	border_color: Color,
	border_width: int
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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
			var button := _create_map_cell_button(position)
			button.pressed.connect(_on_cell_activated.bind(position))
			cell_buttons[position] = button
			map_grid.add_child(button)


func _create_map_cell_button(position: Vector2i) -> Button:
	var button := Button.new()
	button.name = "Cell_%02d_%02d" % [position.x, position.y]
	button.custom_minimum_size = CELL_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.clip_contents = true
	button.text = ""
	button.icon = null
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_constant_override("icon_max_width", 0)

	var visual := TextureRect.new()
	visual.name = "CellVisual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.offset_left = MAP_CELL_ICON_INSET
	visual.offset_top = MAP_CELL_ICON_INSET
	visual.offset_right = -MAP_CELL_ICON_INSET
	visual.offset_bottom = -MAP_CELL_ICON_INSET
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(visual)

	var glyph := Label.new()
	glyph.name = "CellGlyph"
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 14)
	glyph.add_theme_color_override("font_color", Color.WHITE)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	return button


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
		pending_enemy_entry_ids.clear()
		pending_hand_entry_indices.clear()
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		if combat_player_portrait != null:
			combat_player_portrait.visible = false
		if combat_player_state_label != null:
			combat_player_state_label.text = ""
		if combat_player_health_bar != null:
			combat_player_health_bar.value = 0.0
		if combat_mana_label != null:
			combat_mana_label.text = "法力 0/0"
		if combat_combo_label != null:
			combat_combo_label.text = "连击 0"
		if combat_selected_label != null:
			combat_selected_label.text = "已选：无"
		combat_title_label.text = "战斗"
		combat_enemy_label.text = "战斗阵列"
		_add_empty_enemy_row()
		_refresh_combat_stage_floor()
		combat_hand_title_label.text = _combat_hand_title_text()
		combat_log_label.text = combat_log
		end_turn_button.disabled = true
		_style_end_turn_button(false)
		return

	_clamp_selected_hand_index()
	var selected_card_summary := _selected_card_summary()
	var target_enemy := _current_target_enemy()
	var player_action := _player_combat_action()
	if combat_player_portrait != null:
		combat_player_portrait.visible = true
		combat_player_portrait.texture = visual_assets.player_combat_texture(player_action, animation_frame)
		_apply_texture_animation(combat_player_portrait, ANIMATION_PLAYER_COMBAT, "", player_action)
	var player_max_health := maxi(active_combat.player.max_health, 1)
	if combat_player_health_bar != null:
		combat_player_health_bar.max_value = float(player_max_health)
		combat_player_health_bar.value = float(clampi(active_combat.player.health, 0, player_max_health))
	if combat_player_state_label != null:
		combat_player_state_label.text = "生命 %s/%s\n护甲 %s" % [
			active_combat.player.health,
			active_combat.player.max_health,
			active_combat.player.block,
		]
	combat_title_label.text = "遭遇：%s" % (target_enemy.display_name if target_enemy != null else "敌人")
	combat_enemy_label.text = "战斗阵列"
	_refresh_enemy_rows()
	_refresh_combat_stage_floor()
	combat_hand_title_label.text = _combat_hand_title_text()
	if combat_mana_label != null:
		combat_mana_label.text = "法力 %s/%s" % [active_combat.mana, active_combat.max_mana]
	if combat_combo_label != null:
		combat_combo_label.text = "连击 %s" % active_combat.combo.chain
	if combat_selected_label != null:
		combat_selected_label.text = "已选：%s" % selected_card_summary
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
		_style_card_slot(slot, is_selected, i, active_combat.deck.hand.size())
		var button := _create_hand_card_button(card, i, has_combo_multiplier, is_selected)
		slot.add_child(button)
		combat_hand_row.add_child(slot)
		if pending_hand_entry_indices.has(i):
			_play_hand_card_entry_animation(slot, i)
	pending_hand_entry_indices.clear()

func _create_hand_card_button(card, hand_index: int, has_combo_multiplier: bool, is_selected: bool) -> Button:
	var button := Button.new()
	button.name = "Card_%02d_%s" % [hand_index, card.id]
	button.custom_minimum_size = CARD_SIZE
	button.clip_contents = true
	button.text = ""
	var unavailable_reason := _card_unavailable_reason(card)
	button.tooltip_text = _card_button_text(card, unavailable_reason)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = active_combat.is_victory() or active_combat.is_defeat()
	button.mouse_entered.connect(_on_card_hovered.bind(hand_index))
	button.pressed.connect(_on_card_pressed.bind(hand_index))
	_style_card_button(button, card, has_combo_multiplier, is_selected, unavailable_reason != "")

	var content := MarginContainer.new()
	content.name = "CardVisualContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_top = 6
	content.offset_right = -8
	content.offset_bottom = -6
	button.add_child(content)

	var stack := VBoxContainer.new()
	stack.name = "CardVisualStack"
	stack.add_theme_constant_override("separation", 3)
	content.add_child(stack)

	var header := HBoxContainer.new()
	header.name = "CardHeader"
	header.add_theme_constant_override("separation", 4)
	stack.add_child(header)

	header.add_child(_create_badge("费 %s" % card.cost, Color(0.11, 0.12, 0.14), Color(0.92, 0.76, 0.30), 12, Vector2(34, 22)))

	var name_label := Label.new()
	name_label.name = "CardNameLabel"
	name_label.text = card.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var art := _create_card_art(card.id, CARD_ART_SIZE)
	art.name = "CardArt"
	stack.add_child(art)

	var stat_row := HBoxContainer.new()
	stat_row.name = "CardStatRow"
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 3)
	stack.add_child(stat_row)
	for badge_text in _card_stat_badge_texts(card):
		stat_row.add_child(_create_badge(str(badge_text), Color(0.08, 0.09, 0.10), Color(0.40, 0.42, 0.46), 11, Vector2(34, 20)))

	var multiplier_label := Label.new()
	multiplier_label.name = "CardMultiplierLabel"
	multiplier_label.text = "倍率 %s%%" % _preview_card_multiplier_basis_points(card)
	multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_label.add_theme_font_size_override("font_size", 11)
	if has_combo_multiplier:
		multiplier_label.add_theme_color_override("font_color", COLOR_COMBO_HIGHLIGHT)
	stack.add_child(multiplier_label)

	if unavailable_reason != "":
		var unavailable_label := Label.new()
		unavailable_label.name = "CardUnavailableLabel"
		unavailable_label.text = unavailable_reason
		unavailable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unavailable_label.add_theme_font_size_override("font_size", 11)
		unavailable_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.42))
		stack.add_child(unavailable_label)

	_set_mouse_filter_recursive(content, Control.MOUSE_FILTER_IGNORE)
	return button


func _create_reward_choice_button(choice: Dictionary, choice_index: int) -> Button:
	var card_id := str(choice.get("card_id", ""))
	var button := Button.new()
	button.name = "RewardChoice_%02d_%s" % [choice_index, card_id]
	button.custom_minimum_size = REWARD_CHOICE_SIZE
	button.clip_contents = true
	button.text = ""
	button.tooltip_text = _reward_choice_text(choice)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_entered.connect(_on_reward_choice_hovered.bind(choice_index))
	button.pressed.connect(_on_reward_choice_pressed.bind(choice_index))
	_style_reward_choice_button(button, choice, choice_index == selected_reward_index)

	var content := MarginContainer.new()
	content.name = "RewardVisualContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_top = 10
	content.offset_right = -12
	content.offset_bottom = -10
	button.add_child(content)

	var stack := VBoxContainer.new()
	stack.name = "RewardVisualStack"
	stack.add_theme_constant_override("separation", 6)
	content.add_child(stack)

	var title := Label.new()
	title.name = "RewardCardNameLabel"
	title.text = str(choice.get("display_name", "奖励"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	stack.add_child(title)

	var art := _create_card_art(card_id, REWARD_CARD_ART_SIZE)
	art.name = "RewardCardArt"
	stack.add_child(art)

	var stat_row := HBoxContainer.new()
	stat_row.name = "RewardStatRow"
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 5)
	stack.add_child(stat_row)
	for badge_text in _choice_stat_badge_texts(choice):
		stat_row.add_child(_create_badge(str(badge_text), Color(0.08, 0.09, 0.10), Color(0.40, 0.42, 0.46), 13, Vector2(42, 24)))

	var footer := HBoxContainer.new()
	footer.name = "RewardFooter"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 6)
	stack.add_child(footer)
	footer.add_child(_create_badge(_reward_category_label(str(choice.get("category", ""))), Color(0.15, 0.16, 0.18), Color(0.45, 0.48, 0.52), 13, Vector2(62, 24)))
	footer.add_child(_create_badge("加入", Color(0.18, 0.36, 0.26), Color(0.62, 0.86, 0.58), 13, Vector2(52, 24)))

	_set_mouse_filter_recursive(content, Control.MOUSE_FILTER_IGNORE)
	return button


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
		var button := _create_reward_choice_button(choice, i)
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
	button.text = ""
	button.icon = null
	var glyph := _map_cell_glyph(button)
	if glyph != null:
		glyph.text = _cell_text(position, tile)
	_apply_cell_icon(button, position, tile)
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
	var transition_text := ""
	if result.has("to"):
		selected_position = result["to"]
	elif result.has("position"):
		selected_position = result["position"]

	if result["type"] == RunController.EVENT_COMBAT_STARTED:
		selected_hand_index = 0
		combat_focus = COMBAT_FOCUS_HAND
		_set_status_message("遭遇已开始。")
		combat_log = "遭遇开始。"
		transition_text = "遭遇开始"
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
	if transition_text != "":
		_play_combat_transition(transition_text)


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
	_play_combat_transition("遭遇开始")


func _on_card_pressed(hand_index: int) -> void:
	if combat_animation_locked or active_combat == null:
		return
	if hand_index < 0 or hand_index >= active_combat.deck.hand.size():
		return

	combat_animation_locked = true
	selected_hand_index = hand_index
	combat_focus = COMBAT_FOCUS_HAND
	var card = active_combat.deck.hand[hand_index]
	var card_vfx_context := _capture_card_vfx_context(hand_index, card)
	var front_enemy_ids_before := _current_front_enemy_ids()
	var result := controller.play_card(hand_index)
	if result["type"] == RunController.EVENT_COMMAND_REJECTED:
		_sync_from_controller()
		_clamp_selected_hand_index()
		combat_log = "无法出牌：%s" % _card_play_failure_reason(result["reason"])
		_refresh()
		_play_card_reject_feedback(str(result["reason"]))
		combat_animation_locked = false
		return

	combat_log = "%s：造成 %s，获得护甲 %s，抽牌 %s。" % [
		result["card_display_name"],
		result["damage_dealt"],
		result["block_gained"],
		result["cards_drawn"],
	]
	_play_hand_card_exit_animation(hand_index, card)
	_play_defeated_enemy_exit_animations(result)
	_play_card_use_vfx(card, result, card_vfx_context)
	await _wait_for_combat_vfx_to_finish()

	_sync_from_controller()
	_clamp_selected_hand_index()
	if result["type"] == RunController.EVENT_COMBAT_WON:
		selected_position = result["position"]
		selected_hand_index = -1
		combat_focus = COMBAT_FOCUS_HAND
		selected_reward_index = 0
		_set_status_message(_combat_victory_summary(result))
		combat_log = ""
		_refresh()
		_play_combat_transition("战斗胜利")
		combat_animation_locked = false
		return
	_mark_pending_enemy_entries(_enemy_entry_ids_after_front_advance(front_enemy_ids_before))
	_mark_new_hand_entry_indices(int(result.get("cards_drawn", 0)))
	if active_combat != null and not _has_playable_card():
		_refresh()
		await _wait_for_combat_vfx_to_finish()
		await _end_turn_with_log("%s\n费用不足，自动结束回合。" % combat_log, false)
		combat_animation_locked = false
		return
	_refresh()
	await _wait_for_combat_vfx_to_finish()
	combat_animation_locked = false


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


func _play_card_reject_feedback(reason: String) -> void:
	var feedback_text := _card_play_failure_reason(reason)
	var center := _safe_control_center(combat_mana_label)
	if center == Vector2.ZERO:
		center = _safe_control_center(combat_selected_label)
	if center == Vector2.ZERO:
		center = _fallback_vfx_center()
	_spawn_floating_text(feedback_text, center + Vector2(0, -26), Color(1.0, 0.54, 0.36, 1.0), 0.0, 18)
	if combat_mana_label == null:
		return
	var original_scale := combat_mana_label.scale
	var tween := create_tween()
	tween.tween_property(combat_mana_label, "scale", original_scale * 1.10, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(combat_mana_label, "modulate", Color(1.0, 0.58, 0.42, 1.0), 0.08)
	tween.tween_property(combat_mana_label, "scale", original_scale, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(combat_mana_label, "modulate", Color.WHITE, 0.16)


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


func _selected_card_preview_targets(card_override = null) -> Dictionary:
	var preview_targets := {}
	if active_combat == null:
		return preview_targets
	var card = card_override if card_override != null else _selected_card()
	if card == null or card.base_damage <= 0:
		return preview_targets

	if card.target_mode == CardDefinition.TargetMode.SINGLE_ENEMY:
		var target_enemy := _current_target_enemy()
		if target_enemy != null:
			preview_targets[target_enemy.id] = "exact"
		return preview_targets

	if card.target_mode == CardDefinition.TargetMode.FRONT_ROW:
		for enemy in active_combat.front_row_enemies():
			if enemy != null:
				preview_targets[enemy.id] = "exact"
		return preview_targets

	if card.target_mode == CardDefinition.TargetMode.ALL_ENEMIES:
		for enemy in active_combat.living_enemies():
			if enemy != null:
				preview_targets[enemy.id] = "exact"
		return preview_targets

	if card.target_mode == CardDefinition.TargetMode.BOUNCE:
		var living := active_combat.living_enemies()
		if living.is_empty():
			return preview_targets
		var start_enemy := _current_target_enemy()
		var start_index := living.find(start_enemy)
		if start_index < 0:
			start_index = 0
		for i in range(min(card.hit_count, living.size())):
			var enemy: CombatantState = living[(start_index + i) % living.size()]
			if enemy != null:
				preview_targets[enemy.id] = "exact"
		return preview_targets

	if card.target_mode == CardDefinition.TargetMode.RANDOM_ENEMIES:
		for enemy in active_combat.living_enemies():
			if enemy != null:
				preview_targets[enemy.id] = "possible"
	return preview_targets


func _refresh_enemy_rows() -> void:
	var rows := active_combat.living_enemy_rows()
	if rows.is_empty():
		_add_empty_enemy_row()
		pending_enemy_entry_ids.clear()
		return

	var target_enemy := _current_target_enemy()
	var preview_targets := _selected_card_preview_targets()
	for display_index in range(rows.size()):
		var row_index := rows.size() - 1 - display_index
		var row: Array = rows[row_index]
		var row_box := HBoxContainer.new()
		row_box.name = "EnemyRow_%02d" % row_index
		row_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row_box.add_theme_constant_override("separation", 8)

		var row_label := Label.new()
		row_label.name = "EnemyRowLabel_%02d" % row_index
		var row_name := _enemy_row_name(row_index)
		row_label.text = "%s\n%s/%s" % [row_name, row.size(), CombatState.MAX_ENEMIES_PER_ROW]
		row_label.custom_minimum_size = Vector2(48, 1)
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row_label.add_theme_font_size_override("font_size", 13)
		row_box.add_child(row_label)

		var enemy_cards := HBoxContainer.new()
		enemy_cards.name = "EnemyCards_%02d" % row_index
		enemy_cards.alignment = BoxContainer.ALIGNMENT_CENTER
		enemy_cards.add_theme_constant_override("separation", 4)
		for enemy in row:
			var preview_kind := str(preview_targets.get(enemy.id, ""))
			var enemy_card := _create_enemy_card(enemy, row_index, enemy == target_enemy, preview_kind)
			enemy_cards.add_child(enemy_card)
			if pending_enemy_entry_ids.has(enemy.id):
				_play_enemy_entry_animation(enemy_card)
		row_box.add_child(enemy_cards)
		combat_enemy_rows.add_child(row_box)
	pending_enemy_entry_ids.clear()
	call_deferred("_scroll_enemy_rows_to_front")


func _enemy_row_name(row_index: int) -> String:
	if row_index <= 0:
		return "前排"
	return "第%s排" % [row_index + 1]


func _scroll_enemy_rows_to_front() -> void:
	if combat_enemy_scroll == null:
		return
	var vertical_bar := combat_enemy_scroll.get_v_scroll_bar()
	if vertical_bar == null:
		return
	combat_enemy_scroll.scroll_vertical = int(vertical_bar.max_value)


func _add_empty_enemy_row() -> void:
	var empty_label := Label.new()
	empty_label.name = "EnemyEmptyLabel"
	empty_label.text = "无"
	empty_label.add_theme_font_size_override("font_size", 16)
	combat_enemy_rows.add_child(empty_label)


func _refresh_combat_stage_floor() -> void:
	if combat_stage_floor == null:
		return
	for child in combat_stage_floor.get_children():
		combat_stage_floor.remove_child(child)
		child.queue_free()

	var stage_id := ""
	if run_state != null and run_state.current_stage != null:
		stage_id = run_state.current_stage.id
	for i in range(20):
		var tile := TextureRect.new()
		tile.name = "CombatStageTile_%02d" % i
		tile.custom_minimum_size = Vector2(32, 24)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.texture = visual_assets.tile_texture(DungeonTile.TileType.FLOOR, false, animation_frame + i, stage_id)
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combat_stage_floor.add_child(tile)


func _capture_card_vfx_context(hand_index: int, card) -> Dictionary:
	return {
		"source_center": _card_vfx_source_center(hand_index, card),
		"player_center": _safe_control_center(combat_player_portrait),
		"hand_center": _safe_control_center(combat_hand_row),
		"enemy_stage_rect": _safe_control_rect(combat_enemy_panel),
		"enemy_centers": _capture_enemy_card_centers(),
	}


func _card_vfx_source_center(hand_index: int, card) -> Vector2:
	if combat_hand_row != null and card != null:
		var card_button := combat_hand_row.find_child("Card_%02d_%s" % [hand_index, card.id], true, false) as Control
		var card_center := _safe_control_center(card_button)
		if card_center != Vector2.ZERO:
			return card_center

	var player_center := _safe_control_center(combat_player_portrait)
	if player_center != Vector2.ZERO:
		return player_center
	return _fallback_vfx_center()


func _play_hand_card_exit_animation(hand_index: int, card) -> void:
	if combat_fx_layer == null:
		return

	var slot := _hand_card_slot(hand_index, card)
	if slot != null:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.pivot_offset = slot.size * 0.5
		slot.z_index = 120
		var button := _hand_card_button(hand_index, card)
		if button != null:
			button.disabled = true
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var direction := -1.0 if hand_index % 2 == 0 else 1.0
		var start_position := slot.position
		var tween := create_tween()
		tween.tween_property(slot, "scale", Vector2(0.90, 0.90), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "position", start_position + Vector2(direction * 10.0, -18.0), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "rotation_degrees", slot.rotation_degrees + direction * 8.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "modulate:a", 0.34, 0.16)
		tween.tween_property(slot, "scale", Vector2(0.72, 0.72), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(slot, "position", start_position + Vector2(direction * 18.0, -28.0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(slot, "modulate:a", 0.0, 0.18)

	_spawn_vfx_wait_sentinel("CardExitFx", CARD_EXIT_ANIMATION_SECONDS)


func _play_hand_discard_animation() -> void:
	if combat_hand_row == null or combat_hand_row.get_child_count() <= 0:
		return
	for i in range(combat_hand_row.get_child_count()):
		var slot := combat_hand_row.get_child(i) as Control
		if slot == null:
			continue
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.pivot_offset = slot.size * 0.5
		var button := _first_button_child(slot)
		if button != null:
			button.disabled = true
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var direction := -1.0 if i % 2 == 0 else 1.0
		var tween := create_tween()
		tween.tween_property(slot, "scale", Vector2(0.86, 0.86), HAND_TRANSITION_ANIMATION_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(slot, "position", slot.position + Vector2(direction * 16.0, 30.0), HAND_TRANSITION_ANIMATION_SECONDS)
		tween.parallel().tween_property(slot, "rotation_degrees", slot.rotation_degrees + direction * 7.0, HAND_TRANSITION_ANIMATION_SECONDS)
		tween.parallel().tween_property(slot, "modulate:a", 0.0, HAND_TRANSITION_ANIMATION_SECONDS)
	_spawn_vfx_wait_sentinel("HandDiscardFx", HAND_TRANSITION_ANIMATION_SECONDS)


func _play_hand_card_entry_animation(slot: Control, hand_index: int) -> void:
	if slot == null:
		return
	slot.pivot_offset = slot.size * 0.5
	var target_rotation := slot.rotation_degrees
	var direction := -1.0 if hand_index % 2 == 0 else 1.0
	slot.scale = Vector2(0.86, 0.86)
	slot.modulate.a = 0.0
	slot.rotation_degrees = target_rotation + direction * 5.0
	var tween := create_tween()
	tween.tween_property(slot, "modulate:a", 1.0, HAND_TRANSITION_ANIMATION_SECONDS * 0.55)
	tween.parallel().tween_property(slot, "scale", Vector2(1.04, 1.04), HAND_TRANSITION_ANIMATION_SECONDS * 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(slot, "rotation_degrees", target_rotation, HAND_TRANSITION_ANIMATION_SECONDS * 0.55)
	tween.tween_property(slot, "scale", Vector2.ONE, HAND_TRANSITION_ANIMATION_SECONDS * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_spawn_vfx_wait_sentinel("HandDrawFx", HAND_TRANSITION_ANIMATION_SECONDS)


func _play_defeated_enemy_exit_animations(result: Dictionary) -> void:
	var defeated_ids := {}
	var hit_events: Array = result.get("hit_events", [])
	for raw_hit in hit_events:
		var hit: Dictionary = raw_hit
		if not bool(hit.get("defeated", false)):
			continue
		var enemy_id := str(hit.get("target_id", ""))
		if enemy_id == "" or defeated_ids.has(enemy_id):
			continue
		defeated_ids[enemy_id] = true
		var enemy_card := _enemy_card_control(enemy_id)
		if enemy_card == null:
			continue
		enemy_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_card.pivot_offset = enemy_card.size * 0.5
		enemy_card.z_index = 150
		var tween := create_tween()
		tween.tween_property(enemy_card, "scale", Vector2(1.08, 1.08), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(enemy_card, "rotation_degrees", enemy_card.rotation_degrees - 3.0, 0.16)
		tween.tween_property(enemy_card, "scale", Vector2(0.84, 0.84), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(enemy_card, "position", enemy_card.position + Vector2(0, 18), 0.32)
		tween.parallel().tween_property(enemy_card, "modulate:a", 0.0, 0.32)
	if not defeated_ids.is_empty():
		_spawn_vfx_wait_sentinel("EnemyDefeatFx", ENEMY_DEFEAT_ANIMATION_SECONDS)


func _play_enemy_entry_animation(enemy_card: Control) -> void:
	if enemy_card == null:
		return
	enemy_card.pivot_offset = enemy_card.size * 0.5
	enemy_card.scale = Vector2(0.88, 0.88)
	enemy_card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(enemy_card, "modulate:a", 1.0, ENEMY_ENTRY_ANIMATION_SECONDS * 0.45)
	tween.parallel().tween_property(enemy_card, "scale", Vector2(1.06, 1.06), ENEMY_ENTRY_ANIMATION_SECONDS * 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy_card, "scale", Vector2.ONE, ENEMY_ENTRY_ANIMATION_SECONDS * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_spawn_vfx_wait_sentinel("EnemyEntryFx", ENEMY_ENTRY_ANIMATION_SECONDS)


func _spawn_vfx_wait_sentinel(prefix: String, duration: float) -> void:
	if combat_fx_layer == null:
		return
	combat_fx_serial += 1
	var sentinel := Control.new()
	sentinel.name = "%s_%03d" % [prefix, combat_fx_serial]
	sentinel.visible = false
	sentinel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_fx_layer.add_child(sentinel)
	var sentinel_tween := create_tween()
	sentinel_tween.tween_interval(duration)
	sentinel_tween.tween_callback(Callable(sentinel, "queue_free"))


func _hand_card_slot(hand_index: int, card) -> MarginContainer:
	if combat_hand_row == null or card == null:
		return null
	return combat_hand_row.find_child("CardSlot_%02d_%s" % [hand_index, card.id], true, false) as MarginContainer


func _hand_card_button(hand_index: int, card) -> Button:
	var slot := _hand_card_slot(hand_index, card)
	if slot == null:
		return null
	return slot.find_child("Card_%02d_%s" % [hand_index, card.id], true, false) as Button


func _first_button_child(root: Node) -> Button:
	if root == null:
		return null
	for child in root.get_children():
		if child is Button:
			return child
		var nested := _first_button_child(child)
		if nested != null:
			return nested
	return null


func _enemy_card_control(enemy_id: String) -> Control:
	if combat_enemy_rows == null or enemy_id == "":
		return null
	return combat_enemy_rows.find_child("EnemyCard_%s" % enemy_id, true, false) as Control


func _current_front_enemy_ids() -> Array:
	var ids: Array = []
	if active_combat == null:
		return ids
	for enemy in active_combat.front_row_enemies():
		if enemy != null:
			ids.append(enemy.id)
	return ids


func _enemy_entry_ids_after_front_advance(front_enemy_ids_before: Array) -> Array:
	var entered_ids: Array = []
	if front_enemy_ids_before.is_empty() or active_combat == null:
		return entered_ids
	var front_enemy_ids_after := _current_front_enemy_ids()
	if front_enemy_ids_after.is_empty():
		return entered_ids
	var has_previous_front_enemy := false
	for raw_enemy_id in front_enemy_ids_after:
		if front_enemy_ids_before.has(raw_enemy_id):
			has_previous_front_enemy = true
			break
	if has_previous_front_enemy:
		return entered_ids
	for raw_enemy_id in front_enemy_ids_after:
		entered_ids.append(str(raw_enemy_id))
	return entered_ids


func _mark_pending_enemy_entries(enemy_ids: Array) -> void:
	pending_enemy_entry_ids.clear()
	for raw_enemy_id in enemy_ids:
		var enemy_id := str(raw_enemy_id)
		if enemy_id != "":
			pending_enemy_entry_ids[enemy_id] = true


func _mark_new_hand_entry_indices(count: int) -> void:
	pending_hand_entry_indices.clear()
	if active_combat == null or count <= 0:
		return
	var hand_size := active_combat.deck.hand.size()
	var start_index := maxi(hand_size - count, 0)
	for i in range(start_index, hand_size):
		pending_hand_entry_indices[i] = true


func _mark_all_hand_entry_indices() -> void:
	pending_hand_entry_indices.clear()
	if active_combat == null:
		return
	for i in range(active_combat.deck.hand.size()):
		pending_hand_entry_indices[i] = true


func _capture_enemy_card_centers() -> Dictionary:
	var centers := {}
	if combat_enemy_rows != null:
		_collect_enemy_card_centers(combat_enemy_rows, centers)
	return centers


func _capture_enemy_turn_vfx_context() -> Dictionary:
	var context := {
		"attackers": [],
		"player_center": _safe_control_center(combat_player_portrait),
		"enemy_stage_center": _safe_control_center(combat_enemy_panel),
	}
	if active_combat == null:
		return context

	var enemy_centers := _capture_enemy_card_centers()
	var attackers: Array = context["attackers"]
	for enemy in active_combat.active_attackers():
		if enemy == null:
			continue
		var visual_id := _enemy_visual_id(enemy)
		var source_center: Vector2 = enemy_centers.get(enemy.id, Vector2.ZERO)
		if source_center == Vector2.ZERO:
			source_center = context["enemy_stage_center"]
		var intent := active_combat.enemy_intent_for(enemy)
		attackers.append({
			"enemy_id": enemy.id,
			"visual_id": visual_id,
			"display_name": enemy.display_name,
			"amount": int(intent.get("amount", enemy.attack_damage)),
			"source_center": source_center,
		})
	return context


func _collect_enemy_card_centers(root: Node, centers: Dictionary) -> void:
	if root == null:
		return
	for child in root.get_children():
		var child_name := str(child.name)
		if child is PanelContainer and child_name.begins_with("EnemyCard_"):
			var enemy_id := child_name.substr("EnemyCard_".length())
			centers[enemy_id] = _safe_control_center(child as Control)
		_collect_enemy_card_centers(child, centers)


func _play_card_use_vfx(card, result: Dictionary, context: Dictionary) -> void:
	if card == null or combat_fx_layer == null:
		return

	var source_center: Vector2 = context.get("source_center", _fallback_vfx_center())
	var player_center: Vector2 = context.get("player_center", _safe_control_center(combat_player_portrait))
	var hand_center: Vector2 = context.get("hand_center", _safe_control_center(combat_hand_row))
	if source_center == Vector2.ZERO:
		source_center = _fallback_vfx_center()
	if player_center == Vector2.ZERO:
		player_center = source_center
	if hand_center == Vector2.ZERO:
		hand_center = source_center

	var tint := _card_vfx_color(card)
	_spawn_card_fx_burst("single_impact", source_center, Vector2(94, 86), tint, 0.0, 0.22, 0.82, card.id)

	if card.base_damage > 0:
		var target_points := _card_vfx_target_points(result, context)
		_play_attack_card_vfx(card, source_center, target_points, tint, context)
	if card.block > 0:
		_spawn_card_icon_pulse(card, player_center, Vector2(76, 76), Color(1.0, 1.0, 1.0, 0.92), 0.02)
		_spawn_card_fx_burst("single_impact", player_center, Vector2(152, 126), Color(0.38, 0.86, 0.72, 0.82), 0.06, 0.42, 0.82, card.id)
	if card.draw_count > 0:
		_spawn_card_icon_pulse(card, hand_center, Vector2(76, 76), Color(1.0, 1.0, 1.0, 0.90), 0.04)
		_spawn_card_fx_burst("bounce_projectile", hand_center, Vector2(132, 102), Color(0.78, 0.88, 1.00, 0.80), 0.08, 0.38, 0.80, card.id)
	_play_card_result_feedback(card, result, context, player_center, hand_center)


func _play_attack_card_vfx(card, source_center: Vector2, target_points: Array, tint: Color, context: Dictionary) -> void:
	if target_points.is_empty():
		target_points.append(_enemy_stage_center(context))

	if card.target_mode == CardDefinition.TargetMode.FRONT_ROW:
		var sweep_center := _points_center(target_points)
		var sweep_size := _points_span_size(target_points, Vector2(250, 104), Vector2(170, 84))
		_spawn_card_icon_pulse(card, sweep_center, Vector2(78, 78), Color(1.0, 1.0, 1.0, 0.92), 0.02)
		_spawn_card_fx_burst("front_row_sweep", sweep_center, sweep_size, tint, 0.04, 0.34, 0.88, card.id)
		_spawn_target_impacts(target_points, tint, 0.20, card.id)
		return

	if card.target_mode == CardDefinition.TargetMode.ALL_ENEMIES:
		var stage_rect: Rect2 = context.get("enemy_stage_rect", _safe_control_rect(combat_enemy_panel))
		var burst_center := stage_rect.get_center() if stage_rect.size != Vector2.ZERO else _points_center(target_points)
		var burst_size := Vector2(maxf(stage_rect.size.x * 0.86, 320.0), maxf(stage_rect.size.y * 0.70, 170.0))
		_spawn_card_icon_pulse(card, burst_center, Vector2(90, 90), Color(1.0, 1.0, 1.0, 0.92), 0.02)
		_spawn_card_fx_burst("all_screen_burst", burst_center, burst_size, tint, 0.04, 0.48, 0.88, card.id)
		_spawn_target_impacts(target_points, tint, 0.26, card.id)
		return

	if card.target_mode == CardDefinition.TargetMode.RANDOM_ENEMIES:
		for i in range(target_points.size()):
			_spawn_card_icon_echo(card, source_center, target_points[i], 0.02 + float(i) * 0.08, 0.20, Color(1.0, 1.0, 1.0, 0.90))
			_spawn_card_fx_burst("random_strike", target_points[i], Vector2(132, 112), tint, 0.08 + float(i) * 0.08, 0.32, 0.88, card.id)
		return

	if card.target_mode == CardDefinition.TargetMode.BOUNCE:
		var previous_point := source_center
		for i in range(target_points.size()):
			var target_point: Vector2 = target_points[i]
			var delay := float(i) * 0.13
			_spawn_card_icon_echo(card, previous_point, target_point, delay, 0.18, Color(1.0, 1.0, 1.0, 0.88))
			_spawn_card_fx_projectile("bounce_projectile", previous_point, target_point, tint, delay, 0.18, card.id)
			_spawn_card_fx_burst("single_impact", target_point, Vector2(126, 104), tint, delay + 0.17, 0.22, 0.82, card.id)
			previous_point = target_point
		return

	_spawn_card_icon_echo(card, source_center, target_points[0], 0.02, 0.24, Color(1.0, 1.0, 1.0, 0.90))
	_spawn_card_fx_projectile(_card_projectile_action(card), source_center, target_points[0], tint, 0.04, 0.24, card.id)
	_spawn_target_impacts([target_points[0]], tint, 0.28, card.id)


func _card_vfx_target_points(result: Dictionary, context: Dictionary) -> Array:
	var target_points: Array = []
	var enemy_centers: Dictionary = context.get("enemy_centers", {})
	var target_ids: Array = result.get("target_ids", [])
	for raw_target_id in target_ids:
		var target_id := str(raw_target_id)
		if enemy_centers.has(target_id):
			target_points.append(enemy_centers[target_id])

	if target_points.is_empty():
		var target_id := str(result.get("target_id", ""))
		if enemy_centers.has(target_id):
			target_points.append(enemy_centers[target_id])
	return target_points


func _spawn_target_impacts(target_points: Array, tint: Color, base_delay: float, card_id: String = "") -> void:
	for i in range(target_points.size()):
		_spawn_card_fx_burst("single_impact", target_points[i], Vector2(126, 104), tint, base_delay + float(i) * 0.03, 0.24, 0.84, card_id)


func _play_card_result_feedback(card, result: Dictionary, context: Dictionary, player_center: Vector2, hand_center: Vector2) -> void:
	var enemy_centers: Dictionary = context.get("enemy_centers", {})
	var hit_events: Array = result.get("hit_events", [])
	for i in range(hit_events.size()):
		var hit: Dictionary = hit_events[i]
		var target_id := str(hit.get("target_id", ""))
		var center: Vector2 = _enemy_stage_center(context)
		if enemy_centers.has(target_id):
			center = enemy_centers[target_id]
		var damage := int(hit.get("damage", 0))
		var delay := 0.24 + float(i % 5) * 0.04
		if damage > 0:
			_spawn_floating_text("-%s" % damage, center + Vector2(0, -34), Color(1.0, 0.27, 0.18, 1.0), delay, 24)
		else:
			_spawn_floating_text("格挡", center + Vector2(0, -34), Color(0.64, 0.84, 1.0, 1.0), delay, 20)
		if bool(hit.get("defeated", false)):
			_spawn_floating_text("击破", center + Vector2(0, -60), COLOR_SELECTED, delay + 0.10, 20)

	var block_gained := int(result.get("block_gained", 0))
	if block_gained > 0:
		_spawn_floating_text("+%s 护甲" % block_gained, player_center + Vector2(0, -54), Color(0.38, 0.92, 0.72, 1.0), 0.20, 18)

	var cards_drawn := int(result.get("cards_drawn", 0))
	if cards_drawn > 0:
		_spawn_floating_text("+%s 抽牌" % cards_drawn, hand_center + Vector2(0, -42), Color(0.78, 0.88, 1.0, 1.0), 0.22, 18)


func _play_combat_transition(text: String) -> void:
	if combat_fx_layer == null or text == "":
		return
	combat_fx_serial += 1
	var overlay := ColorRect.new()
	overlay.name = "CombatTransitionFx_%03d" % combat_fx_serial
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 560 + combat_fx_serial % 30
	overlay.color = Color(0.02, 0.02, 0.02, 0.0)
	combat_fx_layer.add_child(overlay)

	var label := Label.new()
	label.name = "CombatTransitionLabel"
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.46, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.96))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	label.scale = Vector2(0.92, 0.92)
	overlay.add_child(label)

	var tween := create_tween()
	tween.tween_property(overlay, "color", Color(0.02, 0.02, 0.02, 0.34), 0.08)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.22)
	tween.tween_property(overlay, "color", Color(0.02, 0.02, 0.02, 0.0), 0.18)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.18)
	tween.tween_callback(Callable(overlay, "queue_free"))


func _spawn_floating_text(text: String, center: Vector2, color: Color, delay: float = 0.0, font_size: int = 22) -> void:
	if combat_fx_layer == null or text == "":
		return

	combat_fx_serial += 1
	var label := Label.new()
	label.name = "CombatFloatingText_%03d" % combat_fx_serial
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(112, 30)
	label.size = Vector2(112, 30)
	label.pivot_offset = label.size * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 520 + combat_fx_serial % 50
	label.modulate = Color(1.0, 1.0, 1.0, 0.0 if delay > 0.0 else 1.0)
	label.position = _fx_layer_position_for_center(center, label.size)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	combat_fx_layer.add_child(label)

	var end_position := label.position + Vector2(0, -28)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_property(label, "modulate:a", 1.0, 0.04)
	tween.tween_property(label, "position", end_position, 0.44).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.12, 1.12), 0.18)
	tween.tween_property(label, "modulate:a", 0.0, 0.16)
	tween.tween_callback(Callable(label, "queue_free"))


func _spawn_card_fx_projectile(
	action: String,
	start_center: Vector2,
	end_center: Vector2,
	tint: Color,
	delay: float,
	duration: float,
	card_id: String = ""
) -> void:
	var sprite := _create_card_fx_sprite(action, start_center, Vector2(104, 78), tint, card_id)
	if sprite == null:
		return
	sprite.rotation = (end_center - start_center).angle()
	sprite.visible = delay <= 0.0

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "position", _fx_layer_position_for_center(end_center, sprite.size), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.14, 1.14), duration)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.10)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _spawn_card_icon_echo(card, start_center: Vector2, end_center: Vector2, delay: float, duration: float, tint: Color) -> void:
	var sprite := _create_card_icon_vfx_sprite(card, start_center, Vector2(66, 66), tint)
	if sprite == null:
		return
	sprite.rotation = (end_center - start_center).angle() * 0.18
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2(0.72, 0.72)

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "position", _fx_layer_position_for_center(end_center, sprite.size), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.10, 1.10), duration)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.14)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _spawn_card_icon_pulse(card, center: Vector2, size: Vector2, tint: Color, delay: float) -> void:
	var sprite := _create_card_icon_vfx_sprite(card, center, size, tint)
	if sprite == null:
		return
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2(0.70, 0.70)

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.32)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _create_card_icon_vfx_sprite(card, center: Vector2, size: Vector2, tint: Color) -> TextureRect:
	if card == null or combat_fx_layer == null:
		return null
	var texture := visual_assets.card_texture(card.id, animation_frame)
	if texture == null:
		return null

	combat_fx_serial += 1
	var sprite := TextureRect.new()
	sprite.name = "CardUseIcon_%03d_%s" % [combat_fx_serial, card.id]
	sprite.texture = texture
	sprite.custom_minimum_size = size
	sprite.size = size
	sprite.pivot_offset = size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 460 + combat_fx_serial % 50
	sprite.modulate = tint
	sprite.position = _fx_layer_position_for_center(center, size)
	_apply_texture_animation(sprite, ANIMATION_CARD, card.id, "")
	combat_fx_layer.add_child(sprite)
	return sprite


func _spawn_card_fx_burst(
	action: String,
	center: Vector2,
	size: Vector2,
	tint: Color,
	delay: float,
	duration: float,
	alpha: float,
	card_id: String = ""
) -> void:
	var burst_tint := tint
	burst_tint.a = alpha
	var sprite := _create_card_fx_sprite(action, center, size, burst_tint, card_id)
	if sprite == null:
		return
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2(0.78, 0.78)

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "scale", Vector2(1.18, 1.18), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _create_card_fx_sprite(action: String, center: Vector2, size: Vector2, tint: Color, card_id: String = "") -> TextureRect:
	if combat_fx_layer == null:
		return null
	var texture := visual_assets.card_attack_fx_texture(card_id, animation_frame)
	if texture == null:
		texture = visual_assets.card_fx_texture(action, animation_frame)
	if texture == null:
		return null

	combat_fx_serial += 1
	var sprite := TextureRect.new()
	sprite.name = "CardUseFx_%03d_%s" % [combat_fx_serial, action]
	sprite.texture = texture
	sprite.custom_minimum_size = size
	sprite.size = size
	sprite.pivot_offset = size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 400 + combat_fx_serial % 50
	sprite.modulate = tint
	sprite.position = _fx_layer_position_for_center(center, size)
	_apply_texture_animation(sprite, ANIMATION_CARD_FX, card_id, action)
	combat_fx_layer.add_child(sprite)
	return sprite


func _play_enemy_turn_vfx(context: Dictionary, damage_taken: int) -> void:
	if combat_fx_layer == null:
		return
	var attackers: Array = context.get("attackers", [])
	if attackers.is_empty():
		return
	var player_center: Vector2 = context.get("player_center", _safe_control_center(combat_player_portrait))
	if player_center == Vector2.ZERO:
		player_center = _safe_control_center(combat_player_portrait)
	if player_center == Vector2.ZERO:
		player_center = _fallback_vfx_center()

	for i in range(attackers.size()):
		var attacker_info: Dictionary = attackers[i]
		var visual_id := str(attacker_info.get("visual_id", "grunt"))
		var source_center: Vector2 = attacker_info.get("source_center", _fallback_vfx_center())
		if source_center == Vector2.ZERO:
			source_center = _fallback_vfx_center()
		var delay := 0.04 + float(i) * 0.14
		var tint := _enemy_vfx_color(visual_id)
		_spawn_enemy_attack_fx_burst(visual_id, source_center, Vector2(124, 102), tint, delay, 0.22, 0.82)
		_spawn_enemy_attack_fx_projectile(visual_id, source_center, player_center, tint, delay + 0.08, 0.22)
		_spawn_player_hit_fx(player_center, damage_taken > 0, delay + 0.28 + float(i) * 0.02)
	var result_delay := 0.38 + float(maxi(attackers.size() - 1, 0)) * 0.14
	if damage_taken > 0:
		_spawn_floating_text("-%s" % damage_taken, player_center + Vector2(0, -58), Color(1.0, 0.24, 0.18, 1.0), result_delay, 24)
	else:
		_spawn_floating_text("格挡", player_center + Vector2(0, -58), Color(0.64, 0.84, 1.0, 1.0), result_delay, 20)


func _spawn_enemy_attack_fx_projectile(
	visual_id: String,
	start_center: Vector2,
	end_center: Vector2,
	tint: Color,
	delay: float,
	duration: float
) -> void:
	var sprite := _create_enemy_attack_fx_sprite(visual_id, start_center, Vector2(112, 88), tint)
	if sprite == null:
		return
	sprite.rotation = (end_center - start_center).angle()
	sprite.visible = delay <= 0.0

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "position", _fx_layer_position_for_center(end_center, sprite.size), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.16, 1.16), duration)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.10)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _spawn_enemy_attack_fx_burst(
	visual_id: String,
	center: Vector2,
	size: Vector2,
	tint: Color,
	delay: float,
	duration: float,
	alpha: float
) -> void:
	var burst_tint := tint
	burst_tint.a = alpha
	var sprite := _create_enemy_attack_fx_sprite(visual_id, center, size, burst_tint)
	if sprite == null:
		return
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2(0.78, 0.78)

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "scale", Vector2(1.14, 1.14), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _spawn_player_hit_fx(center: Vector2, took_damage: bool, delay: float) -> void:
	var tint := Color(1.0, 0.24, 0.18, 0.88) if took_damage else Color(0.62, 0.86, 1.0, 0.78)
	var sprite := _create_player_hit_fx_sprite(center, Vector2(154, 124), tint)
	if sprite == null:
		return
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2(0.76, 0.76)

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(Callable(sprite, "show"))
	tween.tween_property(sprite, "scale", Vector2(1.18, 1.18), 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.30)
	tween.tween_callback(Callable(sprite, "queue_free"))


func _create_enemy_attack_fx_sprite(visual_id: String, center: Vector2, size: Vector2, tint: Color) -> TextureRect:
	if combat_fx_layer == null:
		return null
	var texture := visual_assets.enemy_attack_fx_texture(visual_id, animation_frame)
	if texture == null:
		texture = visual_assets.enemy_attack_fx_texture("grunt", animation_frame)
	if texture == null:
		return null

	combat_fx_serial += 1
	var sprite := TextureRect.new()
	sprite.name = "EnemyAttackFx_%03d_%s" % [combat_fx_serial, visual_id]
	sprite.texture = texture
	sprite.custom_minimum_size = size
	sprite.size = size
	sprite.pivot_offset = size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 430 + combat_fx_serial % 50
	sprite.modulate = tint
	sprite.position = _fx_layer_position_for_center(center, size)
	_apply_texture_animation(sprite, ANIMATION_ENEMY_ATTACK_FX, visual_id, "")
	combat_fx_layer.add_child(sprite)
	return sprite


func _create_player_hit_fx_sprite(center: Vector2, size: Vector2, tint: Color) -> TextureRect:
	if combat_fx_layer == null:
		return null
	var texture := visual_assets.player_hurt_fx_texture(animation_frame)
	if texture == null:
		return null

	combat_fx_serial += 1
	var sprite := TextureRect.new()
	sprite.name = "PlayerHitFx_%03d" % combat_fx_serial
	sprite.texture = texture
	sprite.custom_minimum_size = size
	sprite.size = size
	sprite.pivot_offset = size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 470 + combat_fx_serial % 50
	sprite.modulate = tint
	sprite.position = _fx_layer_position_for_center(center, size)
	_apply_texture_animation(sprite, ANIMATION_PLAYER_HIT_FX, "", "")
	combat_fx_layer.add_child(sprite)
	return sprite


func _wait_for_combat_vfx_to_finish() -> void:
	if combat_fx_layer == null:
		return
	var deadline_msec := Time.get_ticks_msec() + int(COMBAT_VFX_TIMEOUT_SECONDS * 1000.0)
	while combat_fx_layer.get_child_count() > 0 and Time.get_ticks_msec() < deadline_msec:
		await get_tree().process_frame


func _card_projectile_action(card) -> String:
	if card == null:
		return "single_projectile"
	if card.id == "axe" or card.id == "cross" or card.id == "runetracer" or card.id == "bone":
		return "bounce_projectile"
	return "single_projectile"


func _card_vfx_color(card) -> Color:
	if card == null:
		return Color(1.0, 1.0, 1.0, 0.88)
	if card.id == "fire_wand" or card.id == "cherry_bomb":
		return Color(1.0, 0.38, 0.16, 0.90)
	if card.id == "lightning_ring" or card.id == "magic_wand" or card.id == "runetracer":
		return Color(0.45, 0.78, 1.0, 0.90)
	if card.id == "pentagram" or card.id == "ebony_wings":
		return Color(0.72, 0.42, 1.0, 0.90)
	if card.id == "garlic":
		return Color(0.44, 0.92, 0.50, 0.88)
	if card.id == "santa_water" or card.id == "cross" or card.id == "peachone":
		return Color(1.0, 0.92, 0.56, 0.90)
	if card.id == "song_of_mana":
		return Color(0.60, 0.72, 1.0, 0.90)
	return Color(1.0, 0.86, 0.58, 0.88)


func _enemy_vfx_color(visual_id: String) -> Color:
	if visual_id == "bat":
		return Color(0.72, 0.32, 1.0, 0.88)
	if visual_id == "guard":
		return Color(0.72, 0.84, 1.0, 0.86)
	if visual_id == "brute":
		return Color(1.0, 0.50, 0.20, 0.88)
	if visual_id == "boss_guard":
		return Color(0.92, 0.18, 0.22, 0.88)
	if visual_id == "stage_boss":
		return Color(0.78, 0.24, 1.0, 0.90)
	return Color(1.0, 0.36, 0.18, 0.88)


func _points_center(points: Array) -> Vector2:
	if points.is_empty():
		return _fallback_vfx_center()
	var sum := Vector2.ZERO
	for raw_point in points:
		var point: Vector2 = raw_point
		sum += point
	return sum / float(points.size())


func _points_span_size(points: Array, minimum_size: Vector2, padding: Vector2) -> Vector2:
	if points.is_empty():
		return minimum_size
	var first_point: Vector2 = points[0]
	var min_x := first_point.x
	var max_x := first_point.x
	var min_y := first_point.y
	var max_y := first_point.y
	for raw_point in points:
		var point: Vector2 = raw_point
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return Vector2(maxf(minimum_size.x, max_x - min_x + padding.x), maxf(minimum_size.y, max_y - min_y + padding.y))


func _enemy_stage_center(context: Dictionary) -> Vector2:
	var stage_rect: Rect2 = context.get("enemy_stage_rect", _safe_control_rect(combat_enemy_panel))
	if stage_rect.size != Vector2.ZERO:
		return stage_rect.get_center()
	return _fallback_vfx_center()


func _safe_control_center(control: Control) -> Vector2:
	var rect := _safe_control_rect(control)
	if rect.size == Vector2.ZERO:
		return Vector2.ZERO
	return rect.get_center()


func _safe_control_rect(control: Control) -> Rect2:
	if control == null or not control.is_inside_tree():
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return control.get_global_rect()


func _fallback_vfx_center() -> Vector2:
	return get_viewport_rect().size * 0.5


func _fx_layer_position_for_center(center: Vector2, size: Vector2) -> Vector2:
	if combat_fx_layer == null:
		return center - size * 0.5
	return combat_fx_layer.get_global_transform().affine_inverse() * center - size * 0.5


func _create_enemy_card(enemy: CombatantState, row_index: int, is_target: bool, preview_kind: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "EnemyCard_%s" % enemy.id
	card.custom_minimum_size = ENEMY_CARD_SIZE
	_style_enemy_card(card, row_index, is_target, preview_kind)

	var content := VBoxContainer.new()
	content.name = "EnemyCardContent_%s" % enemy.id
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)

	var intent_colors := _enemy_intent_colors(enemy)
	var intent_badge := _create_badge(
		_enemy_intent_text(enemy),
		intent_colors[0],
		intent_colors[1],
		12,
		Vector2(54, 20)
	)
	intent_badge.name = "EnemyIntentBadge"
	content.add_child(intent_badge)

	var visual_id := _enemy_visual_id(enemy)
	var animation_action := _enemy_animation_action(enemy)
	var portrait_texture := visual_assets.enemy_texture(visual_id, animation_action, animation_frame)
	if portrait_texture != null:
		var portrait := TextureRect.new()
		portrait.name = "EnemyPortrait"
		portrait.texture = portrait_texture
		portrait.custom_minimum_size = ENEMY_PORTRAIT_SIZE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_apply_texture_animation(portrait, ANIMATION_ENEMY, visual_id, animation_action)
		content.add_child(portrait)

	var safe_enemy_max := enemy.max_health
	if safe_enemy_max < 1:
		safe_enemy_max = 1
	var health_bar := ProgressBar.new()
	health_bar.name = "EnemyHealthBar"
	health_bar.min_value = 0.0
	health_bar.max_value = float(safe_enemy_max)
	health_bar.value = float(clampi(enemy.health, 0, safe_enemy_max))
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(116, 9)
	_style_progress_bar(health_bar, Color(0.70, 0.14, 0.12), Color(0.10, 0.04, 0.04))
	content.add_child(health_bar)

	var name_label := Label.new()
	name_label.name = "EnemyName"
	name_label.text = "%s  血 %s/%s" % [enemy.display_name, enemy.health, enemy.max_health]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	content.add_child(name_label)

	var state_label := Label.new()
	state_label.name = "EnemyStateLabel"
	state_label.text = _enemy_state_text(enemy, is_target, preview_kind)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 12)
	var state_color := COLOR_SELECTED if is_target else Color(0.92, 0.88, 0.82)
	if preview_kind == "exact":
		state_color = Color(1.0, 0.72, 0.30)
	elif preview_kind == "possible":
		state_color = Color(0.62, 0.84, 1.0)
	state_label.add_theme_color_override("font_color", state_color)
	content.add_child(state_label)
	return card


func _enemy_state_text(enemy: CombatantState, is_target: bool, preview_kind: String = "") -> String:
	var parts: Array = []
	if is_target:
		parts.append("当前目标")
	if preview_kind == "exact":
		parts.append("预览命中")
	elif preview_kind == "possible":
		parts.append("可能命中")
	parts.append(_enemy_intent_text(enemy))
	return " · ".join(parts)


func _enemy_intent_text(enemy: CombatantState) -> String:
	var intent := active_combat.enemy_intent_for(enemy)
	var intent_type := str(intent.get("type", CombatState.ENEMY_INTENT_WAIT))
	var amount := int(intent.get("amount", 0))
	if intent_type == CombatState.ENEMY_INTENT_ATTACK:
		return "攻 %s" % amount
	if intent_type == CombatState.ENEMY_INTENT_GUARD:
		return "甲 +%s" % amount
	return "待命"


func _enemy_intent_colors(enemy: CombatantState) -> Array:
	var intent := active_combat.enemy_intent_for(enemy)
	var intent_type := str(intent.get("type", CombatState.ENEMY_INTENT_WAIT))
	if intent_type == CombatState.ENEMY_INTENT_ATTACK:
		return [Color(0.32, 0.10, 0.08), Color(0.88, 0.28, 0.22)]
	if intent_type == CombatState.ENEMY_INTENT_GUARD:
		return [Color(0.12, 0.20, 0.28), Color(0.34, 0.58, 0.82)]
	return [Color(0.18, 0.18, 0.18), Color(0.45, 0.46, 0.48)]


func _on_end_turn_pressed() -> void:
	if combat_animation_locked:
		return
	_end_turn_with_log("手动结束回合。")


func _end_turn_with_log(prefix: String, manage_lock: bool = true) -> void:
	if active_combat == null:
		return
	if manage_lock:
		if combat_animation_locked:
			return
		combat_animation_locked = true
	var enemy_vfx_context := _capture_enemy_turn_vfx_context()
	_play_hand_discard_animation()
	var result := controller.end_turn()
	var damage_taken := int(result.get("damage_taken", 0))
	if damage_taken > 0:
		player_hurt_until_msec = Time.get_ticks_msec() + 520
	_play_enemy_turn_vfx(enemy_vfx_context, damage_taken)
	await _wait_for_combat_vfx_to_finish()

	_sync_from_controller()
	_clamp_selected_hand_index()
	combat_focus = COMBAT_FOCUS_HAND
	combat_log = "%s\n敌人回合：受到 %s 点伤害。" % [prefix, damage_taken]
	if result["type"] == RunController.EVENT_COMBAT_LOST:
		combat_log = "玩家倒下。"
		_set_status_message(str(result.get("run_end_summary", "玩家倒下。")))
	else:
		_mark_all_hand_entry_indices()
	_refresh()
	if result["type"] == RunController.EVENT_COMBAT_LOST:
		_play_combat_transition("冒险结束")
	if result["type"] != RunController.EVENT_COMBAT_LOST:
		await _wait_for_combat_vfx_to_finish()
	if manage_lock:
		combat_animation_locked = false


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
	if result["type"] == RunController.EVENT_COMBAT_WON:
		_play_combat_transition("战斗胜利")


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
	combat_animation_locked = false
	_clear_combat_fx_layer()
	pending_enemy_entry_ids.clear()
	pending_hand_entry_indices.clear()
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
	if combat_animation_locked:
		return
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
	if combat_animation_locked or active_combat == null:
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


func _selected_card():
	if active_combat == null:
		return null
	if selected_hand_index < 0 or selected_hand_index >= active_combat.deck.hand.size():
		return null
	return active_combat.deck.hand[selected_hand_index]


func _selected_card_summary() -> String:
	if combat_focus == COMBAT_FOCUS_END_TURN:
		return "结束回合"
	var card = _selected_card()
	if card == null:
		return "无"
	var multiplier_percent := _preview_card_multiplier_basis_points(card)
	if card.base_damage <= 0:
		return "%s | 无伤害 | 倍率 %s%%" % [card.display_name, multiplier_percent]
	return "%s | 预览伤害 %s | %s | 倍率 %s%%" % [
		card.display_name,
		_preview_card_damage(card),
		_selected_card_target_summary(card),
		multiplier_percent,
	]


func _combat_hand_title_text() -> String:
	if active_combat == null:
		return "手牌"
	return "手牌（%s）  抽牌堆 %s  弃牌堆 %s" % [
		active_combat.deck.hand.size(),
		active_combat.deck.draw_pile.size(),
		active_combat.deck.discard_pile.size(),
	]


func _selected_card_target_summary(card) -> String:
	if card == null or active_combat == null or card.base_damage <= 0:
		return "目标 自身"
	var preview_targets := _selected_card_preview_targets(card)
	var exact_count := 0
	var possible_count := 0
	for enemy_id in preview_targets.keys():
		if str(preview_targets[enemy_id]) == "possible":
			possible_count += 1
		else:
			exact_count += 1
	if possible_count > 0:
		return "可能目标 %s" % possible_count
	return "目标 %s" % exact_count


func _clear_combat_hand() -> void:
	for child in combat_hand_row.get_children():
		combat_hand_row.remove_child(child)
		child.queue_free()


func _clear_enemy_rows() -> void:
	for child in combat_enemy_rows.get_children():
		combat_enemy_rows.remove_child(child)
		child.queue_free()


func _clear_combat_fx_layer() -> void:
	if combat_fx_layer == null:
		return
	for child in combat_fx_layer.get_children():
		combat_fx_layer.remove_child(child)
		child.queue_free()


func _clear_reward_choices() -> void:
	for child in reward_choice_row.get_children():
		reward_choice_row.remove_child(child)
		child.queue_free()


func _card_button_text(card, unavailable_reason: String = "") -> String:
	var parts := [
		card.display_name,
		"",
		"费用：%s" % card.cost,
	]
	if card.base_damage > 0:
		if card.target_mode == CardDefinition.TargetMode.FRONT_ROW:
			parts.append("前排攻击：%s" % card.base_damage)
		elif card.target_mode == CardDefinition.TargetMode.ALL_ENEMIES:
			parts.append("全体攻击：%s" % card.base_damage)
		elif card.target_mode == CardDefinition.TargetMode.RANDOM_ENEMIES:
			parts.append("随机命中：%s x%s" % [card.base_damage, card.hit_count])
		elif card.target_mode == CardDefinition.TargetMode.BOUNCE:
			parts.append("弹跳：%s x%s" % [card.base_damage, card.hit_count])
		elif card.hit_count > 1:
			parts.append("连续攻击：%s x%s" % [card.base_damage, card.hit_count])
		else:
			parts.append("攻击：%s" % card.base_damage)
		parts.append("预览总伤害：%s" % _preview_card_damage(card))
	if card.block > 0:
		parts.append("防御：%s" % card.block)
	if card.draw_count > 0:
		parts.append("抽牌：%s" % card.draw_count)
	if active_combat != null:
		parts.append("")
		parts.append("连击 → %s" % active_combat.combo.preview_chain_for(card))
		parts.append("倍率：%s%%" % _preview_card_multiplier_basis_points(card))
	if unavailable_reason != "":
		parts.append("")
		parts.append("不可用：%s" % unavailable_reason)
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


func _create_card_art(card_id: String, minimum_size: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.texture = visual_assets.card_texture(card_id, animation_frame)
	art.custom_minimum_size = minimum_size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_texture_animation(art, ANIMATION_CARD, card_id, "")
	return art


func _create_badge(text: String, fill_color: Color, border_color: Color, font_size: int, minimum_size: Vector2) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	badge.add_child(label)
	return badge


func _card_stat_badge_texts(card) -> Array:
	var badges: Array = []
	if card.base_damage > 0:
		badges.append("攻 %s" % _preview_card_damage(card))
	if card.block > 0:
		badges.append("防 %s" % card.block)
	if card.draw_count > 0:
		badges.append("抽 %s" % card.draw_count)
	if card.hit_count > 1:
		badges.append("段 %s" % card.hit_count)
	if badges.is_empty():
		badges.append("技")
	return badges


func _choice_stat_badge_texts(choice: Dictionary) -> Array:
	var badges: Array = []
	var damage := int(choice.get("base_damage", 0))
	var block := int(choice.get("block", 0))
	var draw_count := int(choice.get("draw_count", 0))
	var hit_count := int(choice.get("hit_count", 1))
	if damage > 0:
		badges.append("攻 %s" % damage)
	if block > 0:
		badges.append("防 %s" % block)
	if draw_count > 0:
		badges.append("抽 %s" % draw_count)
	if hit_count > 1:
		badges.append("段 %s" % hit_count)
	if badges.is_empty():
		badges.append("技")
	return badges


func _set_mouse_filter_recursive(node: Node, mouse_filter_value: int) -> void:
	if node is Control:
		var control := node as Control
		control.mouse_filter = mouse_filter_value
	for child in node.get_children():
		_set_mouse_filter_recursive(child, mouse_filter_value)


func _preview_card_multiplier_basis_points(card) -> int:
	if active_combat == null or card == null:
		return 100
	return active_combat.combo.preview_multiplier_basis_points(card)


func _preview_card_damage(card) -> int:
	if card == null or card.base_damage <= 0:
		return 0
	if active_combat != null and active_combat.has_method("preview_damage_for_card"):
		return active_combat.preview_damage_for_card(card)
	return int((card.base_damage * _preview_card_multiplier_basis_points(card)) / 100)


func _card_unavailable_reason(card) -> String:
	if active_combat == null or card == null:
		return ""
	if active_combat.is_victory() or active_combat.is_defeat():
		return "战斗已结束"
	if card.cost > active_combat.mana:
		return "法力不足"
	if card.base_damage > 0 and _selected_card_preview_targets(card).is_empty():
		return "没有目标"
	return ""


func _has_playable_card() -> bool:
	if active_combat == null:
		return false
	for card in active_combat.deck.hand:
		if _card_unavailable_reason(card) == "":
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


func _style_progress_bar(progress_bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.border_color = Color(0.04, 0.04, 0.05)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_width_right = 1
	background.border_width_bottom = 1
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("background", background)
	progress_bar.add_theme_stylebox_override("fill", fill)


func _style_card_slot(slot: MarginContainer, is_selected: bool, hand_index: int, hand_size: int) -> void:
	var top_margin := 0 if is_selected else CARD_SELECTED_LIFT
	slot.add_theme_constant_override("margin_top", top_margin)
	slot.add_theme_constant_override("margin_bottom", CARD_SELECTED_LIFT - top_margin)
	slot.add_theme_constant_override("margin_left", 0)
	slot.add_theme_constant_override("margin_right", 0)
	slot.rotation_degrees = _card_fan_rotation(hand_index, hand_size, is_selected)
	slot.scale = Vector2(1.06, 1.06) if is_selected else Vector2.ONE
	slot.pivot_offset = CARD_SLOT_SIZE * 0.5
	slot.z_index = 100 if is_selected else hand_index


func _card_fan_rotation(hand_index: int, hand_size: int, is_selected: bool) -> float:
	if is_selected or hand_size <= 1:
		return 0.0
	var middle := float(hand_size - 1) / 2.0
	return clampf(
		(float(hand_index) - middle) * HAND_FAN_ROTATION_STEP,
		-HAND_FAN_ROTATION_LIMIT,
		HAND_FAN_ROTATION_LIMIT
	)


func _style_card_button(
	button: Button,
	card,
	has_combo_multiplier: bool = false,
	is_selected: bool = false,
	is_unavailable: bool = false
) -> void:
	var color := Color(0.18, 0.20, 0.24)
	if card.base_damage > 0:
		color = Color(0.42, 0.16, 0.14)
	elif card.block > 0:
		color = Color(0.15, 0.28, 0.44)
	elif card.draw_count > 0:
		color = Color(0.20, 0.36, 0.26)
	if is_unavailable:
		color = Color(0.20, 0.18, 0.18)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.08) if has_combo_multiplier else color
	if has_combo_multiplier:
		normal.border_color = COLOR_COMBO_HIGHLIGHT
	elif is_unavailable:
		normal.border_color = Color(0.58, 0.34, 0.30)
	elif is_selected:
		normal.border_color = COLOR_SELECTED
	else:
		normal.border_color = Color(0.08, 0.09, 0.10)
	normal.border_width_left = 4
	normal.border_width_top = 4
	normal.border_width_right = 4
	normal.border_width_bottom = 4
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
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


func _style_enemy_card(card: PanelContainer, row_index: int, is_target: bool, preview_kind: String = "") -> void:
	var color := COLOR_ENEMY_PANEL if row_index == 0 else COLOR_ENEMY_PANEL.darkened(0.14)
	var is_preview := preview_kind != ""
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.lightened(0.10) if is_target or is_preview else Color(color.r, color.g, color.b, 0.38)
	if is_target:
		normal.border_color = COLOR_SELECTED
	elif preview_kind == "exact":
		normal.border_color = Color(1.0, 0.58, 0.18)
	elif preview_kind == "possible":
		normal.border_color = Color(0.42, 0.66, 1.0)
	else:
		normal.border_color = Color(0.24, 0.24, 0.24, 0.55)
	var border_width := 2 if is_target or is_preview else 1
	normal.border_width_left = border_width
	normal.border_width_top = border_width
	normal.border_width_right = border_width
	normal.border_width_bottom = border_width
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
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


func _refresh_animated_assets() -> void:
	if combat_player_portrait != null and combat_player_portrait.has_meta(ANIMATION_META_TYPE):
		var current_action := str(combat_player_portrait.get_meta(ANIMATION_META_ACTION, ""))
		var desired_action := _player_combat_action()
		if current_action != desired_action:
			_apply_texture_animation(combat_player_portrait, ANIMATION_PLAYER_COMBAT, "", desired_action)
	_refresh_animated_controls(self)


func _refresh_animated_controls(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is Button and child.has_meta(ANIMATION_META_TYPE):
			var button := child as Button
			var texture := _animation_texture_for(button)
			if texture != null:
				button.icon = texture
		elif child is TextureRect and child.has_meta(ANIMATION_META_TYPE):
			var texture_rect := child as TextureRect
			var texture := _animation_texture_for(texture_rect)
			if texture != null:
				texture_rect.texture = texture
		_refresh_animated_controls(child)


func _apply_cell_icon(button: Button, position: Vector2i, tile: DungeonTile) -> void:
	var visual := _map_cell_visual(button)
	if visual == null:
		return
	var glyph := _map_cell_glyph(button)
	if position == run_state.dungeon_map.player_position:
		_apply_texture_animation(visual, ANIMATION_PLAYER, "", "")
		_apply_cell_texture(visual, glyph, _animation_texture_for(visual))
		return

	var map_enemy_visual_id := _map_enemy_visual_id(tile.tile_type)
	if map_enemy_visual_id != "":
		_apply_texture_animation(visual, ANIMATION_ENEMY, map_enemy_visual_id, "idle")
		_apply_cell_texture(visual, glyph, _animation_texture_for(visual))
		return

	_clear_animation_meta(visual)
	_apply_cell_texture(visual, glyph, _cell_texture(position, tile, animation_frame))


func _apply_cell_texture(visual: TextureRect, glyph: Label, texture: Texture2D) -> void:
	visual.texture = texture
	visual.visible = texture != null
	if glyph != null:
		glyph.visible = texture == null and glyph.text != ""


func _map_cell_visual(button: Button) -> TextureRect:
	return button.find_child("CellVisual", false, false) as TextureRect


func _map_cell_glyph(button: Button) -> Label:
	return button.find_child("CellGlyph", false, false) as Label


func _cell_texture(position: Vector2i, tile: DungeonTile, frame_index: int = 0) -> Texture2D:
	if position == run_state.dungeon_map.player_position:
		return visual_assets.player_map_texture(frame_index)
	var stage_id := ""
	if run_state != null and run_state.current_stage != null:
		stage_id = run_state.current_stage.id
	return visual_assets.tile_texture(tile.tile_type, run_state.dungeon_map.is_exit_unlocked(), frame_index, stage_id)


func _map_enemy_visual_id(tile_type: int) -> String:
	if tile_type == DungeonTile.TileType.ENEMY:
		return "grunt"
	if tile_type == DungeonTile.TileType.ELITE:
		return "brute"
	if tile_type == DungeonTile.TileType.BOSS:
		return "stage_boss"
	return ""


func _enemy_visual_id(enemy: CombatantState) -> String:
	if enemy == null:
		return ""
	if enemy.visual_id != "":
		return enemy.visual_id
	if enemy.display_name == "刺蝠":
		return "bat"
	if enemy.display_name == "盾卫":
		return "guard"
	if enemy.display_name == "重甲兵":
		return "brute"
	if enemy.display_name == "首领护卫":
		return "boss_guard"
	if enemy.display_name == "首领":
		return "stage_boss"
	return "grunt"


func _enemy_animation_action(enemy: CombatantState) -> String:
	if active_combat == null or enemy == null:
		return "idle"
	var intent := active_combat.enemy_intent_for(enemy)
	var intent_type := str(intent.get("type", CombatState.ENEMY_INTENT_WAIT))
	if intent_type == CombatState.ENEMY_INTENT_ATTACK:
		return "attack"
	if intent_type == CombatState.ENEMY_INTENT_GUARD:
		return "guard"
	return "idle"


func _player_combat_action() -> String:
	if active_combat == null or active_combat.player == null:
		return "idle"
	if active_combat.player.health <= 0:
		return "death"
	if player_hurt_until_msec > Time.get_ticks_msec():
		return "hurt"

	var selected_card = _selected_card()
	if selected_card != null:
		if selected_card.base_damage > 0:
			return "attack"
		if selected_card.block > 0:
			return "guard"
		if selected_card.draw_count > 0:
			return "cast"

	if active_combat.player.block > 0:
		return "guard"
	return "idle"


func _apply_button_animation(
	button: Button,
	animation_type: String,
	asset_id: String,
	max_width: int,
	action: String = ""
) -> void:
	button.set_meta(ANIMATION_META_TYPE, animation_type)
	button.set_meta(ANIMATION_META_ASSET_ID, asset_id)
	button.set_meta(ANIMATION_META_ACTION, action)
	button.set_meta(ANIMATION_META_MAX_WIDTH, max_width)
	_apply_button_icon(button, _animation_texture_for(button), max_width)


func _apply_texture_animation(texture_rect: TextureRect, animation_type: String, asset_id: String, action: String) -> void:
	texture_rect.set_meta(ANIMATION_META_TYPE, animation_type)
	texture_rect.set_meta(ANIMATION_META_ASSET_ID, asset_id)
	texture_rect.set_meta(ANIMATION_META_ACTION, action)


func _clear_button_animation(button: Button) -> void:
	_clear_animation_meta(button)


func _clear_animation_meta(node: Object) -> void:
	if node.has_meta(ANIMATION_META_TYPE):
		node.remove_meta(ANIMATION_META_TYPE)
	if node.has_meta(ANIMATION_META_ASSET_ID):
		node.remove_meta(ANIMATION_META_ASSET_ID)
	if node.has_meta(ANIMATION_META_ACTION):
		node.remove_meta(ANIMATION_META_ACTION)
	if node.has_meta(ANIMATION_META_MAX_WIDTH):
		node.remove_meta(ANIMATION_META_MAX_WIDTH)


func _animation_texture_for(node: Object) -> Texture2D:
	var animation_type := str(node.get_meta(ANIMATION_META_TYPE, ""))
	var asset_id := str(node.get_meta(ANIMATION_META_ASSET_ID, ""))
	var action := str(node.get_meta(ANIMATION_META_ACTION, ""))
	if animation_type == ANIMATION_PLAYER:
		return visual_assets.player_map_texture(animation_frame)
	if animation_type == ANIMATION_PLAYER_COMBAT:
		if action == "":
			action = "idle"
		return visual_assets.player_combat_texture(action, animation_frame)
	if animation_type == ANIMATION_ENEMY:
		if action == "":
			action = "idle"
		return visual_assets.enemy_texture(asset_id, action, animation_frame)
	if animation_type == ANIMATION_CARD:
		return visual_assets.card_texture(asset_id, animation_frame)
	if animation_type == ANIMATION_CARD_FX:
		if action == "":
			action = "single_impact"
		if asset_id != "":
			var card_fx := visual_assets.card_attack_fx_texture(asset_id, animation_frame)
			if card_fx != null:
				return card_fx
		return visual_assets.card_fx_texture(action, animation_frame)
	if animation_type == ANIMATION_ENEMY_ATTACK_FX:
		return visual_assets.enemy_attack_fx_texture(asset_id, animation_frame)
	if animation_type == ANIMATION_PLAYER_HIT_FX:
		return visual_assets.player_hurt_fx_texture(animation_frame)
	return null


func _apply_button_icon(button: Button, texture: Texture2D, max_width: int) -> void:
	button.icon = texture
	button.add_theme_constant_override("icon_max_width", max_width)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = false


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
