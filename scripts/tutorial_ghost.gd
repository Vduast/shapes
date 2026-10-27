class_name TutorialGhost
extends Node2D
## Tutorial visual con una mano fantasma. Muestra, sin palabras, cómo cumplir lo que pide
## el slime: toma la figura de la bandeja, (si el slime pide color) la pinta con los botes
## que hagan falta y se la lleva al slime. Una guía de puntitos marca el camino y la figura
## fantasma cambia de color al "pintarla", igual que en el juego.
##
## Main la lanza con play() al empezar cada nivel (y como ayuda si el jugador se atora) y
## se detiene sola al primer clic del jugador, al terminar sus repeticiones o con stop().

signal finished

const BURST := preload("res://scenes/paint_burst.tscn")

## Cuántas veces repite la demostración antes de desvanecerse
@export var loops := 3
## Duración (s) de cada traslado de la mano
@export var move_time := 0.85

var _playing := false
var _tween: Tween
var _fx: Tween
var _fade: Tween
var _carry: Node2D = null              # lo que lleva la mano ahora (figura o bote fantasma)
var _segments: Array = []              # [[desde, hasta], ...] guía punteada
var _shape_mask := 0                   # color que lleva la figura fantasma
var _t := 0.0
var _hand_mat: ShaderMaterial
var _shape_mat: ShaderMaterial
var _bucket_mat: ShaderMaterial

@onready var hand: Node2D = $Hand
@onready var shape_ghost: Node2D = $ShapeGhost
@onready var bucket_ghost: Node2D = $BucketGhost


func _ready() -> void:
	_hand_mat = _own_material($Hand/Body)
	_shape_mat = _own_material($ShapeGhost/Body)
	_bucket_mat = _own_material($BucketGhost/Body)
	$ShapeGhost/Body.pivot_offset = $ShapeGhost/Body.size / 2.0
	$BucketGhost/Body.pivot_offset = $BucketGhost/Body.size / 2.0


func _own_material(rect: ColorRect) -> ShaderMaterial:
	var m := (rect.material as ShaderMaterial).duplicate() as ShaderMaterial
	rect.material = m
	return m


func is_playing() -> bool:
	return _playing


## Lanza la demostración.
##  shape_type / mask: lo que pide el slime (mask <= 0 = cualquier color, no hace falta pintar)
##  tray: ShapeTray (slot_position)   palette: ColorPalette (bucket_position)
##  target: dónde está la boca del slime
func play(shape_type: int, mask: int, tray: Node2D, palette: Node2D, target: Vector2) -> void:
	stop(true)

	var start: Vector2 = tray.slot_position(shape_type)
	var work := Vector2(start.x, (start.y + target.y) * 0.5 + 10.0)  # mesa de trabajo entre bandeja y slime

	# Botes primarios que hay que mezclar (1 rojo, 2 amarillo, 4 azul)
	var bits: Array = []
	var bucket_pos := {}
	if mask > 0:
		for bit in [1, 2, 4]:
			if mask & bit:
				bits.append(bit)
				bucket_pos[bit] = palette.bucket_position(bit)

	# Guía punteada
	_segments = []
	if bits.is_empty():
		_segments.append([start, target])
	else:
		_segments.append([start, work])
		for bit in bits:
			_segments.append([bucket_pos[bit], work])
		_segments.append([work, target])

	_playing = true
	if _fade:
		_fade.kill()
	modulate.a = 1.0
	visible = true

	_tween = create_tween()
	_tween.set_loops(loops)
	_build(_tween, shape_type, start, work, bits, bucket_pos, target)
	_tween.finished.connect(stop)


## Detiene la demostración. immediate = true la oculta de golpe (sin desvanecer).
func stop(immediate: bool = false) -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if _fx:
		_fx.kill()
	if not _playing:
		return
	_playing = false
	_carry = null
	queue_redraw()
	if immediate:
		visible = false
		return
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.0, 0.25)
	_fade.tween_callback(func(): visible = false)
	finished.emit()


## El primer clic del jugador corta la ayuda
func _input(event: InputEvent) -> void:
	if _playing and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop()


func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta
	if _carry:
		_carry.position = hand.position
	hand.rotation = sin(_t * 3.0) * 0.05
	queue_redraw()


## Guía de puntitos: los puntos "corren" hacia el destino
func _draw() -> void:
	if not _playing:
		return
	var base_a := 0.30 + 0.10 * sin(_t * 4.0)
	for seg in _segments:
		var from: Vector2 = seg[0]
		var to: Vector2 = seg[1]
		var dist := from.distance_to(to)
		var n := maxi(int(dist / 26.0), 2)
		for i in range(1, n):
			var k := float(i) / float(n)
			var pulse := maxf(0.0, sin(_t * 5.0 - k * 7.0))
			draw_circle(from.lerp(to, k), 3.5 + 2.5 * pulse, Color(1, 1, 1, base_a + 0.35 * pulse))


# ---------------------------------------------------------------------------------------
# Línea de tiempo (una vuelta de la demostración)
# ---------------------------------------------------------------------------------------

