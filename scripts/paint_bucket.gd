class_name PaintBucket
extends Area2D

const DROP := preload("res://scenes/paint_drop.tscn")

@export var mask: int = 0  # 1=rojo, 2=amarillo, 4=azul, 0=limpiar
## Distancia (px) entre gota y gota de la estela
@export var trail_spacing := 16.0

var home_position := Vector2.ZERO

var _dragging := false
var _returning := false
var _tween: Tween
var _highlighted = null
var _color := Color.WHITE
var _prev_pos := Vector2.ZERO
var _last_drop_pos := Vector2.ZERO
var _drip_t := 0.0
var _sway := 0.0
var _sway_vel := 0.0
var _lift := 0.0
var _lift_vel := 0.0

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label


func _ready() -> void:
	visual.material = visual.material.duplicate()
	visual.pivot_offset = visual.size / 2.0
	_color = GameData.mask_to_color(mask)
	var mat := visual.material as ShaderMaterial
	mat.set_shader_parameter("shape_type", 0)
	mat.set_shader_parameter("fill_color", _color)
	label.text = "Limpiar" if mask == 0 else GameData.mask_to_name(mask)
	home_position = position
	_prev_pos = global_position


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and not _dragging:
		_dragging = true
		_returning = false
		z_index = 20
		_last_drop_pos = global_position
		_lift_vel += 3.0  # saltito al agarrarlo
		Sound.play("pick", 1.3)
		(visual.material as ShaderMaterial).set_shader_parameter("selected", 1.0)
		if _tween and _tween.is_valid():
			_tween.kill()


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var dt := minf(delta, 0.033)

	if _dragging:
		var target = _find_target()
		var goal := get_global_mouse_position()
		if target:
			goal = goal.lerp(target.global_position, 0.3)  # efecto imán
		global_position = global_position.lerp(goal, 1.0 - exp(-30.0 * delta))

		if target != _highlighted:
			_set_highlight(_highlighted, false)
			_highlighted = target
			_set_highlight(_highlighted, true)

		# Gotita que escurre aunque esté quieto
		_drip_t += delta
		if _drip_t > 0.12:
			_drip_t = 0.0
			_spawn_drop(global_position + Vector2(randf_range(-16.0, 16.0), 12.0),
					Vector2(randf_range(-20.0, 20.0), 30.0), randf_range(10.0, 18.0))

	var vel := (global_position - _prev_pos) / delta
	_prev_pos = global_position

	# Estela mientras se mueve (también al regresar a su lugar)
	if (_dragging or _returning) and global_position.distance_to(_last_drop_pos) > trail_spacing:
		_last_drop_pos = global_position
		_spawn_drop(global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)),
				(-vel * 0.05).limit_length(120.0) + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 30.0)),
				randf_range(14.0, 30.0))

	# Inclinación y "crecer" con resortes (solo el dibujo)
	var sway_target := clampf(vel.x * 0.0012, -0.5, 0.5)
	_sway_vel += ((sway_target - _sway) * 170.0 - _sway_vel * 7.0) * dt
	_sway += _sway_vel * dt

	var lift_target := 0.25 if _dragging else 0.0
	_lift_vel += ((lift_target - _lift) * 220.0 - _lift_vel * 12.0) * dt
	_lift += _lift_vel * dt

	visual.rotation = _sway
	visual.scale = Vector2.ONE * (1.0 + _lift)


func _find_target():
	var best := 70.0
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
	(visual.material as ShaderMaterial).set_shader_parameter("selected", 0.0)

	var target = _find_target()
	_set_highlight(_highlighted, false)
	_highlighted = null
	if target:
		target.paint(mask)

	# Salpicadura al soltar
	for i in 10:
		var ang := TAU * i / 10.0 + randf() * 0.5
		_spawn_drop(global_position, Vector2.RIGHT.rotated(ang) * randf_range(150.0, 320.0),
				randf_range(14.0, 26.0), 0.7)

	_returning = true
	_last_drop_pos = global_position
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", home_position, 0.3)
	_tween.tween_callback(func(): _returning = false)


func _spawn_drop(pos: Vector2, velocity: Vector2, size: float, life: float = 0.6) -> void:
	var d = DROP.instantiate()
	get_tree().current_scene.add_child(d)
	d.global_position = pos
	d.launch(_color, size, velocity, life)
