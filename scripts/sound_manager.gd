extends Node
## Sonido del juego (autoload "Sound"). Todo se GENERA por código, no hay archivos de audio:
##  - Efectos: cada uno es una lista de "capas" (onda, barrido de frecuencia, envolvente)
##    que se sintetiza a un AudioStreamWAV la primera vez que se usa y se guarda en caché.
##  - Música: pistas compuestas por código (acordes, bajo, melodía y batería) que se
##    renderizan en un hilo y suenan en bucle.
##  - Tus propios archivos: si existe res://audio/sfx/<nombre>.(ogg|mp3|wav) reemplaza al
##    efecto procedural, y res://audio/music/<nombre>.(ogg|mp3|wav) a la pista procedural
##    (se pone en bucle solo). Ver audio/README.md.
##
## Uso:
##   Sound.play("click")                       # efecto
##   Sound.play_varied("pick", 0.06)           # con el tono ligeramente al azar
##   Sound.play_music("game")                  # música en bucle (cambia con fundido)
##   Sound.play_music_stream(mi_stream)        # cualquier AudioStream propio, en bucle
##   Sound.stop_music()
##   Sound.set_muted(true) / Sound.toggle_mute()
##   Sound.register_sfx("mi_sonido", [ {...capa...}, ... ])

const RATE := 22050
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const EXTENSIONS := ["ogg", "mp3", "wav"]
const VOICES := 10                 # efectos que pueden sonar a la vez
const ARP := [0, 1, 2, 1, 0, 1, 2, 1]

enum Wave { SINE, TRI, SQUARE, SAW, NOISE }

## Efectos. Cada capa admite (todo opcional salvo dur):
##   at (s de inicio), dur (s), f0 y f1 (Hz al inicio y al final: barrido), wave (Wave),
##   amp (volumen 0..1), atk (ataque en s), dec (caída exponencial, más alto = más corto),
##   rel (fundido final en s), vib_hz y vib (vibrato: velocidad y profundidad),
##   noise (0..1: mezcla de ruido con la onda)
const SFX := {
	"click": [{"dur": 0.07, "f0": 900.0, "f1": 650.0, "amp": 0.45, "dec": 38.0}],
	"hover": [{"dur": 0.045, "f0": 1250.0, "f1": 1350.0, "amp": 0.16, "dec": 55.0}],
	"locked": [{"dur": 0.16, "f0": 210.0, "f1": 150.0, "wave": Wave.SQUARE, "amp": 0.22, "dec": 14.0}],
	"pick": [{"dur": 0.10, "f0": 520.0, "f1": 800.0, "wave": Wave.TRI, "amp": 0.40, "dec": 14.0}],
	"drop": [
		{"dur": 0.14, "f0": 320.0, "f1": 140.0, "amp": 0.50, "dec": 20.0},
		{"dur": 0.04, "wave": Wave.NOISE, "amp": 0.18, "dec": 60.0},
	],
	"paint": [
		{"dur": 0.28, "f0": 300.0, "f1": 720.0, "amp": 0.34, "dec": 5.0, "vib_hz": 24.0, "vib": 0.09},
		{"at": 0.06, "dur": 0.22, "f0": 520.0, "f1": 940.0, "amp": 0.22, "dec": 7.0, "vib_hz": 31.0, "vib": 0.07},
		{"dur": 0.16, "wave": Wave.NOISE, "amp": 0.10, "dec": 14.0},
	],
	"eat": [
		{"dur": 0.09, "f0": 430.0, "f1": 230.0, "wave": Wave.TRI, "amp": 0.55, "dec": 12.0},
		{"at": 0.12, "dur": 0.09, "f0": 520.0, "f1": 270.0, "wave": Wave.TRI, "amp": 0.50, "dec": 12.0},
		{"at": 0.25, "dur": 0.16, "f0": 330.0, "f1": 700.0, "wave": Wave.TRI, "amp": 0.45, "dec": 7.0},
	],
	"happy": [
		{"dur": 0.22, "f0": 523.25, "wave": Wave.TRI, "amp": 0.40, "dec": 7.0},
		{"at": 0.08, "dur": 0.22, "f0": 659.25, "wave": Wave.TRI, "amp": 0.40, "dec": 7.0},
		{"at": 0.16, "dur": 0.30, "f0": 783.99, "wave": Wave.TRI, "amp": 0.40, "dec": 6.0},
	],
	"reject": [
		{"dur": 0.42, "f0": 250.0, "f1": 95.0, "wave": Wave.SAW, "amp": 0.28, "dec": 4.5, "vib_hz": 13.0, "vib": 0.05},
		{"dur": 0.42, "f0": 125.0, "f1": 48.0, "amp": 0.40, "dec": 4.0},
	],
	"levelup": [
		{"dur": 0.30, "f0": 523.25, "wave": Wave.TRI, "amp": 0.45, "dec": 5.0},
		{"at": 0.11, "dur": 0.30, "f0": 659.25, "wave": Wave.TRI, "amp": 0.45, "dec": 5.0},
		{"at": 0.22, "dur": 0.30, "f0": 783.99, "wave": Wave.TRI, "amp": 0.45, "dec": 5.0},
		{"at": 0.35, "dur": 0.80, "f0": 1046.5, "wave": Wave.TRI, "amp": 0.45, "dec": 3.5},
		{"at": 0.35, "dur": 0.80, "f0": 2093.0, "wave": Wave.SQUARE, "amp": 0.08, "dec": 4.0},
	],
	"pop": [{"dur": 0.10, "f0": 300.0, "f1": 950.0, "amp": 0.50, "dec": 24.0}],
	"whoosh": [{"dur": 0.40, "wave": Wave.NOISE, "amp": 0.20, "atk": 0.12, "dec": 5.0}],
	"sparkle": [
		{"dur": 0.12, "f0": 1568.0, "amp": 0.20, "dec": 18.0},
		{"at": 0.06, "dur": 0.12, "f0": 2093.0, "amp": 0.20, "dec": 18.0},
		{"at": 0.12, "dur": 0.16, "f0": 2637.0, "amp": 0.20, "dec": 16.0},
	],
}

