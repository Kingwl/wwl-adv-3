extends Control

@onready var title_label: Label = $Title


func _ready() -> void:
	title_label.text = "WWL 大冒险 3"
