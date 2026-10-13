class_name ShapeTray
extends Node2D

@export var shape_scene: PackedScene
@export var spacing := 170.0
## Segundos que dura una figura suelta antes de desaparecer (0 = nunca)
@export var shape_lifetime := 45.0

var _allowed: Array = []
var _templates := {}  # tipo -> figura plantilla que está en la bandeja


## Define qué figuras ofrece la bandeja. Quita las que sobran, crea las que
## faltan y reacomoda todas centradas.
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