## Pistas de música. bars compases de 4 tiempos; chords/bass en notas MIDI (60 = Do central);
## melody: por compás, lista de [tiempo, nota, duración en tiempos].
const MUSIC := {
	"menu": {
		"bpm": 88, "bars": 4, "drums": false,
		"chords": [[60, 64, 67], [57, 60, 64], [65, 69, 72], [67, 71, 74]],
		"bass": [48, 45, 41, 43],
		"arp_shift": 12, "arp_wave": Wave.TRI, "arp_amp": 0.10,
		"lead_wave": Wave.SINE, "lead_amp": 0.20,
		"melody": [
			[[0.0, 76, 1.5], [2.0, 79, 1.0], [3.0, 76, 1.0]],
			[[0.0, 81, 1.5], [2.0, 79, 1.0], [3.0, 76, 1.0]],
			[[0.0, 77, 1.5], [2.0, 76, 1.0], [3.0, 72, 1.0]],
			[[0.0, 74, 1.0], [1.0, 76, 1.0], [2.0, 79, 2.0]],
		],
	},
	"game": {
		"bpm": 118, "bars": 4, "drums": true,
		"chords": [[60, 64, 67], [59, 62, 67], [57, 60, 64], [53, 57, 60]],
		"bass": [48, 43, 45, 41],
		"arp_shift": 0, "arp_wave": Wave.TRI, "arp_amp": 0.12,
		"lead_wave": Wave.SQUARE, "lead_amp": 0.09,
		"melody": [
			[[0.0, 72, 0.5], [0.5, 76, 0.5], [1.0, 79, 0.5], [1.5, 76, 0.5], [2.0, 72, 0.5], [2.5, 76, 0.5], [3.0, 79, 1.0]],
			[[0.0, 74, 0.5], [0.5, 79, 0.5], [1.0, 83, 0.5], [1.5, 79, 0.5], [2.0, 74, 0.5], [2.5, 79, 0.5], [3.0, 83, 1.0]],
			[[0.0, 72, 0.5], [0.5, 76, 0.5], [1.0, 81, 0.5], [1.5, 76, 0.5], [2.0, 72, 0.5], [2.5, 76, 0.5], [3.0, 81, 1.0]],
			[[0.0, 77, 0.5], [0.5, 81, 0.5], [1.0, 77, 0.5], [1.5, 72, 0.5], [2.0, 77, 1.0], [3.0, 72, 1.0]],
		],
	},
}

