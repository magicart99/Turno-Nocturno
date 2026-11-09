extends Node2D
## Detalles por lugar, solo visuales y sin colisiones nuevas:
## pizarrones con gis, relojes detenidos a las 00:00, sillas que se mueven solas,
## reflejos en los espejos y la cafetería con hornilla, vapor y neón.
const Atmosfera = preload("res://src/world/atmosfera.gd")
const GIS := ["FALTA UNO", "LISTA: 31 / 32", "NO SE PERMITE SALIR", "ENTREGA FINAL: HOY", "¿QUIÉN APAGÓ LA LUZ?",
	"TAREA: CERRAR TU TURNO", "PRESENTE PRESENTE PRES", "NO ESTÁS SOLO", "00:00 00:00 00:00", "CALIFICACIÓN: BAJA"]
const GIS_LOCURA := ["TU NOMBRE NO ESTÁ", "LALO · BAJA", "YA TE ARCHIVARON", "¿PRESENTE?"]
var escuela: Node2D
var pizarrones: Array[Node2D] = []
var relojes: Array[Node2D] = []
var espejos: Array[Node2D] = []
var sillas: Array[Node2D] = []
var espejos_vistos: Dictionary = {}
var espera_silla: float = 30.0
var decorado_campus: bool = false
var luces_campus: Array[Dictionary] = []
var vapor: CPUParticles2D
var material_espectro: CanvasItemMaterial
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")

func _ready() -> void:
	escuela = get_parent()
	z_index = 2
	material_espectro = CanvasItemMaterial.new()
	material_espectro.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for objeto in escuela.get_node("Objetos").get_children():
		var titulo: Variant = objeto.get("titulo")
		if titulo == "Pizarron": pizarrones.append(objeto)
		elif titulo == "Reloj": relojes.append(objeto)
		elif titulo == "Espejo": espejos.append(objeto)
		elif titulo == "Silla": sillas.append(objeto)

func _process(delta: float) -> void:
	if escuela.campana == null:
		return
	var principal: bool = escuela.campana.lugar == "principal"
	if not decorado_campus and is_instance_valid(escuela.campana.exterior):
		decorar_campus()
	if escuela.jugando:
		if principal:
			mover_sillas(delta)
			revisar_espejos()
		else:
			animar_campus()
	queue_redraw()

func mover_sillas(delta: float) -> void:
	# Una silla cercana se arrastra sola. Es visual: no cambia colisiones ni hace ruido para el Archivero.
	espera_silla -= delta
	if espera_silla > 0.0 or sillas.is_empty():
		return
	espera_silla = randf_range(28.0, 50.0)
	var jugador: Vector2 = escuela.jugador.global_position
	for i in range(8):
		var silla: Node2D = sillas[randi() % sillas.size()]
		if not is_instance_valid(silla):
			continue
		var d: float = silla.global_position.distance_to(jugador)
		if d < 200.0 or d > 460.0:
			continue
		var sprite := silla.get_node_or_null("Sprite") as Node2D
		if sprite == null:
			return
		var t := sprite.create_tween()
		t.tween_property(sprite, "position", sprite.position + Vector2(randf_range(-7, 7), randf_range(-5, 5)), 0.35).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(sprite, "rotation", randf_range(-0.22, 0.22), 0.35)
		escuela.sonidos.efecto("metal", silla.global_position, -24)
		return

func revisar_espejos() -> void:
	var jugador: CharacterBody2D = escuela.jugador
	if jugador.cordura >= 92.0:
		return
	for espejo in espejos:
		if not is_instance_valid(espejo) or espejos_vistos.has(espejo.get_instance_id()):
			continue
		if espejo.global_position.distance_to(jugador.global_position) > 110.0:
			continue
		espejos_vistos[espejo.get_instance_id()] = true
		# Algo más se refleja detrás de Lalo durante un segundo.
		var reflejo := Sprite2D.new()
		reflejo.texture = preload("res://assets/sprites/eco_computo.png")
		reflejo.scale = Vector2.ONE * 0.11
		reflejo.modulate = Color(0.75, 0.85, 0.9, 0.0)
		reflejo.material = material_espectro
		reflejo.z_as_relative = false
		reflejo.z_index = 7
		add_child(reflejo)
		reflejo.global_position = espejo.global_position + Vector2(randf_range(-12, 12), -6)
		var t := reflejo.create_tween()
		t.tween_property(reflejo, "modulate:a", 0.55, 0.35)
		t.tween_interval(0.5)
		t.tween_property(reflejo, "modulate:a", 0.0, 0.4)
		t.tween_callback(reflejo.queue_free)
		escuela.sonidos.efecto("susurro", espejo.global_position, -22)
		if is_instance_valid(escuela.mente):
			escuela.mente.presenciar(4.0)
		return

