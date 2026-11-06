class_name Icons
extends RefCounted
## Iconos de los menús (dibujados por shaders/icon.gdshader). Los números son los del shader.

const SHADER := preload("res://shaders/icon.gdshader")
const NAVY := Color(0.07, 0.12, 0.38)

const PLAY := 0
const LEVELS := 1
const HELP := 2
const QUIT := 3
const SOUND_ON := 4
const SOUND_OFF := 5
const BACK := 6
const HOME := 7
const CHECK := 8
const CROSS := 9
const TRASH := 10
const LOCK := 11
const STAR := 12
const ARROW := 13
const SLIME := 14
const SPARKLE := 15


## Pone (o cambia) el icono de un ColorRect.
static func apply(rect: ColorRect, icon: int, tint: Color = NAVY) -> void:
	var mat := rect.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		rect.material = mat
	mat.set_shader_parameter("icon", icon)
	mat.set_shader_parameter("tint", tint)


## Crea un ColorRect cuadrado con el icono dibujado (no recibe clics).
static func make(icon: int, size: float, tint: Color = NAVY) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(size, size)
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply(r, icon, tint)
	return r
