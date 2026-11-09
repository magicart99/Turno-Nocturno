extends Node2D
## Marca flotante sobre el objeto con el que Lalo puede interactuar.
## Lee `escuela.cercano_actual`, que ya calcula el bucle principal, para no repetir raycasts.
var escuela: Node2D
var objetivo: Node2D
var mostrar: float = 0.0
var reloj: float = 0.0
var fuente_tecla: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")
var fuente_texto: Font = preload("res://assets/fuentes/Barlow-Regular.ttf")

func _ready() -> void:
	escuela = get_parent()
	z_as_relative = false
	z_index = 60
	# Sin luz: la marca debe leerse aunque el objeto esté a oscuras.
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = sin_luz

func _process(delta: float) -> void:
	reloj += delta
	var nuevo: Node2D = null
	if escuela.jugando and not escuela.jugador.oculto and escuela.jugador.accion == "" and is_instance_valid(escuela.cercano_actual):
		nuevo = escuela.cercano_actual
	if nuevo != null:
		if nuevo != objetivo:
			mostrar = 0.0
		objetivo = nuevo
	mostrar = move_toward(mostrar, 1.0 if nuevo != null else 0.0, delta * 6.0)
	visible = mostrar > 0.01 and is_instance_valid(objetivo)
	if visible:
		global_position = objetivo.global_position + Vector2(0, -64 + sin(reloj * 3.0) * 3.0)
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(objetivo):
		return
	var a: float = mostrar
	var r: float = 12.0 + sin(reloj * 4.0) * 1.2
	var rombo := PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
	var borde := rombo.duplicate()
	borde.append(rombo[0])
	draw_circle(Vector2.ZERO, r + 9.0, Color(0.95, 0.72, 0.4, 0.07 * a))
	draw_colored_polygon(rombo, Color(0.03, 0.05, 0.07, 0.88 * a))
	draw_polyline(borde, Color(0.96, 0.78, 0.45, a), 2.0)
	var tecla: String = Controles.boton_interaccion()
	draw_string(fuente_tecla, Vector2(-30, 6), tecla, HORIZONTAL_ALIGNMENT_CENTER, 60, 15 if tecla.length() <= 1 else 11, Color(1, 0.93, 0.78, a))
	var titulo: Variant = objetivo.get("titulo")
	if titulo != null:
		draw_string(fuente_texto, Vector2(-120, r + 22), str(titulo), HORIZONTAL_ALIGNMENT_CENTER, 240, 13, Color(0.87, 0.91, 0.89, 0.85 * a))
