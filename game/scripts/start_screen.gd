extends Control

const UI_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"

@onready var title_label: Label = $Title


func _ready() -> void:
	_apply_ui_font()
	title_label.text = "大冒险3"


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
