class_name ConfirmDialog
extends Control
## Diálogo de confirmación con el mismo estilo del menú (panel crema + botones CreamButton).
## Cubre toda la pantalla con un fondo oscuro que bloquea los clics hacia el juego.
## Se abre con ask(); emite `confirmed` (botón "Sí") o `cancelled` ("No", Esc o clic fuera).

signal confirmed
signal cancelled

@onready var panel: ColorRect = $Panel
@onready var title_label: Label = $Panel/Title
@onready var message_label: Label = $Panel/Message
@onready var yes_button: CreamButton = $Panel/Buttons/YesButton
@onready var no_button: CreamButton = $Panel/Buttons/NoButton

var _tween: Tween


func _ready() -> void:
	visible = false
	(panel.material as ShaderMaterial).set_shader_parameter("rect_size", panel.size)
	panel.pivot_offset = panel.size / 2.0
	yes_button.pressed.connect(_answer.bind(true))
	no_button.pressed.connect(_answer.bind(false))


func is_open() -> bool:
	return visible


## Muestra el diálogo. Los textos vacíos dejan los que trae la escena.
func ask(title: String = "", message: String = "", yes_text: String = "", no_text: String = "") -> void:
	if visible:
		return
	if title != "":
		title_label.text = title
	if message != "":
		message_label.text = message
	if yes_text != "":
		yes_button.text = yes_text
	if no_text != "":
		no_button.text = no_text

	visible = true
	modulate.a = 0.0
	panel.scale = Vector2.ONE * 0.7
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	_tween.tween_property(panel, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Clic en el fondo oscuro (fuera del panel) = cancelar
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_answer(false)


## Esc = cancelar. Se atiende antes que el Esc de Main, así que no se encadenan.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(accepted: bool) -> void:
	if not visible:
		return
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	_tween.tween_property(panel, "scale", Vector2.ONE * 0.85, 0.12)
	_tween.chain().tween_callback(func(): visible = false)
	if accepted:
		confirmed.emit()
	else:
		cancelled.emit()


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
