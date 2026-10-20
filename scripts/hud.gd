class_name HUD
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var hint_label: Label = $HintLabel
@onready var menu_button = $MenuButton

var _banner: Label


func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)

	# Letrero grande para anunciar el cambio de nivel (se crea por código)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 56)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_banner.add_theme_constant_override("outline_size", 14)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.size = Vector2(1280, 90)
	_banner.position = Vector2(0, 230)
	_banner.pivot_offset = _banner.size / 2.0
	_banner.modulate.a = 0.0
	add_child(_banner)


func set_progress(level: int, done: int, goal: int) -> void:
	if goal > 0:
		score_label.text = "Nivel %d   %d/%d" % [level, done, goal]
	else:
		score_label.text = "Nivel %d   ★ %d" % [level, done]


func set_hint(text: String) -> void:
	hint_label.text = text


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE * 0.4
	var t := create_tween()
	t.tween_property(_banner, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.6)
	t.tween_property(_banner, "modulate:a", 0.0, 0.5)


## Vuelve al menú principal
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
