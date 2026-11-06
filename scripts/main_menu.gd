extends Node2D
## Menú principal: panel semitransparente a la izquierda (título animado + botones)
## y el slime cambiando de color a la derecha, rodeado de figuras que flotan.

const GAME_SCENE := "res://scenes/main.tscn"
const LEVELS_SCENE := "res://scenes/level_select.tscn"
const SHAPE_SHADER := preload("res://shaders/shape.gdshader")
const ERASER_SHADER := preload("res://shaders/eraser.gdshader")
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
@onready var buttons: Control = $Panel/Buttons
@onready var help: Control = $Panel/Help
@onready var play_button: CreamButton = $Panel/Buttons/PlayButton
@onready var sound_button: CreamButton = $Panel/SoundButton
@onready var confirm: ConfirmDialog = $ConfirmLayer/ConfirmDialog
@onready var slime = $Slime
@onready var decor: Node2D = $Decor


func _ready() -> void:
	_fade_in_from_splash()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	randomize()
	(panel.material as ShaderMaterial).set_shader_parameter("rect_size", panel.size)
	_build_decor()

	play_button.pressed.connect(_on_play)
	$Panel/Buttons/LevelsButton.pressed.connect(_on_levels)
	sound_button.pressed.connect(_on_sound_toggle)
	$Panel/Buttons/HelpButton.pressed.connect(_show_help.bind(true))
	$Panel/Buttons/QuitButton.pressed.connect(_ask_quit)
	confirm.confirmed.connect(get_tree().quit)
	$Panel/Help/BackButton.pressed.connect(_show_help.bind(false))
	slime.poked.connect(title.jump)
	_build_help()
	_show_help(false)

	# La música del menú empieza aquí
	_refresh_sound_label()
	Sound.play_music("menu")

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
	if event.is_action_pressed("ui_cancel"):
		if help.visible:
			_show_help(false)
		elif not confirm.is_open():
			_ask_quit()


## Pregunta antes de salir: icono de apagado, palomita = salir, tache = seguir jugando.
func _ask_quit() -> void:
	if _busy:
		return
	confirm.ask(Icons.QUIT)


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


## "Cómo jugar" en dibujos (sin texto): tres filas  [cosa] -> [resultado].
##  1) figura -> slime (se la das de comer)   2) bote de pintura -> figura pintada
##  3) borrador -> figura tachada (se borra)
func _build_help() -> void:
	var pictos: Control = $Panel/Help/Pictos
	var centers := [Vector2(76, 50), Vector2(198, 50), Vector2(320, 50)]
	for row in 3:
		var y := 6.0 + row * 92.0
		var left: Control
		var right: Control
		match row:
			0:
				left = _help_shape(3, 2, 78.0)
				right = Icons.make(Icons.SLIME, 84.0)
			1:
				left = _help_shape(0, 1, 78.0)
				right = _help_shape(2, 1, 78.0)
			_:
				left = _help_eraser(84.0)
				right = _help_shape(4, 5, 78.0)
				var cross := Icons.make(Icons.CROSS, 56.0)
				cross.position = (right.size - cross.size) / 2.0
				right.add_child(cross)
		var arrow := Icons.make(Icons.ARROW, 64.0)
		for pair in [[left, centers[0]], [arrow, centers[1]], [right, centers[2]]]:
			var c: Control = pair[0]
			c.position = Vector2(pair[1].x, y + pair[1].y) - c.size / 2.0
			pictos.add_child(c)


func _help_shape(type: int, mask: int, size: float) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SHAPE_SHADER
	var color := GameData.mask_to_color(mask)
	m.set_shader_parameter("shape_type", type)
	m.set_shader_parameter("fill_color", color)
	m.set_shader_parameter("old_color", color)
	m.set_shader_parameter("wave", 1.0)
	r.material = m
	return r


func _help_eraser(size: float) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = ERASER_SHADER
	r.material = m
	return r


## Alterna entre los botones del menú y las instrucciones.
func _show_help(value: bool) -> void:
	help.visible = value
	buttons.visible = not value
	sound_button.visible = not value


## Botón "Atrás" de Android: cierra "Cómo jugar" o, desde el menú, sale del juego
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if confirm.is_open():
			confirm.cancel()
		elif help.visible:
			_show_help(false)
		else:
			_ask_quit()


func _refresh_sound_label() -> void:
	sound_button.icon = Icons.SOUND_OFF if Sound.is_muted() else Icons.SOUND_ON


func _on_sound_toggle() -> void:
	Sound.toggle_mute()
	_refresh_sound_label()


## Abre el menú de niveles
func _on_levels() -> void:
	if _busy:
		return
	_busy = true
	create_tween().tween_property(panel, "position:x", panel.position.x - 640.0, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file(LEVELS_SCENE)


func _on_play() -> void:
	if _busy:
		return
	_busy = true
	Sound.play("whoosh")
	SaveData.pending_stage = SaveData.unlocked_stage()  # continúa en el nivel más alto alcanzado
	slime.poke()
	title.jump()
	create_tween().tween_property(panel, "position:x", panel.position.x - 640.0, 0.45) \
		.set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file(GAME_SCENE)


## Aleja la cámara si la pantalla es más chica que 1280x720, para que no se recorte el menú.
func _fit_camera() -> void:
	ScreenFit.fit_camera($Camera2D, get_viewport())


## Si venimos de la pantalla de inicio (que termina en negro), el menú se aclara poco a poco.
func _fade_in_from_splash() -> void:
	if not Splash.fade_menu:
		return
	Splash.fade_menu = false
	var layer := CanvasLayer.new()
	layer.layer = 60
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cover)
	add_child(layer)
	var t := create_tween()
	t.tween_property(cover, "color:a", 0.0, 0.45)
	t.tween_callback(layer.queue_free)
