extends Node2D


## Muestra u oculta los botes. Si están ocultos tampoco se pueden agarrar.
func set_enabled(value: bool, animate: bool = true) -> void:
	visible = value
	var i := 0
	for child in get_children():
		if child is Area2D:
			child.input_pickable = value
			if value and animate:
				child.scale = Vector2.ZERO
				create_tween().tween_property(child, "scale", Vector2.ONE, 0.45) \
					.set_delay(i * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			elif value:
				child.scale = Vector2.ONE
			i += 1
