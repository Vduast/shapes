extends Node2D
## Slime del menú principal: respira, cambia de color sin parar, te sigue con la mirada y
## reacciona al ratón (se emociona cerca, se sorprende y luego se alegra al tocarlo).
## Reutiliza monster.gdshader (el mismo slime del juego) y SlimeFace para la cara.

signal poked

const BURST := preload("res://scenes/paint_burst.tscn")
const MASKS := [1, 2, 4, 3, 6, 5]  # rojo, amarillo, azul, naranja, verde, morado

## Cada cuántos segundos empieza un cambio de color
@export var change_interval := 1.8
## Cuánto dura la transición entre dos colores
@export var change_duration := 0.9
## Radio (en píxeles, sin contar la escala) donde el ratón lo emociona o lo "toca"
@export var click_radius := 150.0

var _color := Color.WHITE
var _last_mask := -1
var _timer := 0.0
var _excite := 0.0
var _hover := 0.0
var _squish := 0.0
var _color_tween: Tween
var _poke_tween: Tween
var _mat: ShaderMaterial
var _face: SlimeFace

@onready var body: ColorRect = $Body


func _ready() -> void:
	_mat = (body.material as ShaderMaterial).duplicate()
	body.material = _mat
	_face = SlimeFace.new(_mat)
	_set_color(GameData.mask_to_color(_pick_mask()))


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= change_interval:
		_timer = 0.0
		_change_color(GameData.mask_to_color(_pick_mask()), change_duration)

	# Se emociona cuando el ratón está cerca
	var near := _is_near_mouse()
	_hover = lerpf(_hover, 1.0 if near else 0.0, 1.0 - exp(-10.0 * delta))
	_mat.set_shader_parameter("excite", maxf(_excite, _hover * 0.6))
	_mat.set_shader_parameter("squish", _squish)

	# Cara: emocionado con el ratón cerca, tranquilo si no; siempre mira al ratón
	var look := ((get_global_mouse_position() - global_position) / (300.0 * maxf(scale.x, 0.01))).limit_length(1.0)
	_face.update(delta, SlimeFace.Mood.EXCITED if near else SlimeFace.Mood.IDLE, look)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_near_mouse():
			poke()


## Lo toca el jugador: se aplasta, cambia de color de golpe y suelta un estallido.
func poke() -> void:
	var to := GameData.mask_to_color(_pick_mask())
	_timer = 0.0
	_change_color(to, 0.25)

	var b = BURST.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.scale = Vector2.ONE * 1.8
	b.play(to)

	if _poke_tween:
		_poke_tween.kill()
	_poke_tween = create_tween()
	_poke_tween.tween_property(self, "_squish", 1.0, 0.10) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_poke_tween.tween_property(self, "_squish", -0.6, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_poke_tween.tween_property(self, "_squish", 0.0, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_excite = 1.0
	create_tween().tween_property(self, "_excite", 0.0, 0.7)
	_face.play([[SlimeFace.Mood.SURPRISED, 0.35], [SlimeFace.Mood.HAPPY, 1.1]])
	poked.emit()


func _is_near_mouse() -> bool:
	return global_position.distance_to(get_global_mouse_position()) < click_radius * scale.x


## Elige un color al azar distinto del anterior.
func _pick_mask() -> int:
	var m: int = MASKS[randi() % MASKS.size()]
	while m == _last_mask:
		m = MASKS[randi() % MASKS.size()]
	_last_mask = m
	return m


func _change_color(to: Color, duration: float) -> void:
	if _color_tween:
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.tween_method(_set_color, _color, to, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_color(c: Color) -> void:
	_color = c
	_mat.set_shader_parameter("body_color", c)
