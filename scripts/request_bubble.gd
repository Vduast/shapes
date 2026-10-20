class_name RequestBubble
extends Node2D
## Globo que muestra la figura + color que pide el monstruo.

@onready var item: ColorRect = $Item


func _ready() -> void:
	item.material = item.material.duplicate()


func show_request(shape_type: int, mask: int) -> void:
	var mat := item.material as ShaderMaterial
	mat.set_shader_parameter("shape_type", shape_type)
	mat.set_shader_parameter("fill_color", GameData.mask_to_color(mask))
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
