class_name GameData
extends RefCounted

enum ShapeType { CIRCLE, SQUARE, TRIANGLE, STAR, HEART }

const RED := 1
const YELLOW := 2
const BLUE := 4

## wanted_mask con este valor = el slime acepta cualquier color (solo importa la forma)
const ANY_COLOR := -1

const COLORS := {
	0: Color(0.93, 0.93, 0.93),
	1: Color(0.90, 0.12, 0.12),
	2: Color(1.00, 0.85, 0.10),
	4: Color(0.15, 0.30, 0.95),
	3: Color(1.00, 0.50, 0.05),
	6: Color(0.10, 0.70, 0.25),
	5: Color(0.58, 0.15, 0.78),
	7: Color(0.38, 0.24, 0.12),
}

const NAMES := {
	0: "Blanco", 1: "Rojo", 2: "Amarillo", 4: "Azul",
	3: "Naranja", 6: "Verde", 5: "Morado", 7: "Marrón",
}

## Niveles. goal = aciertos para pasar al siguiente (0 = nivel final, infinito)
## shapes: formas que puede pedir (y que ofrece la bandeja). masks: colores que puede pedir
## (vacío = cualquier color). palette: si se muestran los botes de pintura.
## Para añadir un nivel basta con agregar otro diccionario; el último debe tener goal 0.
##
## Opcionales (todos los lee random_request, así que los niveles no son "pinta todo del mismo
## color" sino una mezcla que cambia de petición en petición):
##  "tutorial": false      desactiva la mano fantasma al empezar el nivel (por defecto activa).
##  "focus_masks": [..]    colores "protagonistas" del nivel (suben su probabilidad); el resto de
##                         `masks` sale como repaso de lo aprendido.
##  "focus_shapes": [..]   igual, pero con formas.
##  "focus_weight": 0..1   probabilidad de que una petición use un protagonista (def. 0.5).
##  "any_chance": 0..1     probabilidad de una petición "relámpago": solo la forma, sin color
##                         (el slime acepta cualquier color, incluso sin pintar).
##  "keep_color_chance": 0..1  probabilidad de repetir el color de la petición anterior con otra
##                         forma (rachas: un mismo bote sirve para pintar varias figuras seguidas).
## Nota: si se agregan niveles en medio, el progreso guardado apunta por número de nivel.
const STAGES := [
	{
		"name": "Formas",
		"hint": "Arrastra al slime la forma que pide",
		"shapes": [0, 1, 2],
		"masks": [],
		"goal": 5,
		"palette": false,
	},
	{
		"name": "Nuevas formas",
		"hint": "¡Llegaron la estrella y el corazón!",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [],
		"focus_shapes": [3, 4],   # las nuevas salen más seguido
		"focus_weight": 0.55,
		"goal": 6,
		"palette": false,
	},
	{
		"name": "Colores primarios",
		"hint": "Arrastra un bote sobre la forma para pintarla y dásela al slime",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4],
		"any_chance": 0.2,   # de vez en cuando basta con la forma
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Naranja",
		"hint": "Rojo + amarillo = naranja. ¡Pinta la forma con los dos botes!",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3],
		"focus_masks": [3],
		"focus_weight": 0.5,
		"any_chance": 0.1,
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Verde",
		"hint": "Amarillo + azul = verde",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6],
		"focus_masks": [6],
		"focus_weight": 0.5,
		"any_chance": 0.1,
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Morado",
		"hint": "Azul + rojo = morado",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5],
		"focus_masks": [5],
		"focus_weight": 0.5,
		"any_chance": 0.1,
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Descanso",
		"hint": "Sin pintura: ¡solo formas, rápido!",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [],
		"goal": 5,
		"palette": false,
		"tutorial": false,
	},
	{
		"name": "Solo Mezclas",
		"hint": "¡Mezcla! Rojo+amarillo, amarillo+azul o azul+rojo",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [3, 6, 5, 1, 2, 4],
		"focus_masks": [3, 6, 5],
		"focus_weight": 0.7,
		"any_chance": 0.15,
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Marrón",
		"hint": "Mezcla los tres colores: rojo + amarillo + azul = marrón",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [7, 3, 6, 5, 1, 2, 4],
		"focus_masks": [7],
		"focus_weight": 0.4,
		"any_chance": 0.1,
		"goal": 6,
		"palette": true,
	},
	{
		"name": "Racha de color",
		"hint": "El mismo color puede repetirse: ¡aprovecha el bote!",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5],
		"keep_color_chance": 0.6,
		"goal": 8,
		"palette": true,
		"tutorial": false,
	},
	{
		"name": "Estrellas y corazones",
		"hint": "Solo piden estrellas y corazones, ¡de todos los colores!",
		"shapes": [3, 4],
		"masks": [1, 2, 4, 3, 6, 5, 7],
		"any_chance": 0.15,
		"goal": 7,
		"palette": true,
	},
	{
		"name": "Relámpago",
		"hint": "¡Rápido! A veces solo piden la forma",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5],
		"any_chance": 0.45,
		"goal": 8,
		"palette": true,
		"tutorial": false,
	},
	{
		"name": "¡Todo junto!",
		"hint": "Pinta, mezcla y alimenta al slime",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5, 7],
		"any_chance": 0.15,
		"keep_color_chance": 0.25,
		"goal": 10,
		"palette": true,
	},
	{
		"name": "Maestro de colores",
		"hint": "Todas las formas y todos los colores, sin fin",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5, 7],
		"any_chance": 0.15,
		"keep_color_chance": 0.25,
		"goal": 0,
		"palette": true,
	},
]


