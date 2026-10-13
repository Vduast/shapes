extends Node2D

@onready var rect: ColorRect = $Rect


func play(color: Color) -> void:
	var mat := rect.material.duplicate() as ShaderMaterial
	rect.material = mat
	mat.set_shader_parameter("burst_color", color.lightened(0.15))
	var t := create_tween()
	t.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.6)
	t.tween_callback(queue_free)
