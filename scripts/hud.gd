class_name HUD
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var hint_label: Label = $HintLabel
@onready var menu_button = $MenuButton
@onready var confirm: ConfirmDialog = $ConfirmDialog

const CREAM_BUTTON := preload("res://scenes/cream_button.tscn")

var _banner: Label
var _sound_button: CreamButton
var _base := {}   # posiciones originales (offsets) para volver a aplicar el área segura


func _ready() -> void:
	menu_button.pressed.connect(request_exit)
	confirm.confirmed.connect(_go_to_menu)

	# Letrero grande para anunciar el cambio de nivel (se crea por código)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 56)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_banner.add_theme_constant_override("outline_size", 14)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)
	_fit_banner()

	# Menú y Sonido van arriba a la izquierda, debajo del marcador. Abajo estorbaban a la
	# bandeja de figuras (que se ensancha con cada nivel) en pantallas 16:9 y 16:10.
	menu_button.custom_minimum_size = Vector2(190, 64)
	menu_button.font_size = 24
	_place_top_left(menu_button, 68.0)

	# Botón rápido de sonido junto al de Menú (silencia también la vibración)
	_sound_button = CREAM_BUTTON.instantiate()
	_sound_button.custom_minimum_size = Vector2(190, 64)
	_sound_button.font_size = 24
	add_child(_sound_button)
	_place_top_left(_sound_button, 140.0)
	_sound_button.pressed.connect(_on_sound_pressed)
	_refresh_sound_button()

	for c in [score_label, menu_button, _sound_button]:
		_base[c] = Vector4(c.offset_left, c.offset_top, c.offset_right, c.offset_bottom)
	_fit_screen()
	get_viewport().size_changed.connect(_fit_screen)


## Ancla un botón a la esquina superior izquierda (24 px del borde, `top` px desde arriba).
func _place_top_left(c: Control, top: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 0.0
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.grow_horizontal = Control.GROW_DIRECTION_END
	c.grow_vertical = Control.GROW_DIRECTION_END
	c.offset_left = 24.0
	c.offset_right = 24.0 + 190.0
	c.offset_top = top
	c.offset_bottom = top + 64.0


func _fit_screen() -> void:
	_fit_banner()
	# Deja libre el área de muescas y esquinas del celular (en escritorio no hace nada)
	var safe := SafeArea.insets(get_viewport())
	for c in _base:
		var b: Vector4 = _base[c]
		c.offset_left = b.x + safe.x
		c.offset_right = b.z + safe.x
		c.offset_top = b.y + safe.y
		c.offset_bottom = b.w + safe.y


func _on_sound_pressed() -> void:
	Sound.toggle_mute()
	_refresh_sound_button()


func _refresh_sound_button() -> void:
	_sound_button.text = "Sonido: No" if Sound.is_muted() else "Sonido: Sí"


## El letrero ocupa todo el ancho visible (la pantalla del celular puede ser más ancha que 1280)
func _fit_banner() -> void:
	var vp := get_viewport().get_visible_rect().size
	_banner.size = Vector2(vp.x, 90)
	_banner.position = Vector2(0, 230 + maxf(vp.y - 720.0, 0.0) * 0.5)
	_banner.pivot_offset = _banner.size / 2.0


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


## Pide confirmación antes de volver al menú (botón "Menú" y tecla Esc).
func request_exit() -> void:
	confirm.ask("¿Volver al menú?", "Si sales ahora perderás tu progreso de esta partida.", "Sí, salir", "Seguir jugando")


## Botón "Atrás" de Android: cancela el aviso si está abierto; si no, pide volver al menú.
func handle_back() -> void:
	if confirm.is_open():
		confirm.cancel()
	else:
		request_exit()


## true si la ventana de confirmación está abierta
func is_dialog_open() -> bool:
	return confirm.is_open()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
