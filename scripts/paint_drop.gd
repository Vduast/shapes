extends Node2D
## Gota de pintura: se lanza, cae, se encoge y se desvanece sola.

var _vel := Vector2.ZERO
var _life := 0.6
var _age := 0.0
var _base_scale := 1.0

@onready var rect: ColorRect = $Rect


func launch(color: Color, size: float, velocity: Vector2, life: float = 0.6) -> void:
	var mat := rect.material.duplicate() as ShaderMaterial
	rect.material = mat
	mat.set_shader_parameter("drop_color", color)
	_base_scale = size / 40.0
	scale = Vector2.ONE * _base_scale
	_vel = velocity
	_life = life


func _process(delta: float) -> void:
	_age += delta
	var t := _age / _life
	if t >= 1.0:
		queue_free()
		return
	_vel.y += 700.0 * delta       # gravedad
	_vel *= exp(-2.5 * delta)     # fricción
	position += _vel * delta
	scale = Vector2.ONE * _base_scale * (1.0 - t * t)
	modulate.a = 1.0 - t
