class_name Monster
extends Area2D

signal food_accepted(shape_type: int, mask: int)
signal food_rejected(shape_type: int, mask: int)

## Color con el que empieza el slime (se puede cambiar en el Inspector)
@export var start_color := Color(0.35, 0.75, 0.85)

var wanted_shape: int = 0
var wanted_mask: int = GameData.ANY_COLOR
var stage := 0

var _excite := 0.0
var _squish := 0.0
var _busy := false
var _current_color := Color.WHITE
var _last_request := {}

@onready var body: ColorRect = $Body
@onready var bubble: RequestBubble = $RequestBubble
@onready var absorb_point: Marker2D = $AbsorbPoint


func _ready() -> void:
	body.material = body.material.duplicate()
	_current_color = start_color
	_set_body_color(start_color)
	new_request()


func _process(delta: float) -> void:
	if not _busy:
		var hovering := false
		for a in get_overlapping_areas():
			if a.has_method("get_eaten"):
				hovering = true
				break
		_excite = lerpf(_excite, 1.0 if hovering else 0.0, 1.0 - exp(-10.0 * delta))
	var mat := body.material as ShaderMaterial
	mat.set_shader_parameter("excite", _excite)
	mat.set_shader_parameter("squish", _squish)


## Cambia de nivel. Con refresh = true pide algo nuevo de inmediato.
func set_stage(value: int, refresh: bool = false) -> void:
	stage = value
	if refresh:
		new_request()


func new_request() -> void:
	var r := GameData.random_request(stage, _last_request)
	_last_request = r
	wanted_shape = r["shape"]
	wanted_mask = r["mask"]
	# Si acepta cualquier color, la burbuja muestra la forma en blanco
	bubble.show_request(wanted_shape, 0 if wanted_mask == GameData.ANY_COLOR else wanted_mask)


func try_eat(shape) -> bool:
	if _busy:
		return false
	var shape_ok: bool = shape.shape_type == wanted_shape
	var color_ok: bool = wanted_mask == GameData.ANY_COLOR or shape.color_mask == wanted_mask
	if shape_ok and color_ok:
		_accept(shape)
		return true
	_reject(shape)
	return false


func _accept(shape) -> void:
	_busy = true
	var type: int = shape.shape_type
	var mask: int = shape.color_mask

	shape.get_eaten(absorb_point.global_position)
	if mask != 0:  # una figura sin pintar no cambia el color del slime
		_change_color(GameData.mask_to_color(mask))
	food_accepted.emit(type, mask)

	_excite = 1.0
	create_tween().tween_property(self, "_excite", 0.0, 0.7)
	var t := create_tween()
	t.tween_property(self, "_squish", 1.0, 0.10) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_squish", -0.6, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_squish", 0.0, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(_finish_eating).set_delay(0.15)


func _finish_eating() -> void:
	_busy = false
	new_request()


func _reject(shape) -> void:
	_busy = true
	food_rejected.emit(shape.shape_type, shape.color_mask)
	var t := create_tween()
	t.tween_property(self, "_squish", 0.5, 0.08)
	t.tween_property(self, "_squish", -0.3, 0.08)
	t.tween_property(self, "_squish", 0.0, 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _busy = false)


func _change_color(to: Color) -> void:
	var from := _current_color
	_current_color = to
	create_tween().tween_method(_set_body_color, from, to, 0.5)


func _set_body_color(c: Color) -> void:
	(body.material as ShaderMaterial).set_shader_parameter("body_color", c)
