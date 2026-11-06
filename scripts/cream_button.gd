class_name CreamButton
extends ColorRect
## Botón crema dibujado por shader (menu_button.gdshader) con texto azul oscuro.
## Emite `pressed` al soltar el clic izquierdo con el ratón encima.

signal pressed

const NAVY := Color(0.07, 0.12, 0.38)

@export var text := "Botón":
	set(value):
		text = value
		if _label:
			_label.text = value
@export var font_size := 34:
	set(value):
		font_size = value
		if _label:
			_label.add_theme_font_size_override("font_size", value)

## Icono dibujado por shader (ver Icons). -1 = sin icono: se muestra `text`.
@export var icon := -1:
	set(value):
		icon = value
		_apply_icon()
@export var icon_tint := Icons.NAVY:
	set(value):
		icon_tint = value
		_apply_icon()

## Si es true el botón se ve apagado y no responde (al intentar presionarlo suena un "no")
@export var disabled := false
## Si es true se ve "iluminado" y respira (para destacar una opción, p. ej. el nivel actual)
@export var emphasized := false

var _shake := 0.0
var _hover := 0.0
var _press := 0.0
var _hovered := false
var _down := false
var _mat: ShaderMaterial
var _icon_rect: ColorRect

@onready var _label: Label = $Label


func _ready() -> void:
	_mat = (material as ShaderMaterial).duplicate()
	material = _mat
	_label.text = text
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", NAVY)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)
	_on_resized()
	_apply_icon()


func _on_resized() -> void:
	pivot_offset = size / 2.0
	_mat.set_shader_parameter("rect_size", size)
	_layout_icon(0.0)


## Muestra el icono (y oculta el texto) o al revés si icon < 0.
func _apply_icon() -> void:
	if _label == null:
		return   # aún no está listo: _ready() vuelve a llamar
	if icon < 0:
		_label.visible = true
		if _icon_rect:
			_icon_rect.visible = false
		return
	_label.visible = false
	if _icon_rect == null:
		_icon_rect = ColorRect.new()
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon_rect)
	_icon_rect.visible = true
	Icons.apply(_icon_rect, icon, icon_tint)
	_layout_icon(0.0)


## El icono es cuadrado, ocupa ~70 % del lado corto del botón y queda centrado.
func _layout_icon(y_shift: float) -> void:
	if _icon_rect == null:
		return
	var s := minf(size.x, size.y) * 0.7
	_icon_rect.size = Vector2(s, s)
	_icon_rect.position = (size - Vector2(s, s)) / 2.0 + Vector2(0.0, y_shift)


func _on_mouse_entered() -> void:
	_hovered = true
	if not disabled:
		Sound.play("hover")


func _on_mouse_exited() -> void:
	_hovered = false
	_down = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		else:
			if _down and _hovered:
				if disabled:
					_shake = 1.0
					Sound.play("locked")
				else:
					Sound.play("click")
					pressed.emit()
			_down = false


func _process(delta: float) -> void:
	# Suavizado exponencial: se ve igual a cualquier FPS
	var hover_target := 0.0
	if not disabled:
		if _hovered:
			hover_target = 1.0
		elif emphasized:
			hover_target = 0.55 + 0.2 * sin(Time.get_ticks_msec() * 0.004)
	_hover = lerpf(_hover, hover_target, 1.0 - exp(-14.0 * delta))
	_press = lerpf(_press, 1.0 if (_down and not disabled) else 0.0, 1.0 - exp(-24.0 * delta))
	modulate = Color(0.62, 0.62, 0.72, 0.9) if disabled else Color.WHITE
	_shake = maxf(_shake - delta * 3.0, 0.0)
	_mat.set_shader_parameter("hover", _hover)
	_mat.set_shader_parameter("press", _press)

	# Crece un poco con el ratón encima, se achica al presionar y "tiembla" suave
	scale = Vector2.ONE * (1.0 + 0.04 * _hover - 0.03 * _press)
	rotation = sin(Time.get_ticks_msec() * 0.014) * 0.012 * _hover + sin(_shake * 40.0) * 0.06 * _shake

	# El texto acompaña a la cara del botón (sube 3 px en reposo, baja al presionar)
	var y := -3.0 + 4.0 * _press
	_label.offset_top = y
	_label.offset_bottom = y
	_layout_icon(y)
