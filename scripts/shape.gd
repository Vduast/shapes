class_name Shape
extends Area2D

signal left_tray(shape: Shape)

const BURST := preload("res://scenes/paint_burst.tscn")
const WARNING_TIME := 6.0

@export_enum("Círculo", "Cuadrado", "Triángulo", "Estrella", "Corazón") var shape_type: int = 0
## Segundos que dura suelta en pantalla antes de desaparecer (0 = nunca)
@export var lifetime := 45.0
## Qué tan gelatinosa se siente al moverla (0 = rígida, 1 = normal, 2 = exagerada)
@export var jelly := 1.0

var color_mask: int = 0
var is_template := true  # true mientras está en la bandeja (no se puede pintar)

var _shown_color := Color.WHITE
var _idle := 0.0
var _dragging := false
var _moved := false
var _vanishing := false
var _grab_offset := Vector2.ZERO
var _press_mouse := Vector2.ZERO
var _tween: Tween
var _wave_tween: Tween

# --- Efecto gelatina (resortes) ---
var _prev_pos := Vector2.ZERO
var _sway := 0.0          # inclinación
var _sway_vel := 0.0
var _stretch := 0.0       # estiramiento horizontal(+) / vertical(-)
var _stretch_vel := 0.0
var _lift := 0.0          # crecimiento al levantarla
var _lift_vel := 0.0
var _tremor := 0.0        # temblor de posición al soltar
var _tremor_t := 0.0
var _visual_base := Vector2.ZERO

# --- Hover (solo plantillas de la bandeja) ---
var _hovered := false
var _hover := 0.0

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	visual.material = visual.material.duplicate()
	visual.pivot_offset = visual.size / 2.0
	_visual_base = visual.position
	_prev_pos = global_position
	_refresh()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(type: int, mask: int = 0) -> void:
	shape_type = type
	color_mask = mask
	if is_node_ready():
		_refresh()


func _on_mouse_entered() -> void:
	_hovered = true
	if is_template and not _vanishing:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _exit_tree() -> void:
	if _hovered:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func is_dragging() -> bool:
	return _dragging


func can_paint() -> bool:
	return not is_template and not _vanishing


func set_highlight(value: bool) -> void:
	(visual.material as ShaderMaterial).set_shader_parameter("selected", 1.0 if value else 0.0)


func _refresh() -> void:
	_shown_color = GameData.mask_to_color(color_mask)
	var mat := visual.material as ShaderMaterial
	mat.set_shader_parameter("shape_type", shape_type)
	mat.set_shader_parameter("fill_color", _shown_color)
	mat.set_shader_parameter("old_color", _shown_color)
	mat.set_shader_parameter("wave", 1.0)


## brush_mask = 0 limpia; si no, se mezcla con el color actual
func paint(brush_mask: int) -> void:
	var old := _shown_color
	if brush_mask == 0:
		color_mask = 0
	else:
		color_mask |= brush_mask
	_shown_color = GameData.mask_to_color(color_mask)
	_touch()

	var mat := visual.material as ShaderMaterial
	mat.set_shader_parameter("old_color", old)
	mat.set_shader_parameter("fill_color", _shown_color)
	if _wave_tween and _wave_tween.is_valid():
		_wave_tween.kill()
	_wave_tween = create_tween()
	_wave_tween.tween_method(func(v: float): mat.set_shader_parameter("wave", v), 0.0, 1.0, 0.4)

	_spawn_burst(_shown_color)
	_kill_tween()
	scale = Vector2.ONE * 1.25
	rotation = 0.3 * (1.0 if randf() < 0.5 else -1.0)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", 0.0, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_burst(color: Color) -> void:
	var b = BURST.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.play(color)


func _touch() -> void:
	_idle = 0.0
	modulate.a = 1.0


# ---------- Arrastre ----------
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and not _dragging and not _vanishing:
		_start_drag()


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()


func _process(delta: float) -> void:
	_update_jelly(delta)

	if _vanishing:
		return

	if _dragging:
		var m := get_global_mouse_position()
		if not _moved and m.distance_to(_press_mouse) > 8.0:
			_moved = true
			if is_template:
				is_template = false
				left_tray.emit(self)  # la bandeja repone una figura nueva
		if _moved:
			var rect := get_viewport_rect().grow(-50.0)
			var goal := (m + _grab_offset).clamp(rect.position, rect.end)
			# Sigue al mouse con un poquito de retraso (no es rígido)
			global_position = global_position.lerp(goal, 1.0 - exp(-24.0 * delta))
		return

	# Tiempo de vida de las figuras sueltas
	if not is_template and lifetime > 0.0:
		_idle += delta
		var left := lifetime - _idle
		if left <= 0.0:
			vanish()
		elif left <= WARNING_TIME:
			modulate.a = 0.5 + 0.5 * abs(sin(_idle * 5.0))


