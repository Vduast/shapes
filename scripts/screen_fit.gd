class_name ScreenFit
extends RefCounted
## Ajuste de pantalla. El juego está diseñado para 1280x720 (16:9). Con cualquier otra
## proporción (celular 20:9, laptop 16:10, ventana angosta...) hay que garantizar DOS cosas:
##   1. Que el área de diseño completa SIEMPRE se vea (nada recortado a los lados o arriba).
##   2. Que el espacio sobrante (si lo hay) se reparta de forma ordenada.
## Para (1) se aleja la cámara (zoom < 1) cuando el área visible es más chica que 1280x720.
## Para (2) cada escena usa `visible_world()` para pegar cosas a los bordes reales.

const DESIGN := Vector2(1280.0, 720.0)


## Zoom que necesita la cámara para que quepa el área de diseño (nunca acerca: máx. 1).
static func zoom_for(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return minf(minf(viewport_size.x / DESIGN.x, viewport_size.y / DESIGN.y), 1.0)


## Ajusta el zoom de la cámara de la escena actual.
static func fit_camera(cam: Camera2D, viewport: Viewport) -> void:
	if cam == null:
		return
	var z := zoom_for(viewport.get_visible_rect().size)
	cam.zoom = Vector2(z, z)


## Área visible en coordenadas del mundo, tomando en cuenta posición y zoom de la cámara.
## Siempre es igual o mayor que 1280x720.
static func visible_world(cam: Camera2D, viewport: Viewport) -> Rect2:
	var size := viewport.get_visible_rect().size / cam.zoom
	size = Vector2(maxf(size.x, DESIGN.x), maxf(size.y, DESIGN.y))
	return Rect2(cam.position - size / 2.0, size)
