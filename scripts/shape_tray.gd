class_name ShapeTray
extends Node2D

@export var shape_scene: PackedScene
@export var spacing := 170.0
## Segundos que dura una figura suelta antes de desaparecer (0 = nunca)
@export var shape_lifetime := 45.0


func _ready() -> void:
	for i in GameData.ShapeType.size():
		_spawn(i, false)


func _spawn(type: int, animate: bool = true) -> void:
	var s = shape_scene.instantiate()
	var center := (GameData.ShapeType.size() - 1) / 2.0
	s.position = Vector2((type - center) * spacing, 0.0)
	s.lifetime = shape_lifetime
	s.setup(type, 0)
	s.left_tray.connect(_on_shape_left.bind(type))
	add_child(s)
	if animate:
		s.scale = Vector2.ZERO
		create_tween().tween_property(s, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shape_left(_shape, type: int) -> void:
	_spawn(type)
