extends Control

@onready var title_label: Label = $Title


func _ready() -> void:
	title_label.text = "大冒险3"
