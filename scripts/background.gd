class_name Background
extends ColorRect
## Fondo que siempre cubre TODA la pantalla. El juego está diseñado para 1280x720 y con
## `stretch/aspect = expand` los celulares más anchos (p. ej. 20:9) muestran espacio extra a
## los lados. Cada frame este nodo se ajusta al área visible (tomando en cuenta la cámara) y
## le pasa su posición y tamaño al shader para que el dibujo no se estire.

var _mat: ShaderMaterial


func _ready() -> void:
	_mat = (material as ShaderMaterial).duplicate() as ShaderMaterial
	material = _mat
	_fit()


func _process(_delta: float) -> void:
	_fit()


func _fit() -> void:
	# Área visible en coordenadas del mundo (con o sin Camera2D)
	var area: Rect2 = get_canvas_transform().affine_inverse() * get_viewport_rect()
	if area.position.is_equal_approx(position) and area.size.is_equal_approx(size):
		return
	position = area.position
	size = area.size
	_mat.set_shader_parameter("rect_pos", area.position)
	_mat.set_shader_parameter("rect_size", area.size)
