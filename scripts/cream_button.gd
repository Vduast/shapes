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

var _hover := 0.0
var _press := 0.0
var _hovered := false
var _down := false
var _mat: ShaderMaterial

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


func _on_resized() -> void:
	pivot_offset = size / 2.0
	_mat.set_shader_parameter("rect_size", size)


func _on_mouse_entered() -> void:
	_hovered = true


func _on_mouse_exited() -> void:
	_hovered = false
	_down = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		else:
			if _down and _hovered:
				pressed.emit()
			_down = false


func _process(delta: float) -> void:
	# Suavizado exponencial: se ve igual a cualquier FPS
	_hover = lerpf(_hover, 1.0 if _hovered else 0.0, 1.0 - exp(-14.0 * delta))
	_press = lerpf(_press, 1.0 if _down else 0.0, 1.0 - exp(-24.0 * delta))
	_mat.set_shader_parameter("hover", _hover)
	_mat.set_shader_parameter("press", _press)

	# Crece un poco con el ratón encima, se achica al presionar y "tiembla" suave
	scale = Vector2.ONE * (1.0 + 0.04 * _hover - 0.03 * _press)
	rotation = sin(Time.get_ticks_msec() * 0.014) * 0.012 * _hover

	# El texto acompaña a la cara del botón (sube 3 px en reposo, baja al presionar)
	var y := -3.0 + 4.0 * _press
	_label.offset_top = y
	_label.offset_bottom = y
