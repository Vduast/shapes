class_name Monster
extends Area2D

signal food_accepted(shape_type: int, mask: int)
signal food_rejected(shape_type: int, mask: int)

## Color con el que empieza el slime (se puede cambiar en el Inspector)
@export var start_color := Color(0.35, 0.75, 0.85)

var wanted_shape: int = 0
var wanted_mask: int = GameData.ANY_COLOR
var stage := 0

## Segundos sin que pase nada (ni figuras ni ratón) para que le dé sueño
const SLEEP_AFTER := 14.0

var _excite := 0.0
var _squish := 0.0
var _busy := false
var _hovering := false
var _cheer := false        # el próximo bocado sube de nivel: celebra con la cara grande
var _idle_time := 0.0
var _last_mouse := Vector2.ZERO
var _current_color := Color.WHITE
var _last_request := {}
var _face: SlimeFace

@onready var body: ColorRect = $Body
@onready var bubble: RequestBubble = $RequestBubble
@onready var absorb_point: Marker2D = $AbsorbPoint


func _ready() -> void:
	body.material = body.material.duplicate()
	_current_color = start_color
	_set_body_color(start_color)
	_face = SlimeFace.new(body.material as ShaderMaterial)
	new_request()


func _process(delta: float) -> void:
	if not _busy:
		_hovering = false
		for a in get_overlapping_areas():
			if a.has_method("get_eaten"):
				_hovering = true
				break
		_excite = lerpf(_excite, 1.0 if _hovering else 0.0, 1.0 - exp(-10.0 * delta))
	var mat := body.material as ShaderMaterial
	mat.set_shader_parameter("excite", _excite)
	mat.set_shader_parameter("squish", _squish)

	# Cara: de fondo está tranquilo, emocionado con una figura encima o con sueño si
	# pasa mucho rato sin actividad. Los gestos (comer, rechazar...) pisan esta cara.
	var mouse := get_global_mouse_position()
	if _hovering or mouse.distance_to(_last_mouse) > 2.0:
		_idle_time = 0.0
	else:
		_idle_time += delta
	_last_mouse = mouse

	var base := SlimeFace.Mood.IDLE
	if _hovering:
		base = SlimeFace.Mood.EXCITED
	elif _idle_time > SLEEP_AFTER:
		base = SlimeFace.Mood.SLEEPY
	_face.update(delta, base, ((mouse - global_position) / 260.0).limit_length(1.0))


## Cambia de nivel. Con refresh = true pide algo nuevo de inmediato.
func set_stage(value: int, refresh: bool = false) -> void:
	stage = value
	if refresh:
		new_request()


## Main lo llama cuando el bocado que viene sube de nivel: el slime celebra con la cara grande.
func celebrate() -> void:
	_cheer = true


func new_request() -> void:
	_idle_time = 0.0
	_face.glance(Vector2(-1.0, -0.85), 1.2)  # mira hacia el globo (arriba a la izquierda)
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

	_cheer = false
	shape.get_eaten(absorb_point.global_position)
	if mask != 0:  # una figura sin pintar no cambia el color del slime
		_change_color(GameData.mask_to_color(mask))
	food_accepted.emit(type, mask)  # Main puede llamar a celebrate() desde aquí

	# Cara: mastica y luego se pone feliz (o festeja si se subió de nivel)
	if _cheer:
		_face.play([[SlimeFace.Mood.EATING, 0.45], [SlimeFace.Mood.CHEER, 1.7]])
	else:
		_face.play([[SlimeFace.Mood.EATING, 0.45], [SlimeFace.Mood.HAPPY, 1.0]])
	_cheer = false

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
	_idle_time = 0.0
	_face.play([[SlimeFace.Mood.SAD, 1.1]])
	food_rejected.emit(shape.shape_type, shape.color_mask)
	var t := create_tween()
	t.tween_property(self, "_squish", 0.8, 0.08)
	t.tween_property(self, "_squish", -0.5, 0.08)
	t.tween_property(self, "_squish", 0.0, 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _busy = false)


func _change_color(to: Color) -> void:
	var from := _current_color
	_current_color = to
	create_tween().tween_method(_set_body_color, from, to, 0.5)


func _set_body_color(c: Color) -> void:
	(body.material as ShaderMaterial).set_shader_parameter("body_color", c)
