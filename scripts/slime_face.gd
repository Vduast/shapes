class_name SlimeFace
extends RefCounted
## Cara del slime (ojos y boca). El dibujo lo hace monster.gdshader; esta clase solo decide
## QUÉ cara poner y la anima: cada parámetro del shader se acerca suavemente al valor del
## estado de ánimo (Mood) actual, así los gestos se mezclan en vez de saltar.
##
## Uso (lo hacen Monster y MenuSlime):
##   face = SlimeFace.new(material)            # material ya duplicado
##   face.update(delta, base_mood, look)       # cada frame; base_mood = cara "de fondo"
##   face.play([[Mood.EATING, 0.45], [Mood.HAPPY, 1.0]])  # gesto temporal, pisa al de fondo
##   face.glance(Vector2(-1, -1), 1.2)         # mira hacia ahí un rato (p. ej. al globo)

enum Mood {
	IDLE,       ## tranquilo: sonrisa chica
	EXCITED,    ## hay una figura encima o el ratón cerca: ojos grandes, boca abierta
	EATING,     ## masticando: ojos felices y boca que abre y cierra
	HAPPY,      ## acaba de comer: ojos felices, sonrisa grande y mejillas
	CHEER,      ## subió de nivel: sonrisa enorme
	SAD,        ## rechazó la figura: cejas tristes y ceño
	SURPRISED,  ## lo tocaron: ojos enormes y boca en "o"
	SLEEPY,     ## mucho rato sin que pase nada: ojos medio cerrados
}

## Cada estado fija los uniforms de cara de monster.gdshader (mismos nombres).
## Las caras son exageradas a propósito (estilo Slime Rancher): ojos que se agrandan y
## se ponen llorosos (`shine`), bocas enormes con lengua, lágrimas y destellos.
const PRESETS := {
	Mood.IDLE: {
		"eye_open": 1.0, "eye_happy": 0.0, "eye_size": 1.0, "shine": 1.0, "brow": 0.0,
		"mouth_curve": 0.7, "mouth_open": 0.18, "mouth_width": 0.75,
		"blush": 0.0, "tears": 0.0, "sparkle": 0.0,
	},
	Mood.EXCITED: {
		"eye_open": 1.0, "eye_happy": 0.0, "eye_size": 1.25, "shine": 1.8, "brow": 0.0,
		"mouth_curve": 0.6, "mouth_open": 0.85, "mouth_width": 1.0,
		"blush": 0.5, "tears": 0.0, "sparkle": 0.0,
	},
	Mood.EATING: {
		"eye_open": 0.0, "eye_happy": 1.0, "eye_size": 1.1, "shine": 1.0, "brow": 0.0,
		"mouth_curve": 1.0, "mouth_open": 0.55, "mouth_width": 1.05,
		"blush": 0.8, "tears": 0.0, "sparkle": 0.0,
	},
	Mood.HAPPY: {
		"eye_open": 0.0, "eye_happy": 1.0, "eye_size": 1.15, "shine": 1.0, "brow": 0.0,
		"mouth_curve": 1.0, "mouth_open": 0.7, "mouth_width": 1.2,
		"blush": 1.0, "tears": 0.0, "sparkle": 0.6,
	},
	Mood.CHEER: {
		"eye_open": 0.0, "eye_happy": 1.0, "eye_size": 1.25, "shine": 1.0, "brow": 0.0,
		"mouth_curve": 1.0, "mouth_open": 1.0, "mouth_width": 1.35,
		"blush": 1.0, "tears": 0.0, "sparkle": 1.0,
	},
	Mood.SAD: {
		"eye_open": 1.0, "eye_happy": 0.0, "eye_size": 1.25, "shine": 2.0, "brow": -1.0,
		"mouth_curve": -1.0, "mouth_open": 0.25, "mouth_width": 0.8,
		"blush": 0.0, "tears": 1.0, "sparkle": 0.0,
	},
	Mood.SURPRISED: {
		"eye_open": 1.0, "eye_happy": 0.0, "eye_size": 1.45, "shine": 1.6, "brow": 0.0,
		"mouth_curve": 0.0, "mouth_open": 0.9, "mouth_width": 0.55,
		"blush": 0.0, "tears": 0.0, "sparkle": 0.0,
	},
	Mood.SLEEPY: {
		"eye_open": 0.1, "eye_happy": 0.0, "eye_size": 1.0, "shine": 1.0, "brow": 0.0,
		"mouth_curve": 0.0, "mouth_open": 0.25, "mouth_width": 0.4,
		"blush": 0.0, "tears": 0.0, "sparkle": 0.0,
	},
}

