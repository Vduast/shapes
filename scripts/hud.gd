class_name HUD
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var hint_label: Label = $HintLabel
@onready var menu_button = $MenuButton
@onready var confirm: ConfirmDialog = $ConfirmDialog

const CREAM_BUTTON := preload("res://scenes/cream_button.tscn")
const DOTS_SHADER := preload("res://shaders/progress_dots.gdshader")
const DOT_SIZE := 48.0

var _banner: Label
var _banner_star: ColorRect
var _badge: ColorRect
var _dots: ColorRect
var _sound_button: CreamButton
var _base := {}   # posiciones originales (offsets) para volver a aplicar el área segura


func _ready() -> void:
	menu_button.pressed.connect(request_exit)
	confirm.confirmed.connect(_go_to_menu)

	# Letrero grande para anunciar el cambio de nivel (se crea por código)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 96)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_banner.add_theme_constant_override("outline_size", 14)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	# Estrella dorada detrás del número del nivel
	_banner_star = Icons.make(Icons.STAR, 230.0, Color(1, 1, 1))
	_banner_star.show_behind_parent = true
	_banner.add_child(_banner_star)
	add_child(_banner)
	_fit_banner()

	# Marcador sin texto: estrella con el número de nivel + bolitas que se llenan con los aciertos
	_badge = Icons.make(Icons.STAR, 80.0, Color(1, 1, 1))
	add_child(_badge)
	move_child(_badge, score_label.get_index())   # la estrella va detrás del número
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 34)
	score_label.add_theme_color_override("font_color", Icons.NAVY)
	_place(score_label, 20.0, 12.0, 80.0, 80.0)
	_place(_badge, 20.0, 12.0, 80.0, 80.0)

	_dots = ColorRect.new()
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dots_mat := ShaderMaterial.new()
	dots_mat.shader = DOTS_SHADER
	_dots.material = dots_mat
	add_child(_dots)

	# Menú (casa) y Sonido (bocina) arriba a la izquierda, debajo del marcador. Abajo estorbaban
	# a la bandeja de figuras (que se ensancha con cada nivel) en pantallas 16:9 y 16:10.
	menu_button.custom_minimum_size = Vector2(76, 76)
	menu_button.icon = Icons.HOME
	_place(menu_button, 24.0, 104.0, 76.0, 76.0)

	# Botón rápido de sonido junto al de Menú (silencia también la vibración)
	_sound_button = CREAM_BUTTON.instantiate()
	_sound_button.custom_minimum_size = Vector2(76, 76)
	add_child(_sound_button)
	_place(_sound_button, 112.0, 104.0, 76.0, 76.0)
	_sound_button.pressed.connect(_on_sound_pressed)
	_refresh_sound_button()

	set_progress(1, 0, 0)
	for c in [score_label, _badge, _dots, menu_button, _sound_button]:
		_base[c] = Vector4(c.offset_left, c.offset_top, c.offset_right, c.offset_bottom)
	_fit_screen()
	get_viewport().size_changed.connect(_fit_screen)


## Coloca un control anclado arriba a la izquierda (x, y desde la esquina; w, h de tamaño).
func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 0.0
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.grow_horizontal = Control.GROW_DIRECTION_END
	c.grow_vertical = Control.GROW_DIRECTION_END
	c.offset_left = x
	c.offset_right = x + w
	c.offset_top = y
	c.offset_bottom = y + h


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
	_sound_button.icon = Icons.SOUND_OFF if Sound.is_muted() else Icons.SOUND_ON


## El letrero ocupa todo el ancho visible (la pantalla del celular puede ser más ancha que 1280)
func _fit_banner() -> void:
	var vp := get_viewport().get_visible_rect().size
	_banner.size = Vector2(vp.x, 120)
	_banner.position = Vector2(0, 215 + maxf(vp.y - 720.0, 0.0) * 0.5)
	_banner.pivot_offset = _banner.size / 2.0
	_banner_star.position = (_banner.size - _banner_star.size) / 2.0


## Estrella con el número de nivel + bolitas de progreso (goal = 0: nivel sin fin, bolitas cíclicas)
func set_progress(level: int, done: int, goal: int) -> void:
	score_label.text = str(level)
	var count := goal if goal > 0 else 7
	var filled := done if goal > 0 else done % 7
	var mat := _dots.material as ShaderMaterial
	mat.set_shader_parameter("count", float(count))
	mat.set_shader_parameter("filled", float(filled))
	mat.set_shader_parameter("rect_size", Vector2(count * DOT_SIZE, DOT_SIZE))
	_dots.size = Vector2(count * DOT_SIZE, DOT_SIZE)
	_place(_dots, 112.0, 22.0, count * DOT_SIZE, DOT_SIZE)
	if _base.has(_dots):
		_base[_dots] = Vector4(_dots.offset_left, _dots.offset_top, _dots.offset_right, _dots.offset_bottom)
		_fit_screen()


## Sin texto: los niños aún no leen. Se conserva la función por compatibilidad.
func set_hint(_text: String) -> void:
	pass


func show_banner(text: String) -> void:
	_banner.text = text   # solo el número del nivel (la estrella va detrás)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE * 0.4
	var t := create_tween()
	t.tween_property(_banner, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.6)
	t.tween_property(_banner, "modulate:a", 0.0, 0.5)


## Pide confirmación antes de volver al menú (botón "Menú" y tecla Esc).
func request_exit() -> void:
	confirm.ask(Icons.HOME)


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
