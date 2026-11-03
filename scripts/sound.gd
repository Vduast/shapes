class_name Sound
extends RefCounted
## Acceso global al sonido del juego: Sound.play("click"), Sound.play_music("game"), etc.
## Es una clase estática (no un autoload): la primera vez que se usa crea un SoundManager
## (scripts/sound_manager.gd) y lo cuelga de la raíz del árbol, donde sobrevive a los cambios
## de escena. Ver sound_manager.gd para cómo se generan los sonidos y audio/README.md para
## poner tus propios archivos.

static var _manager: SoundManager = null


static func _m() -> SoundManager:
	if _manager == null or not is_instance_valid(_manager):
		_manager = SoundManager.new()
		_manager.name = "SoundManager"
		# Diferido: puede llamarse mientras la raíz aún está montando la escena
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_manager)
	return _manager


## Reproduce un efecto. pitch: 1.0 = normal; volume_db: 0 = normal.
static func play(sfx: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	_m().play(sfx, pitch, volume_db)


## Como play(), con el tono un poco al azar (spread = variación máxima, 0.06 = ±6 %).
static func play_varied(sfx: String, spread: float = 0.06, volume_db: float = 0.0) -> void:
	_m().play_varied(sfx, spread, volume_db)


## Añade (o reemplaza) un efecto procedural; ver la constante SFX de SoundManager.
static func register_sfx(sfx: String, layers: Array) -> void:
	_m().register_sfx(sfx, layers)


## Usa un AudioStream tuyo como efecto con ese nombre.
static func register_stream(sfx: String, stream: AudioStream) -> void:
	_m().register_stream(sfx, stream)


## Música en bucle por nombre ("menu", "game" o una pista propia en res://audio/music/).
static func play_music(track: String) -> void:
	_m().play_music(track)


## Música en bucle con cualquier AudioStream.
static func play_music_stream(stream: AudioStream, id: String = "custom") -> void:
	_m().play_music_stream(stream, id)


static func stop_music(fade: float = 0.5) -> void:
	_m().stop_music(fade)


## Volumen de la música / de los efectos (0..1); se guarda.
static func set_music_volume(linear: float) -> void:
	_m().set_music_volume(linear)


static func set_sfx_volume(linear: float) -> void:
	_m().set_sfx_volume(linear)


## Activa o desactiva la vibración en celulares (se guarda).
static func set_haptics(value: bool) -> void:
	_m().set_haptics(value)


static func set_muted(value: bool) -> void:
	_m().set_muted(value)


static func is_muted() -> bool:
	return _m().is_muted()


## Alterna el silencio general y devuelve el nuevo estado (true = silenciado).
static func toggle_mute() -> bool:
	return _m().toggle_mute()
