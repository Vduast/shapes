class_name ShapeTray
extends Node2D
## Bandeja con las figuras plantilla del nivel actual. El tablero (Board) lo dibuja
## tray.gdshader: crece o se encoge según cuántas figuras ofrezca el nivel y deja un
## hueco (cuna) debajo de cada figura.

@export var shape_scene: PackedScene
## Separación entre figuras (px). tray.gdshader usa el mismo valor para los huecos.
@export var spacing := 160.0
## Segundos que dura una figura suelta antes de desaparecer (0 = nunca)
@export var shape_lifetime := 45.0
## Alto visible del tablero (sin contar el margen de la sombra)
@export var board_height := 160.0
## Espacio entre la primera/última figura y el borde del tablero
@export var board_side := 92.0

const BOARD_PAD := 14.0  # debe coincidir con `pad` en tray.gdshader

var _allowed: Array = []
var _templates := {}  # tipo -> figura plantilla que está en la bandeja
var _board_n := 0.0   # cuántas casillas muestra el tablero (float para animarlo)
var _board_tween: Tween

@onready var board: ColorRect = $Board


## Define qué figuras ofrece la bandeja. Quita las que sobran, crea las que
## faltan, reacomoda todas centradas y ajusta el tablero.
func set_allowed_shapes(types: Array, animate: bool = true) -> void:
	_allowed = types.duplicate()
	_allowed.sort()

	for type in _templates.keys():
		if type not in _allowed:
			var s = _templates[type]
			_templates.erase(type)
			if animate:
				s.vanish()
			else:
				s.queue_free()

	for type in _allowed:
		if not _templates.has(type):
			_spawn(type, animate)

	_layout(animate)
	_update_board(animate)


## Posición global de la casilla de un tipo de figura (la usa el tutorial fantasma).
func slot_position(type: int) -> Vector2:
	return to_global(Vector2(_slot_x(type), 0.0))


func _slot_x(type: int) -> float:
	var i := _allowed.find(type)
	return (i - (_allowed.size() - 1) / 2.0) * spacing


func _layout(animate: bool) -> void:
	for type in _templates:
		var s = _templates[type]
		var pos := Vector2(_slot_x(type), 0.0)
		if animate:
			create_tween().tween_property(s, "position", pos, 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			s.position = pos


## Anima el tablero hacia el número de casillas del nivel (misma curva que las figuras).
func _update_board(animate: bool) -> void:
	var target := float(_allowed.size())
	if _board_tween:
		_board_tween.kill()
	if animate:
		_board_tween = create_tween()
		_board_tween.tween_method(_set_board_slots, _board_n, target, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_set_board_slots(target)


func _set_board_slots(n: float) -> void:
	_board_n = n
	var visible_w := maxf(n - 1.0, 0.0) * spacing + board_side * 2.0
	board.size = Vector2(visible_w + BOARD_PAD * 2.0, board_height + BOARD_PAD * 2.0)
	board.position = -board.size / 2.0
	var mat := board.material as ShaderMaterial
	mat.set_shader_parameter("rect_size", board.size)
	mat.set_shader_parameter("slot_count", n)
	mat.set_shader_parameter("slot_spacing", spacing)


func _spawn(type: int, animate: bool = true) -> void:
	var s = shape_scene.instantiate()
	s.position = Vector2(_slot_x(type), 0.0)
	s.lifetime = shape_lifetime
	s.setup(type, 0)
	s.left_tray.connect(_on_shape_left.bind(type))
	add_child(s)
	_templates[type] = s
	if animate:
		s.scale = Vector2.ZERO
		create_tween().tween_property(s, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shape_left(_shape, type: int) -> void:
	_templates.erase(type)
	if type in _allowed:
		_spawn(type)
