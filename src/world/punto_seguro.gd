extends Node2D
## Punto seguro (plan de trabajo, semanas 6 y 9): al entrar se guarda la partida y,
## mientras Lalo permanece dentro, recupera cordura poco a poco hasta 75.
## El Archivero no puede atraparlo ni seguir los ruidos que haga aquí.
const Atmosfera = preload("res://src/world/atmosfera.gd")
const RADIO := 95.0
const CORDURA_MAXIMA := 75.0
var escuela: Node2D
var lugar: String = "principal"
var nombre_punto: String = "Sala de espera"
## En el campus el punto se ancla a un punto de campaña (clave) cuando el exterior existe.
var ancla: String = ""
var desplazamiento := Vector2.ZERO
var anclado: bool = false
var dentro: bool = false
var primera: bool = true
var tiempo: float = 0.0
var luz: PointLight2D
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")

func _ready() -> void:
	escuela = get_tree().get_first_node_in_group("control")
	add_to_group("puntos_seguros")
	z_index = 1
	anclado = ancla == ""
	luz = PointLight2D.new()
	luz.texture = Atmosfera.textura_radial(Color.WHITE, 200)
	luz.color = Color(1.0, 0.78, 0.5)
	luz.energy = 0.5
	luz.texture_scale = 1.1
	add_child(luz)

func activo() -> bool:
	return anclado and escuela.campana != null and escuela.campana.lugar == lugar

func contiene(p: Vector2) -> bool:
	return activo() and global_position.distance_to(p) < RADIO

func _process(delta: float) -> void:
	if not anclado:
		anclar()
	visible = activo()
	if not visible or not escuela.jugando:
		return
	tiempo += delta
	var j: CharacterBody2D = escuela.jugador
	var ahora: bool = contiene(j.global_position)
	if ahora and not dentro and not primera:
		var a: CharacterBody2D = escuela.archivero
		if (not a.activo or a.global_position.distance_to(j.global_position) > 420.0) and escuela.guardar_partida():
			escuela.anunciar("PUNTO SEGURO · " + nombre_punto.to_upper(), "Partida guardada. Aquí recuperas cordura poco a poco y el Archivero no puede alcanzarte.")
			escuela.sonidos.efecto("aviso", Vector2.INF, -20)
	primera = false
	dentro = ahora
	if dentro and j.cordura < CORDURA_MAXIMA:
		j.cordura = minf(CORDURA_MAXIMA, j.cordura + 1.2 * delta)
	luz.energy = 0.5 + 0.06 * sin(tiempo * 2.0)
	queue_redraw()

func anclar() -> void:
	for punto in get_tree().get_nodes_in_group("puntos_campana"):
		if punto.get("clave") == ancla:
			global_position = punto.global_position + desplazamiento
			anclado = true
			return

func _draw() -> void:
	var alfa: float = 0.16 + 0.05 * sin(tiempo * 2.0)
	draw_arc(Vector2.ZERO, RADIO, 0, TAU, 48, Color(1, 0.8, 0.55, alfa), 2.0)
	draw_string(fuente, Vector2(-60, RADIO - 8), "PUNTO SEGURO", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 0.86, 0.62, alfa + 0.15))