## Resortes: inclinación, estiramiento, "levantada" y temblor. Solo afectan al dibujo.
func _update_jelly(delta: float) -> void:
	if delta <= 0.0:
		return
	var dt := minf(delta, 0.033)
	var vel := (global_position - _prev_pos) / delta
	_prev_pos = global_position

	# Hover: solo plantillas de la bandeja, y no mientras se arrastran
	var hover_target := 1.0 if (_hovered and is_template and not _dragging) else 0.0
	_hover = lerpf(_hover, hover_target, 1.0 - exp(-14.0 * delta))
	(visual.material as ShaderMaterial).set_shader_parameter("hover", _hover)

	var sway_target := clampf(vel.x * 0.0009, -0.45, 0.45) * jelly
	var stretch_target := clampf((absf(vel.x) - absf(vel.y)) * 0.00025, -0.2, 0.2) * jelly
	var lift_target := 0.12 if _dragging else 0.10 * _hover

	# Resortes subamortiguados: por eso "tiemblan" antes de quedarse quietos
	_sway_vel += ((sway_target - _sway) * 170.0 - _sway_vel * 7.0) * dt
	_sway += _sway_vel * dt

	_stretch_vel += ((stretch_target - _stretch) * 190.0 - _stretch_vel * 8.0) * dt
	_stretch += _stretch_vel * dt

	_lift_vel += ((lift_target - _lift) * 220.0 - _lift_vel * 12.0) * dt
	_lift += _lift_vel * dt

	# Meneo suave y saltito vertical mientras el cursor está encima
	visual.rotation = _sway + 0.06 * _hover * sin(Time.get_ticks_msec() * 0.009)
	visual.scale = Vector2((1.0 + _lift) * (1.0 + _stretch), (1.0 + _lift) * (1.0 - _stretch))

	var bob := Vector2(0.0, -8.0 * _hover)
	if _tremor > 0.05:
		_tremor_t += delta
		_tremor *= exp(-7.0 * delta)
		visual.position = _visual_base + bob \
			+ Vector2(sin(_tremor_t * 70.0), cos(_tremor_t * 58.0)) * _tremor
	else:
		visual.position = _visual_base + bob


func _start_drag() -> void:
	_kill_tween()
	_touch()
	_dragging = true
	_moved = false
	_press_mouse = get_global_mouse_position()
	_grab_offset = global_position - _press_mouse
	z_index = 10
	_lift_vel += 2.5 * jelly  # saltito al agarrarla
	get_parent().move_child.call_deferred(self, -1)


func _end_drag() -> void:
	_dragging = false
	z_index = 0
	if not _moved or _vanishing:
		return
	_touch()

	# Golpecito al soltarla: se aplasta, se mece y tiembla hasta quedarse quieta
	_sway_vel += randf_range(-7.0, 7.0) * jelly
	_stretch_vel += 4.0 * jelly
	_lift_vel -= 2.0 * jelly
	_tremor = 4.0 * jelly
	_tremor_t = 0.0

	for area in get_overlapping_areas():
		if area.has_method("try_eat"):
			if area.try_eat(self):
				return
			_push_away(area.global_position)
			return
		if area.has_method("erase_shape"):
			area.erase_shape(self)
			return


func _push_away(center: Vector2) -> void:
	var dir := (global_position - center).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var rect := get_viewport_rect().grow(-50.0)
	var target := (center + dir * 240.0).clamp(rect.position, rect.end)
	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "global_position", target, 0.3)


## Desaparece con un "puf" (borrador o fin del tiempo de vida)
func vanish() -> void:
	if _vanishing:
		return
	_vanishing = true
	_dragging = false
	input_pickable = false
	modulate.a = 1.0
	_kill_tween()
	_spawn_burst(_shown_color)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "rotation", rotation + PI, 0.35)
	_tween.chain().tween_callback(queue_free)


## Lo llama el slime cuando acepta la figura.
func get_eaten(target: Vector2) -> void:
	_vanishing = true
	_kill_tween()
	input_pickable = false
	modulate.a = 1.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position", target, 0.25)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	_tween.chain().tween_callback(queue_free)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
