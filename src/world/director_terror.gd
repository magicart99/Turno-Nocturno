extends Node2D
## Niebla de patio, Ecos fugaces y oscilación de la única línea alimentada.
var espera: float = 22.0
var oscilacion: float = 0.0
var restaurar: bool = false
var eco: Sprite2D
## Eventos con silencio previo: primero calla el ambiente y luego ocurre algo.
var espera_evento: float = 45.0
var pendiente: String = ""
var cuenta: float = 0.0
var pasos_eco: float = 0.0
var reloj_paso: float = 0.0
var usados: Dictionary = {}
var bucles: int = 0
@onready var escuela: Node2D = get_parent()
func _ready() -> void:z_index=14
func _process(delta: float) -> void:
	queue_redraw()
	if not escuela.jugando:return
	if oscilacion>0:
		oscilacion=maxf(0,oscilacion-delta)
		for l in get_tree().get_nodes_in_group("luces_zona"):
			if l.enabled and l.get_meta("zona","")!="Exterior_Caseta":l.energy=float(l.get_meta("energia_base",.6))*(.15 if sin(escuela.tiempo*47)>0 else .85)
		restaurar=true
	elif restaurar:
		for l in get_tree().get_nodes_in_group("luces_zona"):l.energy=float(l.get_meta("energia_base",.6))
		restaurar=false
	revisar_bucle()
	actualizar_pasos(delta)
	if pendiente != "":
		cuenta -= delta
		if cuenta <= 0.0:
			ejecutar(pendiente)
			pendiente = ""
	elif escuela.peligro < 0.2 and not escuela.campana.gracia_activa():
		espera_evento -= delta
		if espera_evento <= 0.0:
			espera_evento = randf_range(35.0, 60.0)
			programar()
	if escuela.campana.gracia_activa() or escuela.peligro>.6:return
	espera-=delta
	if espera<=0:
		espera=randf_range(26,42)
		manifestacion()
func manifestacion() -> void:
	if is_instance_valid(eco):return
	var j: CharacterBody2D=escuela.jugador
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new();forma.radius=18
	consulta.shape=forma;consulta.collision_mask=1;consulta.exclude=[j.get_rid(),escuela.archivero.get_rid()]
	for i in range(8):
		var p: Vector2=j.global_position+Vector2.from_angle(randf()*TAU)*randf_range(210,300)
		consulta.transform=Transform2D(0,p)
		var rayo := PhysicsRayQueryParameters2D.create(j.global_position,p,1,[j.get_rid(),escuela.archivero.get_rid()])
		if not get_world_2d().direct_space_state.intersect_shape(consulta).is_empty() or not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():continue
		eco=Sprite2D.new();eco.texture=preload("res://assets/sprites/eco_computo.png");eco.position=p;eco.scale=Vector2.ONE*.23;eco.modulate=Color(.64,.68,.66,0)
		add_child(eco)
		var t := create_tween();t.tween_property(eco,"modulate:a",.48,.45);t.parallel().tween_property(eco,"position:y",p.y-14,1.4);t.tween_property(eco,"modulate:a",0.0,.7);t.tween_callback(eco.queue_free)
		escuela.sonidos.efecto("eco_%d" % randi_range(1,5),p,-18)
		if randf() < 0.5: escuela.sonidos.efecto("papeles",p+Vector2(65,20),-16)
		escuela.mente.presenciar(8.0)
		oscilacion=.65
		return
	escuela.sonidos.efecto("metal",j.position+Vector2(140,-60),-18)
func _draw() -> void:
	if escuela.campana==null:return
	var p: Vector2=escuela.jugador.position
	for i in range(7):
		var centro := p+Vector2(sin(escuela.tiempo*.035+i*1.7)*450,cos(i*2.7)*280)
		draw_circle(centro,190+i*13,Color(.38,.44,.49,.012))

func programar() -> void:
	var opciones: Array[String] = ["pasos"]
	var j: CharacterBody2D = escuela.jugador
	if escuela.campana.lugar == "principal":
		opciones.append("apagon")
		if not usados.has("altavoz"): opciones.append("altavoz")
	if j.linterna and j.cordura < 85.0: opciones.append("asomo")
	pendiente = opciones[randi() % opciones.size()]
	cuenta = 2.6
	escuela.sonidos.silencio = 3.4

func ejecutar(evento: String) -> void:
	match evento:
		"pasos":
			pasos_eco = 7.0
			reloj_paso = 0.6
		"apagon": apagon()
		"altavoz":
			usados["altavoz"] = true
			escuela.sonidos.efecto("radio_estatica", Vector2.INF, -12)
			escuela.relato.decir("ALTAVOZ · …Lalo… favor de presentarse en Rectoría. Su trámite sigue abierto. Su trámite sigue abierto.")
		"asomo": asomo()

