extends Area2D

var _hover := 0.0

@onready var visual: ColorRect = $Visual


## Margen extra (px) alrededor del borrador para que sea fácil acertarle con el dedo
const DROP_LEEWAY := 24.0


func _ready() -> void:
	add_to_group("drop_target")
	visual.material = visual.material.duplicate()


func _process(delta: float) -> void:
	var hovering := false
	for a in get_overlapping_areas():
		if a.has_method("is_dragging") and a.is_dragging():
			hovering = true
			break
	_hover = lerpf(_hover, 1.0 if hovering else 0.0, 1.0 - exp(-12.0 * delta))
	(visual.material as ShaderMaterial).set_shader_parameter("hover", _hover)
	scale = Vector2.ONE * (1.0 + 0.15 * _hover)


## Radio dentro del cual acepta figuras: el de su colisión más un margen para los dedos.
func get_drop_radius() -> float:
	return ($Collision.shape as CircleShape2D).radius * scale.x + DROP_LEEWAY


## La llama la figura al soltarse encima.
func erase_shape(shape) -> void:
	shape.vanish()
	var t := create_tween()
	t.tween_property(self, "rotation", 0.3, 0.06)
	t.tween_property(self, "rotation", -0.3, 0.1)
	t.tween_property(self, "rotation", 0.0, 0.2) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