func decorar_campus() -> void:
	decorado_campus = true
	for punto in get_tree().get_nodes_in_group("puntos_campana"):
		var clave: Variant = punto.get("clave")
		if clave == "revision_cafe":
			agregar_luz(punto, Color(1.0, 0.55, 0.2), 0.9, 0.55, "fuego", "revision_cafe")
			vapor = CPUParticles2D.new()
			vapor.amount = 12
			vapor.lifetime = 2.4
			vapor.position = Vector2(0, -22)
			vapor.direction = Vector2(0, -1)
			vapor.spread = 22.0
			vapor.gravity = Vector2(0, -12)
			vapor.initial_velocity_min = 6.0
			vapor.initial_velocity_max = 14.0
			vapor.scale_amount_min = 3.0
			vapor.scale_amount_max = 6.0
			vapor.color_ramp = gradiente_vapor()
			punto.add_child(vapor)
		elif clave == "tienda":
			agregar_luz(punto, Color(0.55, 1.0, 0.8), 0.7, 0.8, "neon", "")
		elif clave == "revision_banos":
			agregar_luz(punto, Color(0.9, 0.12, 0.12), 0.6, 0.45, "pulso", "revision_banos")

func agregar_luz(punto: Node2D, color: Color, energia: float, escala: float, modo: String, hecho: String) -> void:
	var luz := PointLight2D.new()
	luz.texture = Atmosfera.textura_radial(Color.WHITE, 160)
	luz.color = color
	luz.energy = energia
	luz.texture_scale = escala
	luz.position = Vector2(0, -16)
	punto.add_child(luz)
	luces_campus.append({"luz": luz, "base": energia, "modo": modo, "hecho": hecho})

func gradiente_vapor() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(0.9, 0.92, 0.95, 0.22), Color(1, 1, 1, 0.0)])
	return g

func animar_campus() -> void:
	var t: float = escuela.tiempo
	for dato in luces_campus:
		var luz: PointLight2D = dato["luz"]
		if not is_instance_valid(luz):
			continue
		var hecho: String = dato["hecho"]
		var resuelto: bool = hecho != "" and escuela.campana.hechos.get(hecho, false)
		var base: float = dato["base"]
		match dato["modo"]:
			"fuego":
				luz.energy = 0.0 if resuelto else base * (0.75 + 0.25 * sin(t * 13.0) * sin(t * 5.3) + randf() * 0.1)
			"neon":
				luz.energy = base * (0.15 if sin(t * 2.1) * sin(t * 17.0) > 0.86 else 1.0)
			"pulso":
				luz.energy = 0.0 if resuelto else base * (0.5 + 0.5 * sin(t * 1.6))
	if is_instance_valid(vapor):
		vapor.emitting = not escuela.campana.hechos.get("revision_cafe", false)

func _draw() -> void:
	if escuela.campana == null or escuela.campana.lugar != "principal":
		return
	var cerca: Vector2 = escuela.jugador.position
	var locura: bool = escuela.jugador.cordura < 45.0
	# Plumón en los pizarrones: se lee al iluminarlos.
	for i in range(pizarrones.size()):
		var p: Node2D = pizarrones[i]
		if not is_instance_valid(p) or p.global_position.distance_to(cerca) > 700.0:
			continue
		var texto: String = GIS_LOCURA[i % GIS_LOCURA.size()] if locura else GIS[i % GIS.size()]
		var origen: Vector2 = p.global_position + Vector2(-72, 2)
		# Plumón sobre el pizarrón blanco: azul normal, rojo cuando la cordura se rompe.
		var tinta := Color(0.75, 0.12, 0.1, 0.85) if locura else Color(0.13, 0.22, 0.55, 0.8)
		draw_string(fuente, origen, texto, HORIZONTAL_ALIGNMENT_CENTER, 144, 12, tinta)
		draw_line(origen + Vector2(30, 6), origen + Vector2(114, 6), Color(tinta, 0.4), 1.0)
	# Relojes detenidos a las 00:00; el segundero tiembla sin avanzar.
	for r in relojes:
		if not is_instance_valid(r) or r.global_position.distance_to(cerca) > 700.0:
			continue
		var centro: Vector2 = r.global_position
		draw_line(centro, centro + Vector2(0, -7), Color(0.08, 0.08, 0.08), 2.0)
		draw_line(centro, centro + Vector2(0, -5), Color(0.08, 0.08, 0.08), 2.5)
		var temblor: float = sin(escuela.tiempo * 30.0) * 0.12
		draw_line(centro, centro + Vector2.from_angle(-PI / 2 + temblor) * 9.0, Color(0.7, 0.1, 0.08), 1.0)
		draw_circle(centro, 1.5, Color(0.1, 0.1, 0.1))