func actualizar_pasos(delta: float) -> void:
	# Alguien camina detrás de Lalo al mismo ritmo y se detiene cuando él se detiene.
	if pasos_eco <= 0.0:
		return
	pasos_eco -= delta
	var j: CharacterBody2D = escuela.jugador
	if j.get_real_velocity().length() < 20.0 or j.agachado or j.oculto:
		reloj_paso = 0.15
		return
	reloj_paso -= delta
	if reloj_paso <= 0.0:
		reloj_paso = 0.52
		escuela.sonidos.efecto("paso", j.global_position - j.apuntado * 130.0, -19)

func apagon() -> void:
	# Las luces cercanas se apagan una tras otra, de la más lejana hacia Lalo, y vuelven después.
	var j: Vector2 = escuela.jugador.global_position
	var luces: Array = []
	for l in get_tree().get_nodes_in_group("luces_zona"):
		if l.enabled and not l.is_in_group("parpadeo") and l.global_position.distance_to(j) < 650.0:
			luces.append(l)
	if luces.is_empty():
		pasos_eco = 6.0
		return
	luces.sort_custom(func(a, b): return a.global_position.distance_to(j) > b.global_position.distance_to(j))
	for i in range(luces.size()):
		var luz: PointLight2D = luces[i]
		var base: float = float(luz.get_meta("energia_base", 0.6))
		var t := luz.create_tween()
		t.tween_interval(0.3 * i)
		t.tween_callback(func(): escuela.sonidos.efecto("interruptor", luz.global_position, -20))
		t.tween_property(luz, "energy", 0.0, 0.06)
		t.tween_interval(2.4 + 0.1 * (luces.size() - i))
		t.tween_property(luz, "energy", base, 0.4)
	escuela.mente.presenciar(6.0)

func asomo() -> void:
	# El Archivero aparece un instante al fondo del haz y desaparece. No hace daño.
	var j: CharacterBody2D = escuela.jugador
	var a: CharacterBody2D = escuela.archivero
	if a.activo and a.global_position.distance_to(j.global_position) < 700.0:
		return
	var espacio := get_world_2d().direct_space_state
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 14.0
	consulta.shape = forma
	consulta.collision_mask = 1
	for i in range(6):
		var p: Vector2 = j.global_position + Vector2.from_angle(j.apuntado.angle() + randf_range(-0.3, 0.3)) * randf_range(230.0, 290.0)
		consulta.transform = Transform2D(0, p)
		var rayo := PhysicsRayQueryParameters2D.create(j.global_position, p, 1, [j.get_rid(), a.get_rid()])
		if not espacio.intersect_shape(consulta).is_empty() or not espacio.intersect_ray(rayo).is_empty():
			continue
		var figura := Sprite2D.new()
		figura.texture = a.sprite.sprite_frames.get_frame_texture("down", 0)
		figura.scale = Vector2.ONE * 0.35
		figura.offset = Vector2(10, -140)
		figura.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		figura.z_as_relative = false
		figura.z_index = 5
		figura.modulate = Color(1, 1, 1, 0)
		add_child(figura)
		figura.global_position = p
		var t := figura.create_tween()
		t.tween_property(figura, "modulate:a", 0.85, 0.12)
		t.tween_interval(0.5)
		t.tween_property(figura, "modulate:a", 0.0, 0.25)
		t.tween_callback(figura.queue_free)
		escuela.mente.presenciar(5.0)
		j.cordura = maxf(0.0, j.cordura - 2.0)
		return

func revisar_bucle() -> void:
	# Plan de trabajo (semana 8): el pasillo vuelve a empezar hasta que Lalo tenga la llave maestra.
	var c: Node = escuela.campana
	var j: CharacterBody2D = escuela.jugador
	if c.etapa != 1 or c.lugar != "principal" or j.inventario.has("Llave maestra") or j.oculto or j.accion != "":
		return
	var p: Vector2 = j.global_position
	if p.x < 3060.0 or p.y < 520.0 or p.y > 830.0 or j.velocity.x <= 0.0:
		return
	var destino := Vector2(2330.0, p.y)
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 12.0
	consulta.shape = forma
	consulta.collision_mask = 1
	consulta.exclude = [j.get_rid()]
	consulta.transform = Transform2D(0, destino)
	if not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty():
		return
	bucles += 1
	j.global_position = destino
	j.get_node("Camera2D").reset_smoothing()
	escuela.interfaz.fundido_entrada(0.6)
	escuela.sonidos.efecto("susurro", Vector2.INF, -14)
	escuela.mente.presenciar(4.0)
	if bucles == 1:
		escuela.anunciar("EL PASILLO VUELVE A EMPEZAR", "Las mismas puertas, el mismo reloj. Algo no te deja llegar a Rectoría.")
	else:
		escuela.anunciar("OTRA VEZ EL MISMO PASILLO", "Sin la llave maestra no hay salida. Búscala en Dirección.")
