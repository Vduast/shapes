extends Node2D
## Menú de niveles. Las tarjetas se crean a partir de GameData.STAGES, así que al añadir un
## nivel nuevo aparece aquí solo. Los niveles se desbloquean al llegar a ellos (SaveData);
## los bloqueados se ven apagados y no se pueden abrir.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
const CARD_SCENE := preload("res://scenes/cream_button.tscn")
const CARD_SIZE := Vector2(270, 100)

var _busy := false

@onready var panel: ColorRect = $Panel
@onready var subtitle: Label = $Panel/Subtitle
@onready var grid: GridContainer = $Panel/Scroll/Margin/Grid
@onready var back_button: CreamButton = $Panel/BackButton
@onready var reset_button: CreamButton = $Panel/ResetButton
@onready var confirm: ConfirmDialog = $ConfirmLayer/ConfirmDialog


func _ready() -> void:
	(panel.material as ShaderMaterial).set_shader_parameter("rect_size", panel.size)
	back_button.pressed.connect(_go_back)
	reset_button.pressed.connect(_ask_reset)
	confirm.confirmed.connect(_reset)
	_build_cards()
	Sound.play_music("menu")

	# Entrada: el panel crece desde un poco más chico
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2.ONE * 0.9
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.25)


## Esc vuelve al menú principal (si el diálogo de borrar está abierto, él atiende el Esc)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirm.is_open():
		_go_back()


## Crea una tarjeta por cada nivel de GameData.STAGES
func _build_cards() -> void:
	for c in grid.get_children():
		c.queue_free()

	var unlocked := SaveData.unlocked_stage()
	var total := GameData.STAGES.size()
	subtitle.text = "Nivel alcanzado: %d de %d" % [unlocked + 1, total]

	for i in total:
		var cfg: Dictionary = GameData.STAGES[i]
		var open := SaveData.is_unlocked(i)
		var card: CreamButton = CARD_SCENE.instantiate()
		card.custom_minimum_size = CARD_SIZE
		card.mouse_filter = Control.MOUSE_FILTER_PASS  # deja pasar la rueda del ratón al scroll
		card.font_size = 24
		if open:
			var mark := "★ " if SaveData.is_completed(i) else ""
			card.text = "%sNivel %d\n%s" % [mark, i + 1, cfg["name"]]
		else:
			card.text = "Nivel %d\nBloqueado" % (i + 1)
		card.disabled = not open
		card.emphasized = (i == unlocked)   # el nivel al que llegaste brilla
		card.pressed.connect(_play_stage.bind(i))
		grid.add_child(card)


func _play_stage(index: int) -> void:
	if _busy:
		return
	_busy = true
	SaveData.pending_stage = index
	Sound.play("whoosh")
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE * 0.9, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(panel, "modulate:a", 0.0, 0.3)
	await t.finished
	get_tree().change_scene_to_file(GAME_SCENE)


func _go_back() -> void:
	if _busy:
		return
	_busy = true
	get_tree().change_scene_to_file(MENU_SCENE)


func _ask_reset() -> void:
	confirm.ask("¿Borrar progreso?", "Volverás al nivel 1 y los demás se bloquearán de nuevo.", "Sí, borrar", "Cancelar")


func _reset() -> void:
	SaveData.reset_progress()
	_build_cards()
