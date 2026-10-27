class_name SaveData
extends RefCounted
## Guardado del juego en `user://shapes_save.cfg` (ConfigFile). Todo es estático: no hace
## falta instanciarla ni registrarla como autoload.
##
## Guarda el nivel más alto alcanzado (los niveles se desbloquean al llegar a ellos) y los
## ajustes de sonido. El número de niveles sale de GameData.STAGES, así que al añadir un
## nivel nuevo el menú de niveles lo muestra solo.

const PATH := "user://shapes_save.cfg"

## Nivel elegido en el menú para la próxima partida (-1 = ninguno). Main lo lee y lo limpia.
static var pending_stage := -1

static var _cfg: ConfigFile
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_cfg = ConfigFile.new()
	_cfg.load(PATH)  # si el archivo no existe simplemente queda vacío
	_loaded = true


static func save() -> void:
	_ensure()
	_cfg.save(PATH)


## Índice (desde 0) del nivel más alto desbloqueado, siempre dentro de GameData.STAGES.
static func unlocked_stage() -> int:
	_ensure()
	var v: int = _cfg.get_value("progress", "unlocked", 0)
	return clampi(v, 0, GameData.STAGES.size() - 1)


## Desbloquea (y guarda) el nivel `index` si es más alto que el que ya se tenía.
static func unlock_stage(index: int) -> void:
	if index > unlocked_stage():
		_cfg.set_value("progress", "unlocked", clampi(index, 0, GameData.STAGES.size() - 1))
		save()


static func is_unlocked(index: int) -> bool:
	return index <= unlocked_stage()


## Un nivel está completado cuando ya se desbloqueó el siguiente (el último nunca: es infinito).
static func is_completed(index: int) -> bool:
	return index < unlocked_stage()


## Borra el progreso (los ajustes se conservan).
static func reset_progress() -> void:
	_ensure()
	if _cfg.has_section("progress"):
		_cfg.erase_section("progress")
	pending_stage = -1
	save()


static func get_setting(key: String, default: Variant) -> Variant:
	_ensure()
	return _cfg.get_value("settings", key, default)


static func set_setting(key: String, value: Variant) -> void:
	_ensure()
	_cfg.set_value("settings", key, value)
	save()
