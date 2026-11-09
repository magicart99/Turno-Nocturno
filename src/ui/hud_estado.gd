extends Control
## Panel de estado del HUD: cordura, resistencia, pila y sigilo.
## Cada fila tiene icono, barra con degradado, estela del daño reciente y valor.
## Por debajo de 25 la fila late en rojo. Al pie: dinero, mochila, circuito y postura.
const Mochila = preload("res://src/player/mochila.gd")
const FILAS := [
	["cordura", "CORDURA", Color("b9a3f0")],
	["energia", "RESISTENCIA", Color("f0c36a")],
	["bateria", "PILA", Color("7fd3f0")],
	["sigilo", "SIGILO", Color("88d8b0")],
]
const ANCHO := 316.0
var escuela: Node2D
var mostrados: Dictionary = {}
var estelas: Dictionary = {}
var tiempo: float = 0.0
var estilo: StyleBoxFlat
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")
var fuente_texto: Font = preload("res://assets/fuentes/Barlow-Regular.ttf")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(24, 116)
	size = Vector2(ANCHO, 128)
	estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.035, 0.045, 0.78)
	estilo.border_color = Color(0.55, 0.65, 0.66, 0.25)
	estilo.set_border_width_all(1)
	estilo.border_width_left = 3
	estilo.set_corner_radius_all(6)

func valor(nombre: String) -> float:
	match nombre:
		"cordura": return escuela.jugador.cordura
		"energia": return escuela.jugador.energia
		"bateria": return escuela.campana.bateria
	return escuela.jugador.sigilo

func _process(delta: float) -> void:
	visible = escuela.jugando and escuela.campana != null
	if not visible:
		return
	tiempo += delta
	for fila in FILAS:
		var actual: float = valor(fila[0])
		mostrados[fila[0]] = move_toward(float(mostrados.get(fila[0], actual)), actual, delta * 90.0)
		var estela: float = float(estelas.get(fila[0], actual))
		estelas[fila[0]] = actual if actual > estela else move_toward(estela, actual, delta * 22.0)
	queue_redraw()

func _draw() -> void:
	if escuela == null or escuela.campana == null:
		return
	draw_style_box(estilo, Rect2(Vector2.ZERO, size))
	for i in range(FILAS.size()):
		var fila: Array = FILAS[i]
		var y: float = 10.0 + i * 24.0
		var color: Color = fila[2]
		var actual: float = valor(fila[0])
		var mostrado: float = float(mostrados.get(fila[0], actual))
		var estela: float = float(estelas.get(fila[0], actual))
		var pulso: float = (0.5 + 0.5 * sin(tiempo * 7.0)) if actual < 25.0 else 0.0
		var tono: Color = color.lerp(Color("ff6b5a"), pulso)
		icono(fila[0], Vector2(16, y + 8), tono)
		draw_string(fuente_texto, Vector2(32, y + 12), fila[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9fb0b0"))
		var barra := Rect2(114, y + 3, 156, 10)
		draw_rect(barra, Color(0.05, 0.08, 0.1, 0.92))
		draw_rect(Rect2(barra.position, Vector2(barra.size.x * clampf(estela / 100.0, 0, 1), barra.size.y)), Color(1, 0.86, 0.8, 0.5))
		var ancho: float = barra.size.x * clampf(mostrado / 100.0, 0, 1)
		draw_rect(Rect2(barra.position, Vector2(ancho, barra.size.y)), tono.darkened(0.28))
		draw_rect(Rect2(barra.position, Vector2(ancho, barra.size.y * 0.45)), tono.lightened(0.12))
		for k in range(1, 4):
			var x: float = barra.position.x + barra.size.x * k / 4.0
			draw_line(Vector2(x, barra.position.y), Vector2(x, barra.end.y), Color(0, 0, 0, 0.45), 1.0)
		draw_rect(barra, Color(1, 1, 1, 0.14), false, 1.0)
		draw_string(fuente, Vector2(barra.end.x + 8, y + 13), "%d" % roundi(actual), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ff8f80") if actual < 25.0 else Color("e8efe9"))
	var j: CharacterBody2D = escuela.jugador
	var c: Node = escuela.campana
	var postura: String = "OCULTO" if j.oculto else ("AGACHADO" if j.agachado else ("CORRIENDO" if j.ruido > 0.5 else ("CAMINANDO" if j.ruido > 0.0 else "SILENCIO")))
	var circuito: String = str(c.alimentado).replace("_", " ") if str(c.alimentado) != "" else "NINGUNO"
	var pie := "$%d   ·   MOCHILA %d/6   ·   LUZ: %s   ·   %s" % [c.monedas, Mochila.usados(j.inventario), circuito.to_upper(), postura]
	draw_string(fuente_texto, Vector2(12, size.y - 10), pie, HORIZONTAL_ALIGNMENT_LEFT, ANCHO - 20, 11, Color("8ea3a6"))

func icono(tipo: String, centro: Vector2, color: Color) -> void:
	match tipo:
		"cordura":
			# Ojo abierto: lo que Lalo todavía puede ver con claridad.
			draw_arc(centro, 6.0, PI * 1.15, PI * 1.85, 10, color, 2.0)
			draw_arc(centro, 6.0, PI * 0.15, PI * 0.85, 10, color, 2.0)
			draw_circle(centro, 2.2, color)
		"energia":
			draw_colored_polygon(PackedVector2Array([centro + Vector2(1, -7), centro + Vector2(-5, 1), centro + Vector2(1, 1)]), color)
			draw_colored_polygon(PackedVector2Array([centro + Vector2(-1, -1), centro + Vector2(5, -1), centro + Vector2(-2, 7)]), color)
		"bateria":
			draw_rect(Rect2(centro + Vector2(-7, -4), Vector2(12, 8)), color, false, 1.5)
			draw_rect(Rect2(centro + Vector2(5, -2), Vector2(2, 4)), color)
			draw_rect(Rect2(centro + Vector2(-5, -2), Vector2(8.0 * clampf(escuela.campana.bateria / 100.0, 0, 1), 4)), color)
		_:
			# Ondas de sonido: cuánto silencio le queda.
			draw_circle(centro + Vector2(-4, 0), 1.8, color)
			draw_arc(centro + Vector2(-4, 0), 5.0, -0.8, 0.8, 8, color, 1.5)
			draw_arc(centro + Vector2(-4, 0), 9.0, -0.7, 0.7, 8, color, 1.5)