var _defs := {}                  # efectos disponibles (SFX + los registrados)
var _cache := {}                 # nombre -> AudioStream ya sintetizado o cargado
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0

var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _music_name := ""            # pista pedida
var _music_cache := {}           # pista -> AudioStream
var _building := {}              # pistas que se están generando en un hilo


func _ready() -> void:
	_defs = SFX.duplicate(true)
	_setup_buses()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_voices.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	set_music_volume(SaveData.get_setting("music_volume", 0.8), false)
	set_sfx_volume(SaveData.get_setting("sfx_volume", 1.0), false)
	AudioServer.set_bus_mute(0, SaveData.get_setting("muted", false))

	# Las pistas procedurales empiezan a generarse ya, en segundo plano
	for track in MUSIC:
		if _load_file(MUSIC_DIR, track) == null:
			_build_music_async(track)
	_warm_up()


## Sintetiza los efectos poco a poco (un frame cada uno) para no trabar el arranque
func _warm_up() -> void:
	for sfx in _defs.keys():
		_get_sfx(sfx)
		await get_tree().process_frame


func _setup_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


# ---------------------------------------------------------------------------------------
# API pública: efectos
# ---------------------------------------------------------------------------------------

## Reproduce un efecto. pitch: 1.0 = normal; volume_db: 0 = normal.
func play(sfx: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream := _get_sfx(sfx)
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Como play(), con el tono un poco al azar (spread = variación máxima, 0.06 = ±6 %)
func play_varied(sfx: String, spread: float = 0.06, volume_db: float = 0.0) -> void:
	play(sfx, 1.0 + randf_range(-spread, spread), volume_db)


## Añade (o reemplaza) un efecto procedural. `layers` usa el formato de la constante SFX.
func register_sfx(sfx: String, layers: Array) -> void:
	_defs[sfx] = layers
	_cache.erase(sfx)


## Usa un AudioStream tuyo como efecto con ese nombre.
func register_stream(sfx: String, stream: AudioStream) -> void:
	_cache[sfx] = stream


# ---------------------------------------------------------------------------------------
# API pública: música y volúmenes
# ---------------------------------------------------------------------------------------

## Música en bucle por nombre ("menu", "game" o una pista propia en res://audio/music/).
## Si ya está sonando no hace nada; si no, cambia con un fundido.
func play_music(track: String) -> void:
	if track == _music_name and (_music_player.playing or _building.has(track)):
		return
	_music_name = track
	var stream: AudioStream = null
	if _music_cache.has(track):
		stream = _music_cache[track]
	else:
		stream = _load_file(MUSIC_DIR, track)
		if stream != null:
			stream = _loopable(stream)
			_music_cache[track] = stream
	if stream != null:
		_start_music(stream)
	elif MUSIC.has(track):
		_build_music_async(track)  # al terminar arranca sola (si sigue siendo la pedida)
	else:
		push_warning("Sound: no existe la pista '%s'" % track)


## Música en bucle con cualquier AudioStream (se duplica y se le activa el bucle).
func play_music_stream(stream: AudioStream, id: String = "custom") -> void:
	_music_name = id
	_start_music(_loopable(stream))


func stop_music(fade: float = 0.5) -> void:
	_music_name = ""
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -50.0, fade)
	_music_tween.tween_callback(_music_player.stop)


## Volumen de la música (0..1). Se guarda salvo que persist sea false.
func set_music_volume(linear: float, persist: bool = true) -> void:
	_set_bus_volume(MUSIC_BUS, linear)
	if persist:
		SaveData.set_setting("music_volume", linear)


## Volumen de los efectos (0..1). Se guarda salvo que persist sea false.
func set_sfx_volume(linear: float, persist: bool = true) -> void:
	_set_bus_volume(SFX_BUS, linear)
	if persist:
		SaveData.set_setting("sfx_volume", linear)


