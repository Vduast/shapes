class_name Eraser
extends Area2D
## Borrador arrastrable. Se agarra, se lleva encima de una figura suelta y al soltarlo la
## borra con un "puf". Después regresa solo a su lugar. (Igual que los botes de pintura.)

## Distancia máxima (px) entre el borrador y el centro de la figura para poder borrarla
const REACH := 95.0

var home_position := Vector2.ZERO

var _dragging := false
var _drag_age := 0.0
var _returning := false
var _tween: Tween
var _highlighted = null
var _hovered := false
var _hover := 0.0
var _prev_pos := Vector2.ZERO
var _sway := 0.0
var _sway_vel := 0.0
var _lift := 0.0
var _lift_vel := 0.0
var _scrub := 0.0   # 0..1: qué tanto "restriega" (está encima de una figura)

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	visual.material = visual.material.duplicate()
	visual.pivot_offset = visual.size / 2.0
	home_position = position
	_prev_pos = global_position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Main lo llama al acomodar la pantalla (el lugar de reposo depende del ancho visible).
func set_home(pos: Vector2) -> void:
	home_position = pos
	if not _dragging and not _returning:
		position = pos


func is_dragging() -> bool:
	return _dragging


func _on_mouse_entered() -> void:
	_hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _exit_tree() -> void:
	if _hovered:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and not _dragging:
		_start_drag()


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()


func _start_drag() -> void:
	_dragging = true
	_drag_age = 0.0
	_returning = false
	z_index = 20
	_lift_vel += 3.0   # saltito al agarrarlo
	Sound.play("pick", 0.9)
	if _tween and _tween.is_valid():
		_tween.kill()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var dt := minf(delta, 0.033)

	var target = null
	if _dragging:
		# Seguro para el celular: si el sistema cancela el toque, se suelta solo
		_drag_age += delta
		if _drag_age > 0.2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_end_drag()
		else:
			target = _find_target()
			var goal := get_global_mouse_position()
			if target:
				goal = goal.lerp(target.global_position, 0.3)   # efecto imán
			# No sale de la pantalla visible
			var rect := (get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(-50.0)
			goal = goal.clamp(rect.position, rect.end)
			global_position = global_position.lerp(goal, 1.0 - exp(-30.0 * delta))

			if target != _highlighted:
				_set_highlight(_highlighted, false)
				_highlighted = target
				_set_highlight(_highlighted, true)

	var vel := (global_position - _prev_pos) / delta
	_prev_pos = global_position

	_hover = lerpf(_hover, 1.0 if (_hovered and not _dragging) else 0.0, 1.0 - exp(-14.0 * delta))
	_scrub = lerpf(_scrub, 1.0 if target != null else 0.0, 1.0 - exp(-12.0 * delta))
	(visual.material as ShaderMaterial).set_shader_parameter("hover", maxf(_hover, _scrub))

	# Inclinación y "crecer" con resortes (solo el dibujo)
	var sway_target := clampf(vel.x * 0.0012, -0.5, 0.5)
	_sway_vel += ((sway_target - _sway) * 170.0 - _sway_vel * 7.0) * dt
	_sway += _sway_vel * dt

	var lift_target := 0.2 if _dragging else 0.1 * _hover
	_lift_vel += ((lift_target - _lift) * 220.0 - _lift_vel * 12.0) * dt
	_lift += _lift_vel * dt

	# Encima de una figura "restriega" de un lado a otro
	var rub := sin(Time.get_ticks_msec() * 0.03) * 0.16 * _scrub
	visual.rotation = _sway + rub
	visual.scale = Vector2.ONE * (1.0 + _lift)


## La figura suelta más cercana dentro del alcance (las de la bandeja no se borran).
func _find_target():
	var best := REACH
	var target = null
	for area in get_overlapping_areas():
		if area.has_method("can_paint") and area.can_paint():
			var dist: float = area.global_position.distance_to(global_position)
			if dist < best:
				best = dist
				target = area
	return target


func _set_highlight(shape, value: bool) -> void:
	if shape != null and is_instance_valid(shape):
		shape.set_highlight(value)


func _end_drag() -> void:
	_dragging = false
	z_index = 0
	var target = _find_target()
	_set_highlight(_highlighted, false)
	_highlighted = null
	if target:
		target.vanish()
		_lift_vel -= 3.0
		_sway_vel += 8.0

	# Regresa a su lugar
	_returning = true
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", home_position, 0.3)
	_tween.tween_callback(func(): _returning = false)