func _build(t: Tween, shape_type: int, start: Vector2, work: Vector2, bits: Array,
		bucket_pos: Dictionary, target: Vector2) -> void:
	# 1. La mano aparece junto a la figura de la bandeja y la agarra
	t.tween_callback(_begin_loop.bind(shape_type, start))
	t.tween_property(hand, "modulate:a", 1.0, 0.3)
	_move(t, start, 0.45)
	t.tween_callback(_take_shape.bind(start))
	t.tween_method(_set_grab, 0.0, 1.0, 0.15)

	# 2. La lleva a la "mesa" (si hay que pintar) o directo al slime
	_move(t, target if bits.is_empty() else work, move_time)

	# 3. Por cada color primario: va por el bote, lo arrastra sobre la figura y la pinta
	var running := 0
	for i in bits.size():
		var bit: int = bits[i]
		running |= bit
		if i == 0:
			t.tween_callback(_drop_carry)
			t.tween_method(_set_grab, 1.0, 0.0, 0.15)
		_move(t, bucket_pos[bit], 0.55)
		t.tween_callback(_take_bucket.bind(bit, bucket_pos[bit]))
		t.tween_method(_set_grab, 0.0, 1.0, 0.15)
		_move(t, work, 0.7)
		t.tween_callback(_paint.bind(running, work))
		t.tween_method(_set_grab, 1.0, 0.0, 0.15)
		t.tween_interval(0.35)

	# 4. Recoge la figura ya pintada y se la lleva al slime
	if not bits.is_empty():
		t.tween_method(_set_grab, 0.0, 1.0, 0.15)
		t.tween_callback(_carry_shape)
		_move(t, target, move_time)

	# 5. El slime se la come; la mano se despide
	t.tween_callback(_eat.bind(target))
	t.tween_method(_set_grab, 1.0, 0.0, 0.15)
	t.tween_interval(0.5)
	t.tween_property(hand, "modulate:a", 0.0, 0.3)
	t.tween_interval(0.8)


func _move(t: Tween, to: Vector2, time: float) -> void:
	t.tween_property(hand, "position", to, time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _begin_loop(shape_type: int, start: Vector2) -> void:
	_shape_mask = 0
	_carry = null
	hand.position = start + Vector2(70.0, 90.0)
	hand.modulate.a = 0.0
	_set_grab(0.0)
	bucket_ghost.visible = false
	shape_ghost.visible = false
	shape_ghost.scale = Vector2.ONE
	_shape_mat.set_shader_parameter("shape_type", shape_type)
	_set_shape_color(0, 0)
	_shape_mat.set_shader_parameter("wave", 1.0)


func _take_shape(start: Vector2) -> void:
	shape_ghost.position = start
	shape_ghost.visible = true
	_carry = shape_ghost
	Sound.play("pick", 1.0, -10.0)


func _carry_shape() -> void:
	_carry = shape_ghost


func _drop_carry() -> void:
	_carry = null


func _take_bucket(bit: int, pos: Vector2) -> void:
	var c := GameData.mask_to_color(bit)
	_bucket_mat.set_shader_parameter("fill_color", c)
	_bucket_mat.set_shader_parameter("old_color", c)
	bucket_ghost.position = pos
	bucket_ghost.visible = true
	_carry = bucket_ghost
	Sound.play("pick", 1.3, -10.0)


## El bote llega a la figura: estallido, onda de color y el bote fantasma desaparece
func _paint(new_mask: int, pos: Vector2) -> void:
	_carry = null
	bucket_ghost.visible = false
	var c := GameData.mask_to_color(new_mask)
	_spawn_burst(pos, c, 0.9)
	Sound.play("paint", 1.0, -10.0)
	_set_shape_color(_shape_mask, new_mask)
	_shape_mask = new_mask
	if _fx:
		_fx.kill()
	_fx = create_tween()
	_fx.tween_method(_set_wave, 0.0, 1.0, 0.4)


func _eat(pos: Vector2) -> void:
	_carry = null
	_spawn_burst(pos, Color.WHITE, 1.0)
	Sound.play("eat", 1.0, -10.0)
	if _fx:
		_fx.kill()
	_fx = create_tween()
	_fx.tween_property(shape_ghost, "scale", Vector2.ZERO, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _set_grab(v: float) -> void:
	_hand_mat.set_shader_parameter("grab", v)
	hand.scale = Vector2.ONE * (1.0 - 0.08 * v)


func _set_wave(v: float) -> void:
	_shape_mat.set_shader_parameter("wave", v)


func _set_shape_color(old_mask: int, new_mask: int) -> void:
	_shape_mat.set_shader_parameter("old_color", GameData.mask_to_color(old_mask))
	_shape_mat.set_shader_parameter("fill_color", GameData.mask_to_color(new_mask))


func _spawn_burst(pos: Vector2, color: Color, size: float) -> void:
	var b = BURST.instantiate()
	add_child(b)
	b.position = pos
	b.scale = Vector2.ONE * size
	b.play(color)
