extends Node2D

const BURST := preload("res://scenes/paint_burst.tscn")

## Nivel con el que empieza (0 = primero; el tope lo marca GameData.STAGES). Útil para probar.
@export var start_stage := 0
## Activa el tutorial fantasma (la mano que enseña cómo cumplir cada petición)
@export var tutorial := true

## Espera (s) antes de lanzar el tutorial tras llegar la primera petición del nivel
const TUTORIAL_FIRST_DELAY := 0.8   # al empezar la partida
const TUTORIAL_STAGE_DELAY := 1.6   # en niveles nuevos: deja ver el letrero y el confeti
## Segundos sin que el jugador haga clic para repetir la ayuda
const HELP_AFTER := 10.0

@onready var monster = $Monster
@onready var palette = $Palette
@onready var hud = $HUD
@onready var tray = $ShapeTray
@onready var ghost: TutorialGhost = $TutorialGhost

var stage := 0
var progress := 0

const DESIGN_WIDTH := 1280.0   # ancho para el que se diseñó la escena

var _palette_x := 0.0           # posición original de la paleta y del borrador
var _eraser_x := 0.0
var _tutorial_pending := false   # el nivel acaba de empezar: falta lanzar su tutorial
var _tutorial_wait := -1.0       # cuenta regresiva para lanzarlo (-1 = ninguna)
var _tutorial_delay := TUTORIAL_FIRST_DELAY
var _help_idle := 0.0


func _ready() -> void:
	randomize()
	var vp := get_viewport()
	vp.physics_object_picking_sort = true
	vp.physics_object_picking_first_only = true

	monster.food_accepted.connect(_on_food_accepted)
	monster.request_changed.connect(_on_request_changed)

	# Nivel de partida: el elegido en el menú (Jugar/Niveles) o, si no, el export start_stage
	var first := SaveData.pending_stage if SaveData.pending_stage >= 0 else start_stage
	SaveData.pending_stage = -1
	stage = clampi(first, 0, GameData.STAGES.size() - 1)

	# Si se continúa el mismo nivel donde se quedó, se recuperan sus aciertos
	progress = SaveData.saved_progress(stage)
	var saved_goal: int = GameData.STAGES[stage]["goal"]
	if saved_goal > 0 and progress >= saved_goal:
		progress = 0

	DisplayServer.screen_set_keep_on(true)  # la pantalla no se apaga mientras se juega
	Sound.play_music("game")
	_palette_x = palette.position.x
	_eraser_x = $Eraser.position.x
	get_viewport().size_changed.connect(_fit_to_screen)
	_fit_to_screen()
	_apply_stage(false)


## Adapta la escena a cualquier proporción de pantalla:
##  - Si el área visible es más chica que 1280x720 (ventana de laptop 16:10, ventana angosta),
##    la cámara se aleja para que no se recorte nada (la paleta y el borrador ya no se cortan).
##  - Si es más ancha que 16:9 (celulares), la paleta y el borrador se pegan a los bordes
##    reales y el resto queda centrado (la cámara está en el centro).
func _fit_to_screen() -> void:
	var cam: Camera2D = $Camera2D
	ScreenFit.fit_camera(cam, get_viewport())
	var vis := ScreenFit.visible_world(cam, get_viewport())
	var extra := maxf(vis.size.x - DESIGN_WIDTH, 0.0)
	var safe := SafeArea.insets(get_viewport())   # margen por muescas y esquinas del celular
	palette.position.x = _palette_x + extra * 0.5 - safe.z
	$Eraser.position.x = _eraser_x - extra * 0.5 + safe.x


func _exit_tree() -> void:
	DisplayServer.screen_set_keep_on(false)


## Botón "Atrás" de Android: igual que Esc (pide volver al menú o cancela el aviso)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		hud.handle_back()


## Cada clic del jugador cancela el tutorial que esté por salir y reinicia el contador de ayuda
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_help_idle = 0.0
		if _tutorial_wait > 0.0:
			_tutorial_wait = -1.0


func _process(delta: float) -> void:
	if not tutorial or hud.is_dialog_open():
		return
	if _tutorial_wait > 0.0:
		_tutorial_wait -= delta
		if _tutorial_wait <= 0.0:
			_tutorial_wait = -1.0
			_play_tutorial()
	elif not ghost.is_playing() and not _tutorial_pending:
		# Ayuda si el jugador se atora: tras HELP_AFTER s sin hacer clic se repite la demostración
		_help_idle += delta
		if _help_idle >= HELP_AFTER:
			_help_idle = 0.0
			_play_tutorial()


## Lanza la mano fantasma con lo que el slime pide ahora (espera si está ocupado o el jugador arrastra)
func _play_tutorial() -> void:
	if monster.is_busy() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_tutorial_wait = 0.4
		return
	ghost.play(monster.wanted_shape, monster.wanted_mask, tray, palette, monster.absorb_point.global_position)


## Primera petición de un nivel nuevo: programa su tutorial
func _on_request_changed(_shape_type: int, _mask: int) -> void:
	if _tutorial_pending:
		_tutorial_pending = false
		_tutorial_wait = _tutorial_delay
		_help_idle = 0.0


## Esc pide volver al menú principal (el HUD muestra la confirmación; si ya está abierta,
## es ella quien atiende el Esc para cancelar)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hud.request_exit()


func _apply_stage(celebrate: bool) -> void:
	var cfg: Dictionary = GameData.STAGES[stage]
	# Tutorial del nivel (antes de set_stage: la primera petición llega ya dentro de esa llamada)
	ghost.stop()
	_tutorial_wait = -1.0
	_tutorial_pending = tutorial and cfg.get("tutorial", true)
	_tutorial_delay = TUTORIAL_STAGE_DELAY if celebrate else TUTORIAL_FIRST_DELAY
	monster.set_stage(stage, not celebrate)  # en un cambio de nivel, la nueva petición llega al terminar de comer
	palette.set_enabled(cfg["palette"], celebrate)
	tray.set_allowed_shapes(cfg["shapes"], celebrate)
	hud.set_hint(cfg["hint"])
	_update_hud()
	if celebrate:
		monster.celebrate()  # cara de fiesta mientras se come el bocado que subió de nivel
		hud.show_banner("¡Nivel %d!  %s" % [stage + 1, cfg["name"]])
		_confetti()


func _update_hud() -> void:
	var goal: int = GameData.STAGES[stage]["goal"]
	hud.set_progress(stage + 1, progress, goal)


func _on_food_accepted(_shape_type: int, _mask: int) -> void:
	ghost.stop()
	_help_idle = 0.0
	progress += 1
	SaveData.save_progress(stage, progress)
	var goal: int = GameData.STAGES[stage]["goal"]
	if goal > 0 and progress >= goal and stage < GameData.STAGES.size() - 1:
		stage += 1
		progress = 0
		SaveData.unlock_stage(stage)  # se guarda el nivel alcanzado
		SaveData.save_progress(stage, 0)
		_apply_stage(true)
	else:
		_update_hud()


## Estallidos de colores alrededor del slime al subir de nivel
func _confetti() -> void:
	var masks := [1, 2, 4, 3, 6, 5]
	for i in masks.size():
		var b = BURST.instantiate()
		add_child(b)
		b.global_position = monster.global_position + Vector2.RIGHT.rotated(TAU * i / masks.size()) * 170.0
		b.scale = Vector2.ONE * 1.3
		b.play(GameData.mask_to_color(masks[i]))
