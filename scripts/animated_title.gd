class_name AnimatedTitle
extends Control
## Título con una letra por Label. Cada letra:
##  - flota con una onda continua,
##  - se inclina y "respira" (escala) con su propio desfase,
##  - cada `jump_interval` segundos todo el título hace una ola de saltos
##    con aplastamiento y estiramiento.
## El color de cada letra lo cambia title_letter.gdshader.

const LETTER_SHADER := preload("res://shaders/title_letter.gdshader")

@export var text := "SHAPES"
@export var font_size := 96
@export var letter_spacing := 4.0
@export var outline_size := 18
@export var outline_color := Color(0.07, 0.12, 0.38)
@export var jump_interval := 3.6

var _items: Array = []  # Label por letra; null por cada espacio
var _t := 0.0
var _last_jump := 0.0


func _ready() -> void:
	_build()
	resized.connect(_layout)


## Dispara ya la ola de saltos (por ejemplo, al tocar al slime).
func jump() -> void:
	_last_jump = _t


func _build() -> void:
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == " ":
			_items.append(null)
			continue
		var l := Label.new()
		l.text = ch
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", outline_color)
		l.add_theme_constant_override("outline_size", outline_size)
		var m := ShaderMaterial.new()
		m.shader = LETTER_SHADER
		m.set_shader_parameter("offset", float(i) * 0.17)
		l.material = m
		add_child(l)
		l.size = l.get_combined_minimum_size()
		l.pivot_offset = l.size / 2.0
		_items.append(l)
	_layout()


## Centra las letras horizontalmente dentro del control.
func _layout() -> void:
	var gap := font_size * 0.32
	var total := 0.0
	for it in _items:
		total += (gap if it == null else it.size.x) + letter_spacing
	total -= letter_spacing
	var x := (size.x - total) * 0.5
	for it in _items:
		if it == null:
			x += gap + letter_spacing
			continue
		it.position.x = x
		x += it.size.x + letter_spacing


func _process(delta: float) -> void:
	_t += delta
	var c := _t - _last_jump
	if c > jump_interval:
		_last_jump = _t
		c = 0.0

	var k := 0
	for it in _items:
		if it == null:
			continue
		var i := float(k)
		k += 1

		var wave := sin(_t * 2.6 - i * 0.7)
		# Ola de saltos: cada letra salta un poquito después de la anterior
		var j := clampf((c - i * 0.11) / 0.55, 0.0, 1.0)
		var hop := sin(j * PI) if (j > 0.0 and j < 1.0) else 0.0

		it.position.y = wave * 8.0 - hop * 38.0
		it.rotation = sin(_t * 1.9 + i * 1.1) * 0.09 + hop * 0.18 * sin(i * 2.0 + 1.0)
		var breathe := 1.0 + 0.06 * sin(_t * 3.4 + i * 0.9)
		it.scale = Vector2(breathe * (1.0 - 0.10 * hop), breathe * (1.0 + 0.16 * hop))