func set_muted(value: bool) -> void:
	AudioServer.set_bus_mute(0, value)
	SaveData.set_setting("muted", value)


func is_muted() -> bool:
	return AudioServer.is_bus_mute(0)


## Alterna el silencio general y devuelve el nuevo estado (true = silenciado).
func toggle_mute() -> bool:
	set_muted(not is_muted())
	return is_muted()


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


# ---------------------------------------------------------------------------------------
# Música: reproducción
# ---------------------------------------------------------------------------------------

func _start_music(stream: AudioStream) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music_player.playing:
		_music_tween.tween_property(_music_player, "volume_db", -50.0, 0.35)
	_music_tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.volume_db = -50.0
		_music_player.play())
	_music_tween.tween_property(_music_player, "volume_db", 0.0, 0.9)


## Activa el bucle en una copia del stream (WAV, OGG o MP3)
func _loopable(stream: AudioStream) -> AudioStream:
	var s := stream.duplicate() as AudioStream
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		var bytes_per := (2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if w.stereo else 1)
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / bytes_per
	else:
		s.set("loop", true)  # OGG y MP3
	return s


func _load_file(dir: String, file_name: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path: String = dir + file_name + "." + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _build_music_async(track: String) -> void:
	if _building.has(track) or _music_cache.has(track):
		return
	_building[track] = true
	WorkerThreadPool.add_task(func():
		var stream := _compose(track)
		_on_music_built.call_deferred(track, stream))


func _on_music_built(track: String, stream: AudioStreamWAV) -> void:
	_building.erase(track)
	_music_cache[track] = stream
	if _music_name == track:
		_start_music(stream)


# ---------------------------------------------------------------------------------------
# Síntesis
# ---------------------------------------------------------------------------------------

func _get_sfx(sfx: String) -> AudioStream:
	if _cache.has(sfx):
		return _cache[sfx]
	var stream := _load_file(SFX_DIR, sfx)
	if stream == null and _defs.has(sfx):
		stream = _synth(_defs[sfx])
	if stream == null:
		push_warning("Sound: no existe el efecto '%s'" % sfx)
		return null
	_cache[sfx] = stream
	return stream


func _synth(layers: Array) -> AudioStreamWAV:
	var total := 0.0
	for layer in layers:
		total = maxf(total, float(layer.get("at", 0.0)) + float(layer["dur"]))
	var buf := PackedFloat32Array()
	buf.resize(int((total + 0.05) * RATE))
	for layer in layers:
		_render_layer(buf, layer, false)
	return _to_wav(buf, false, 1.0)


## Suma una capa al búfer. Con wrap = true lo que se pasa del final vuelve al principio
## (así las notas de una pista en bucle no se cortan en la unión).
func _render_layer(buf: PackedFloat32Array, layer: Dictionary, wrap: bool) -> void:
	var size := buf.size()
	var start := int(float(layer.get("at", 0.0)) * RATE)
	var n := int(float(layer["dur"]) * RATE)
	var f0: float = layer.get("f0", 440.0)
	var f1: float = layer.get("f1", f0)
	var wave: int = layer.get("wave", Wave.SINE)
	var amp: float = layer.get("amp", 0.5)
	var atk: float = maxf(layer.get("atk", 0.004), 0.0005)
	var dec: float = layer.get("dec", 6.0)
	var rel: float = maxf(layer.get("rel", 0.01), 0.001)
	var vib_hz: float = layer.get("vib_hz", 0.0)
	var vib: float = layer.get("vib", 0.0)
	var noise_mix: float = layer.get("noise", 0.0)
	var phase := 0.0
	var seed_n := (start * 2654435761 + 12345) & 0x7fffffff   # ruido propio (sirve en hilos)

	for i in n:
		var idx := start + i
		if idx >= size:
			if wrap:
				idx = idx % size
			else:
				break
		var t := float(i) / RATE
		var f := lerpf(f0, f1, float(i) / float(maxi(n - 1, 1)))
		if vib > 0.0:
			f *= 1.0 + vib * sin(TAU * vib_hz * t)
		phase += TAU * f / RATE

		var s := 0.0
		match wave:
			Wave.SINE:
				s = sin(phase)
			Wave.TRI:
				s = asin(sin(phase)) * 0.6366
			Wave.SQUARE:
				s = 0.5 if sin(phase) >= 0.0 else -0.5
			Wave.SAW:
				s = fmod(phase / TAU, 1.0) * 2.0 - 1.0
			_:
				seed_n = (seed_n * 1103515245 + 12345) & 0x7fffffff
				s = float(seed_n) / 1073741823.5 - 1.0
		if noise_mix > 0.0:
			seed_n = (seed_n * 1103515245 + 12345) & 0x7fffffff
			s = lerpf(s, float(seed_n) / 1073741823.5 - 1.0, noise_mix)

		var env := minf(t / atk, 1.0) * exp(-dec * t) * minf(float(n - i) / (rel * RATE), 1.0)
		buf[idx] += s * env * amp


func _to_wav(buf: PackedFloat32Array, loop: bool, gain: float) -> AudioStreamWAV:
	var n := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(tanh(buf[i] * gain) * 32000.0))  # tanh = limitador suave
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


