extends Node2D
## Paleta de pintura. El tablero de madera (Board) lo dibuja palette_board.gdshader y se
## ajusta solo a donde estén los botes: un hueco por bote y el agujero del pulgar abajo.

const NAVY := Color(0.07, 0.12, 0.38)
const BOARD_PAD := 14.0  # debe coincidir con `pad` en palette_board.gdshader

## Espacio a cada lado de los botes
@export var board_margin_x := 80.0
## Espacio arriba del primer bote
@export var board_margin_top := 70.0
## Espacio debajo del último bote (cabe el rótulo y el agujero del pulgar)
@export var board_margin_bottom := 160.0

@onready var board: ColorRect = $Board


func _ready() -> void:
	# Los rótulos de los botes quedan sobre la madera clara: texto azul oscuro
	for child in get_children():
		var label := child.get_node_or_null("Label") as Label
		if label:
			label.add_theme_color_override("font_color", NAVY)
			label.add_theme_font_size_override("font_size", 20)
	_fit_board()


## Muestra u oculta los botes. Si están ocultos tampoco se pueden agarrar.
func set_enabled(value: bool, animate: bool = true) -> void:
	visible = value
	if value and animate:
		board.pivot_offset = board.size / 2.0
		board.scale = Vector2(0.2, 0.2)
		create_tween().tween_property(board, "scale", Vector2.ONE, 0.45) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif value:
		board.scale = Vector2.ONE

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


## Calcula el rectángulo del tablero y las posiciones de los huecos a partir de los botes.
func _fit_board() -> void:
	var first := Vector2.ZERO
	var last := Vector2.ZERO
	var n := 0
	for child in get_children():
		if child is Area2D:
			if n == 0:
				first = child.position
			last = child.position
			n += 1
	if n == 0:
		return

	var step := (last - first) / float(maxi(n - 1, 1))
	var top_left := Vector2(first.x - board_margin_x - BOARD_PAD, first.y - board_margin_top - BOARD_PAD)
	var bottom_right := Vector2(last.x + board_margin_x + BOARD_PAD, last.y + board_margin_bottom + BOARD_PAD)
	board.position = top_left
	board.size = bottom_right - top_left
	board.pivot_offset = board.size / 2.0

	# El shader trabaja con coordenadas relativas al centro del tablero
	var center := top_left + board.size / 2.0
	var mat := board.material as ShaderMaterial
	mat.set_shader_parameter("rect_size", board.size)
	mat.set_shader_parameter("well_first", first - center)
	mat.set_shader_parameter("well_step", step)
	mat.set_shader_parameter("well_count", n)
	mat.set_shader_parameter("hole_pos", Vector2(last.x, last.y + board_margin_bottom - 52.0) - center)