static func mask_to_color(mask: int) -> Color:
	return COLORS.get(mask, COLORS[0])


static func mask_to_name(mask: int) -> String:
	return NAMES.get(mask, "?")


## Pide algo al azar según el nivel. Cada petición se elige así:
##  1. Forma: con probabilidad focus_weight sale una "protagonista" (focus_shapes); si no, cualquiera.
##  2. Color: con probabilidad any_chance es "relámpago" (solo forma, ANY_COLOR); si no, con
##     probabilidad focus_weight sale un color protagonista (focus_masks) y si no, cualquiera de masks.
##  3. Racha: con probabilidad keep_color_chance se repite el color anterior con otra forma.
## Se evita repetir la forma (y el color) de la petición anterior, para que no se sienta igual.
static func random_request(stage: int, last: Dictionary = {}) -> Dictionary:
	var cfg: Dictionary = STAGES[clampi(stage, 0, STAGES.size() - 1)]
	var shapes: Array = cfg["shapes"]
	var masks: Array = cfg["masks"]
	var focus_shapes: Array = cfg.get("focus_shapes", [])
	var focus_masks: Array = cfg.get("focus_masks", [])
	var focus_weight: float = cfg.get("focus_weight", 0.5)
	var any_chance: float = cfg.get("any_chance", 0.0)
	var keep_color: float = cfg.get("keep_color_chance", 0.0)

	var last_shape: int = last.get("shape", -1)
	var last_mask: int = last.get("mask", -2)

	var r := {}
	for i in 16:
		var shape: int = _pick(shapes, focus_shapes, focus_weight)
		var m: int = ANY_COLOR
		var streak := false
		if not masks.is_empty():
			if last_mask > 0 and last_mask in masks and randf() < keep_color:
				m = last_mask   # racha: mismo color, otra forma
				streak = true
			elif randf() >= any_chance:
				m = _pick(masks, focus_masks, focus_weight)
		r = {"shape": shape, "mask": m}

		var same_shape := shape == last_shape
		var same_mask := m == last_mask and m != ANY_COLOR
		if i < 10:
			# Primeros intentos: forma distinta y color distinto (salvo que sea una racha)
			if not same_shape and (not same_mask or streak):
				break
		elif not (same_shape and m == last_mask):
			break   # al menos que no sea exactamente la misma petición
	return r


## Elige de `pool`; con probabilidad `weight` elige de `focus` (si no está vacío).
static func _pick(pool: Array, focus: Array, weight: float) -> int:
	if not focus.is_empty() and randf() < weight:
		return focus.pick_random()
	return pool.pick_random()
