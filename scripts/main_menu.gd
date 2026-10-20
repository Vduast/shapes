extends Node2D
## Menú principal: panel semitransparente a la izquierda (título animado + botones)
## y el slime cambiando de color a la derecha, rodeado de figuras que flotan.

const GAME_SCENE := "res://scenes/main.tscn"
const SHAPE_SHADER := preload("res://shaders/shape.gdshader")
const SLIME_SCALE := 1.35

## Figuras decorativas: tipo (0 círculo, 1 cuadrado, 2 triángulo, 3 estrella, 4 corazón),
## máscara de color (ver GameData), posición y tamaño.
const DECOR := [
	{"type": 0, "mask": 4, "pos": Vector2(700, 130), "size": 84.0},
	{"type": 2, "mask": 6, "pos": Vector2(885, 78), "size": 92.0},
	{"type": 3, "mask": 2, "pos": Vector2(1075, 125), "size": 104.0},
	{"type": 4, "mask": 1, "pos": Vector2(1195, 300), "size": 88.0},
	{"type": 1, "mask": 5, "pos": Vector2(640, 585), "size": 80.0},
	{"type": 0, "mask": 3, "pos": Vector2(1165, 585), "size": 76.0},
]

var _t := 0.0
var _busy := false
var _decor_nodes: Array[ColorRect] = []
var _decor_base: Array[Vector2] = []

@onready var panel: ColorRect = $Panel
@onready var title = $Panel/Title
@onready var subtitle: Label = $Panel/Subtitle
@onready var buttons: Control = $Panel/Buttons
@onready var help: Control = $Panel/Help
@onready var slime = $Slime
@onready var decor: Node2D = $Decor


func _ready() -> void:
	randomize()
	(panel.material as ShaderMaterial).set_shader_parameter("rect_size", panel.size)
	_build_decor()

	$Panel/Buttons/PlayButton.pressed.connect(_on_play)
	$Panel/Buttons/HelpButton.pressed.connect(_show_help.bind(true))
	$Panel/Buttons/QuitButton.pressed.connect(get_tree().quit)
	$Panel/Help/BackButton.pressed.connect(_show_help.bind(false))
	slime.poked.connect(title.jump)
	_show_help(false)

	# Entrada: el panel se desliza desde la izquierda y el slime "salta" a escena
	var final_pos := panel.position
	panel.position = final_pos + Vector2(-620.0, 0.0)
	create_tween().tween_property(panel, "position", final_pos, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slime.scale = Vector2.ZERO
	create_tween().tween_property(slime, "scale", Vector2.ONE * SLIME_SCALE, 0.8) \
		.set_delay(0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	for i in _decor_nodes.size():
		var n := _decor_nodes[i]
		var ph := float(i) * 1.7
		n.position = _decor_base[i] + Vector2(sin(_t * 0.9 + ph) * 8.0, sin(_t * 1.3 + ph) * 14.0)
		n.rotation = sin(_t * 0.7 + ph) * 0.35
		n.scale = Vector2.ONE * (1.0 + 0.05 * sin(_t * 2.0 + ph))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and help.visible:
		_show_help(false)


func _build_decor() -> void:
	for d in DECOR:
		var sz: float = d["size"]
		var r := ColorRect.new()
		r.size = Vector2(sz, sz)
		r.pivot_offset = r.size / 2.0
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = SHAPE_SHADER
		var color := GameData.mask_to_color(d["mask"])
		m.set_shader_parameter("shape_type", d["type"])
		m.set_shader_parameter("fill_color", color)
		m.set_shader_parameter("old_color", color)
		m.set_shader_parameter("wave", 1.0)
		r.material = m
		var base: Vector2 = d["pos"] - r.size / 2.0
		r.position = base
		decor.add_child(r)
		_decor_nodes.append(r)
		_decor_base.append(base)


## Alterna entre los botones del menú y las instrucciones.
func _show_help(value: bool) -> void:
	help.visible = value
	buttons.visible = not value
	subtitle.visible = not value


func _on_play() -> void:
	if _busy:
		return
	_busy = true
	slime.poke()
	title.jump()
	create_tween().tween_property(panel, "position:x", panel.position.x - 640.0, 0.45) \
		.set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file(GAME_SCENE)