static func _midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Compone una pista de MUSIC (corre en un hilo: no toca nada compartido)
func _compose(track: String) -> AudioStreamWAV:
	var def: Dictionary = MUSIC[track]
	var beat := 60.0 / float(def["bpm"])
	var bars: int = def["bars"]
	var buf := PackedFloat32Array()
	buf.resize(int(bars * 4.0 * beat * RATE))
	var chords: Array = def["chords"]
	var bass: Array = def["bass"]
	var melody: Array = def["melody"]
	var shift: int = def["arp_shift"]

	for bar in bars:
		var b0 := float(bar * 4)
		var chord: Array = chords[bar % chords.size()]
		var root: int = bass[bar % bass.size()]

		# Bajo: raíz en los tiempos 1 y 3
		_note(buf, beat, b0, root, 1.8, Wave.SINE, 0.30, 2.0)
		_note(buf, beat, b0 + 2.0, root, 1.8, Wave.SINE, 0.24, 2.2)

		# Arpegio en corcheas
		for step in 8:
			var tone: int = chord[ARP[step]] + shift
			_note(buf, beat, b0 + step * 0.5, tone, 0.9, def["arp_wave"], def["arp_amp"], 5.0)

		# Melodía
		for m in melody[bar % melody.size()]:
			_note(buf, beat, b0 + float(m[0]), int(m[1]), float(m[2]), def["lead_wave"], def["lead_amp"], 3.0)

		# Batería: bombo en 1 y 3, caja en 2 y 4, platillo en los contratiempos
		if def["drums"]:
			for kick in [0.0, 2.0]:
				_render_layer(buf, {"at": (b0 + kick) * beat, "dur": 0.14, "f0": 130.0, "f1": 42.0, "amp": 0.5, "dec": 22.0}, true)
			for snare in [1.0, 3.0]:
				_render_layer(buf, {"at": (b0 + snare) * beat, "dur": 0.12, "wave": Wave.NOISE, "amp": 0.12, "dec": 26.0}, true)
				_render_layer(buf, {"at": (b0 + snare) * beat, "dur": 0.10, "f0": 190.0, "f1": 150.0, "amp": 0.15, "dec": 30.0}, true)
			for hat in [0.5, 1.5, 2.5, 3.5]:
				_render_layer(buf, {"at": (b0 + hat) * beat, "dur": 0.05, "wave": Wave.NOISE, "amp": 0.06, "dec": 70.0}, true)

	return _to_wav(buf, true, 0.8)


func _note(buf: PackedFloat32Array, beat: float, at_beats: float, midi: int, dur_beats: float,
		wave: int, amp: float, dec: float) -> void:
	_render_layer(buf, {
		"at": at_beats * beat, "dur": dur_beats * beat, "f0": _midi_to_hz(float(midi)),
		"wave": wave, "amp": amp, "dec": dec, "atk": 0.01, "rel": 0.03,
	}, true)
