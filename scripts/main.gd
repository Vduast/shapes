extends Node2D

const BURST := preload("res://scenes/paint_burst.tscn")

## Nivel con el que empieza (0 = primero; el tope lo marca GameData.STAGES). Útil para probar.
@export var start_stage := 0

@onready var monster = $Monster
@onready var palette = $Palette
@onready var hud = $HUD
@onready var tray = $ShapeTray

var stage := 0
var progress := 0


func _ready() -> void:
	randomize()
	var vp := get_viewport()
	vp.physics_object_picking_sort = true
	vp.physics_object_picking_first_only = true

	monster.food_accepted.connect(_on_food_accepted)

	stage = clampi(start_stage, 0, GameData.STAGES.size() - 1)
	_apply_stage(false)


## Esc pide volver al menú principal (el HUD muestra la confirmación; si ya está abierta,
## es ella quien atiende el Esc para cancelar)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hud.request_exit()


func _apply_stage(celebrate: bool) -> void:
	var cfg: Dictionary = GameData.STAGES[stage]
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
	progress += 1
	var goal: int = GameData.STAGES[stage]["goal"]
	if goal > 0 and progress >= goal and stage < GameData.STAGES.size() - 1:
		stage += 1
		progress = 0
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