## Qué tan rápido se acercan los parámetros a su objetivo (suavizado exponencial)
const RATE := 12.0
## Segundos entre parpadeos (al azar entre ambos valores) y lo que dura cada uno
const BLINK_EVERY := Vector2(2.0, 5.0)
const BLINK_TIME := 0.16

var current: int = Mood.IDLE  ## estado que se está mostrando ahora mismo

var _mat: ShaderMaterial
var _p := {}                  # valores actuales de los parámetros
var _time := 0.0
var _seq: Array = []          # gestos pendientes: [[mood, segundos], ...]
var _seq_left := 0.0
var _blink_wait := 2.0
var _blink_t := 1.0
var _look := Vector2.ZERO
var _glance := Vector2.ZERO
var _glance_left := 0.0


func _init(material: ShaderMaterial) -> void:
	_mat = material
	_p = (PRESETS[Mood.IDLE] as Dictionary).duplicate()
	_blink_wait = randf_range(BLINK_EVERY.x, BLINK_EVERY.y)


## Reproduce una secuencia de gestos, cada uno [mood, segundos]. Mientras dura, pisa al
## estado de fondo; al terminar vuelve a él. Una secuencia nueva reemplaza a la anterior.
func play(sequence: Array) -> void:
	_seq = sequence.duplicate()
	if not _seq.is_empty():
		_seq_left = _seq[0][1]


## Mira hacia `dir` (-1..1 en cada eje) durante `seconds`, sin importar el ratón.
func glance(dir: Vector2, seconds: float) -> void:
	_glance = dir
	_glance_left = seconds


## Llamar cada frame. `base_mood` es la cara de fondo; `look_dir` hacia dónde mira.
func update(delta: float, base_mood: int, look_dir: Vector2 = Vector2.ZERO) -> void:
	_time += delta

	# Gesto temporal (si hay) o cara de fondo
	var mood := base_mood
	if not _seq.is_empty():
		mood = _seq[0][0]
		_seq_left -= delta
		if _seq_left <= 0.0:
			_seq.pop_front()
			if not _seq.is_empty():
				_seq_left = _seq[0][1]
	current = mood

	# Los parámetros se acercan a los del estado actual
	var target: Dictionary = PRESETS[mood]
	var k := 1.0 - exp(-RATE * delta)
	for key in target:
		_p[key] = lerpf(_p[key], target[key], k)

	# Mirada: el "vistazo" manda sobre el ratón; dormido mira al frente
	var want := look_dir
	if _glance_left > 0.0:
		_glance_left -= delta
		want = _glance
	if mood == Mood.SLEEPY:
		want = Vector2.ZERO
	_look = _look.lerp(want, 1.0 - exp(-8.0 * delta))

	# Parpadeo cada cierto tiempo (más lento si tiene sueño)
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_t = 0.0
		_blink_wait = randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
	var blink := 0.0
	if _blink_t < 1.0:
		_blink_t += delta / BLINK_TIME
		blink = sin(clampf(_blink_t, 0.0, 1.0) * PI)

	_apply(blink)


func _apply(blink: float) -> void:
	for key in _p:
		_mat.set_shader_parameter(key, _p[key])
	# Masticando: la boca abre y cierra rápido encima del valor base
	if current == Mood.EATING:
		_mat.set_shader_parameter("mouth_open", clampf(_p["mouth_open"] + 0.3 * sin(_time * 22.0), 0.0, 1.0))
	_mat.set_shader_parameter("blink", blink)
	_mat.set_shader_parameter("look", _look)
