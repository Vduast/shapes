class_name Splash
extends Node2D
## Pantalla de inicio: aparece el logo de Godot, luego llega el slime y se lo
## "come" con un estallido, salta de felicidad y todo se funde a negro para pasar al menú.
## Un toque / clic / tecla la salta.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const LOGO_PATH := "res://art/godot_logo.svg"
const BURST := preload("res://scenes/paint_burst.tscn")
const GODOT_BLUE := Color("478cbf")
const LOGO_POS := Vector2(640.0, 235.0)
const LOGO_HEIGHT := 200.0
const SLIME_POS := Vector2(640.0, 470.0)
const SLIME_SCALE := Vector2(0.8, 0.8)
## El menú lo lee para hacer su propio fundido de entrada (viene desde negro)
static var fade_menu := false

var _going := false
var _age := 0.0
var _logo_idle := false
var _logo_scale := Vector2.ONE

@onready var slime = $Slime
@onready var logo: Sprite2D = $Logo
@onready var black: ColorRect = $Fade/Black


func _ready() -> void:
	ScreenFit.fit_camera($Camera2D, get_viewport())
	get_viewport().size_changed.connect(func(): ScreenFit.fit_camera($Camera2D, get_viewport()))

	var tex = load(LOGO_PATH)   # load() y no preload(): si falta el archivo, la pantalla sigue
	if tex is Texture2D:
		logo.texture = tex
		_logo_scale = Vector2.ONE * (LOGO_HEIGHT / float(tex.get_height()))
	else:
		logo.visible = false
	logo.position = LOGO_POS + Vector2(0.0, 90.0)
	logo.scale = Vector2.ZERO
	slime.position = SLIME_POS
	slime.scale = Vector2.ZERO
	black.color = Color.BLACK
	_play()


func _process(delta: float) -> void:
	_age += delta
	if _logo_idle:
		logo.position.y = LOGO_POS.y + sin(_age * 3.0) * 6.0
		logo.rotation = sin(_age * 2.0) * 0.05


func _input(event: InputEvent) -> void:
	if _age < 0.3 or _going:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		_go()


func _play() -> void:
	# 1) Se aclara la pantalla y aparece el logo de Godot (arriba, meciéndose)
	create_tween().tween_property(black, "color:a", 0.0, 0.45)
	if logo.visible:
		await get_tree().create_timer(0.3).timeout
		if _going:
			return
		Sound.play("pop")
		var t := create_tween().set_parallel(true)
		t.tween_property(logo, "scale", _logo_scale, 0.55) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(logo, "position", LOGO_POS, 0.55) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await t.finished
		_logo_idle = true
		await get_tree().create_timer(1.0).timeout
		if _going:
			return

	# 2) Llega el slime (salta a escena abajo)
	create_tween().tween_property(slime, "scale", SLIME_SCALE, 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.1).timeout
	if _going:
		return

	# 3) Se come el logo: salta hacia él y el logo se hunde dentro del slime
	if logo.visible:
		_logo_idle = false
		logo.rotation = 0.0
		var bite := create_tween()
		bite.tween_property(slime, "position:y", SLIME_POS.y - 45.0, 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bite.tween_property(slime, "position:y", SLIME_POS.y, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var eat := create_tween().set_parallel(true)
		eat.tween_property(logo, "position", SLIME_POS + Vector2(0.0, -20.0), 0.45) \
			.set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		eat.tween_property(logo, "scale", Vector2.ZERO, 0.45) \
			.set_delay(0.1).set_ease(Tween.EASE_IN)
		await eat.finished
		if _going:
			return
		logo.visible = false
		Sound.play("eat")
		var b = BURST.instantiate()
		add_child(b)
		b.global_position = slime.global_position
		b.scale = Vector2.ONE * 2.0
		b.play(GODOT_BLUE)
		slime.poke()
		await get_tree().create_timer(0.35).timeout
		if _going:
			return

	# 4) Salta de felicidad
	Sound.play("happy")
	var jump := create_tween()
	jump.tween_property(slime, "position:y", SLIME_POS.y - 70.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.tween_property(slime, "position:y", SLIME_POS.y, 0.45) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.1).timeout
	_go()


## Funde a negro y pasa al menú principal.
func _go() -> void:
	if _going:
		return
	_going = true
	fade_menu = true
	var t := create_tween()
	t.tween_property(black, "color:a", 1.0, 0.35)
	await t.finished
	get_tree().change_scene_to_file(MENU_SCENE)
