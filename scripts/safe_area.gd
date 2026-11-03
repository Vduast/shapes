class_name SafeArea
extends RefCounted
## Márgenes que hay que dejar para no quedar debajo de la muesca (notch), las esquinas
## redondeadas o la barra de gestos de un celular. Devuelve Vector4(izquierda, arriba,
## derecha, abajo) en unidades del juego (no en píxeles). En escritorio son todos 0.

const MAX_INSET := 160.0


static func insets(viewport: Viewport) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var screen := Vector2(DisplayServer.screen_get_size())
	if screen.x <= 0.0 or screen.y <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return Vector4.ZERO
	# El área segura viene en píxeles de pantalla: se pasa a unidades del juego
	var k := viewport.get_visible_rect().size / screen
	return Vector4(
		clampf(safe.position.x * k.x, 0.0, MAX_INSET),
		clampf(safe.position.y * k.y, 0.0, MAX_INSET),
		clampf((screen.x - safe.end.x) * k.x, 0.0, MAX_INSET),
		clampf((screen.y - safe.end.y) * k.y, 0.0, MAX_INSET))
