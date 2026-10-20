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
		"goal": 5,
		"palette": false,
	},
	{
		"name": "Colores primarios",
		"hint": "Arrastra un bote sobre la forma para pintarla y dásela al slime",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4],
		"goal": 6,
		"palette": true,
	},
	{
		"name": "Naranja",
		"hint": "Rojo + amarillo = naranja. ¡Pinta la forma con los dos botes!",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [3],
		"goal": 4,
		"palette": true,
	},
	{
		"name": "Verde",
		"hint": "Amarillo + azul = verde",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [6],
		"goal": 4,
		"palette": true,
	},
	{
		"name": "Morado",
		"hint": "Azul + rojo = morado",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [5],
		"goal": 4,
		"palette": true,
	},
	{
		"name": "Solo Mezclas",
		"hint": "¡Mezcla! Rojo+amarillo, amarillo+azul o azul+rojo",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [3, 6, 5],
		"goal": 6,
		"palette": true,
	},
	{
		"name": "Marrón",
		"hint": "Mezcla los tres colores: rojo + amarillo + azul = marrón",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [7],
		"goal": 4,
		"palette": true,
	},
	{
		"name": "Estrellas y corazones",
		"hint": "Solo piden estrellas y corazones, ¡de todos los colores!",
		"shapes": [3, 4],
		"masks": [1, 2, 4, 3, 6, 5, 7],
		"goal": 6,
		"palette": true,
	},
	{
		"name": "¡Todo junto!",
		"hint": "Pinta, mezcla y alimenta al slime",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5],
		"goal": 8,
		"palette": true,
	},
	{
		"name": "Maestro de colores",
		"hint": "Todas las formas y todos los colores, sin fin",
		"shapes": [0, 1, 2, 3, 4],
		"masks": [1, 2, 4, 3, 6, 5, 7],
		"goal": 0,
		"palette": true,
	},
]


static func mask_to_color(mask: int) -> Color:
	return COLORS.get(mask, COLORS[0])


static func mask_to_name(mask: int) -> String:
	return NAMES.get(mask, "?")


## Pide algo al azar según el nivel, evitando repetir lo último.
static func random_request(stage: int, last: Dictionary = {}) -> Dictionary:
	var cfg: Dictionary = STAGES[clampi(stage, 0, STAGES.size() - 1)]
	var shapes: Array = cfg["shapes"]
	var masks: Array = cfg["masks"]
	var r := {}
	for i in 12:
		var m: int = ANY_COLOR if masks.is_empty() else masks.pick_random()
		r = {"shape": shapes.pick_random(), "mask": m}
		if last.is_empty() or r["shape"] != last.get("shape") or r["mask"] != last.get("mask"):
			break
	return r
