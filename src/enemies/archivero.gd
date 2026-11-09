extends CharacterBody2D
## No ve al jugador: patrulla y sigue posiciones de sonidos con memoria limitada.
const Geo = preload("res://src/world/geometria_campus.gd")
const Animacion = preload("res://src/player/animacion_personaje.gd")
@export var velocidad_patrulla: float = 65.0
@export var velocidad_busqueda: float = 142.0
var vision_reloj := 0.0
var activo: bool = false
var estado: String = "DORMIDO"
var destino := Vector2(3264, 670)
var memoria: float = 0.0
var espera: float = 0.0
var reaccion: float = 0.0
var atascado := 0.0
var repelido := 0.0
var recalcular: float = 0.0
var paso: float = 0.0
var camino := PackedVector2Array()
var puntos := [Vector2(3264, 670), Vector2(2496, 670), Vector2(1728, 670), Vector2(960, 670), Vector2(192, 670)]
var punto: int = 0
var sprite: AnimatedSprite2D
var rejilla := AStarGrid2D.new()
var lista: bool = false
var celda: float = 16.0
var voz_espera: float = 0.0
var persiguiendo := false
var revisando := false
var revisados: Dictionary = {}
## Segundos en que el gafete de la Prefecta lo hace ignorar a Lalo (un solo uso).
var ignorar: float = 0.0
@onready var escuela: Node2D = get_parent()

func _ready() -> void:
	name = "Archivero"
	position = Vector2(3264, 670)
	z_index = 5
	collision_layer = 2
	collision_mask = 1
	var colision := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 13.0
	colision.shape = forma
	add_child(colision)
	sprite = Animacion.crear("archivero")
	add_child(sprite)
	hide()

func construir_rutas() -> void:
	var exterior: bool = escuela.campana.lugar == "campus"
	celda = 32.0 if exterior else 16.0
	rejilla.region = Rect2i(Vector2i.ZERO,Vector2i(ceili(Geo.TAMANO.x/32.0),ceili(Geo.TAMANO.y/32.0))) if exterior else Rect2i(0, 0, 240, 84)
	rejilla.cell_size = Vector2.ONE * celda
	rejilla.offset = Vector2.ONE * celda * 0.5
	puntos = Geo.PATRULLA.duplicate() if exterior else [Vector2(3264,670),Vector2(2496,670),Vector2(1728,670),Vector2(960,670),Vector2(192,670)]
	if exterior and escuela.campana.etapa >= 4: puntos.append(Geo.PARKING)
	# Intensidad por nivel (GDD): lento en el edificio principal para aprender sus
	# patrones, y persecución intensa en el estacionamiento.
	var etapa: int = clampi(escuela.campana.etapa, 1, 4)
	velocidad_patrulla = 55.0 if etapa == 1 else 65.0
	velocidad_busqueda = [88.0, 98.0, 98.0, 116.0][etapa - 1]
	punto = 0
	rejilla.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	rejilla.update()
	var excluidos: Array[RID] = [get_rid(), escuela.jugador.get_rid()]
	for objeto in get_tree().get_nodes_in_group("interactivos"):
		if objeto.tipo == "puerta" and objeto.is_visible_in_tree():
			excluidos.append(objeto.get_rid())
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 13.0
	consulta.shape = forma
	consulta.collision_mask = 1
	consulta.exclude = excluidos
	for y in range(rejilla.region.size.y):
		for x in range(rejilla.region.size.x):
			consulta.transform = Transform2D(0, Vector2(x + 0.5, y + 0.5) * celda)
			rejilla.set_point_solid(Vector2i(x, y), not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty())
	lista = true
	recalcular = 0

func celda_libre(posicion: Vector2) -> Vector2i:
	var indice := Vector2i(floori(posicion.x / celda), floori(posicion.y / celda))
	for radio in range(7):
		for y in range(-radio, radio + 1):
			for x in range(-radio, radio + 1):
				var candidata := indice + Vector2i(x, y)
				if rejilla.is_in_boundsv(candidata) and not rejilla.is_point_solid(candidata):
					return candidata
	return Vector2i(59,76) if escuela.campana.lugar == "campus" else Vector2i(204,41)

func despertar() -> void:
	if escuela.campana.gracia_activa(): return
	if activo:
		return
	activo = true
	estado = "PATRULLANDO"
	show()
	sprite.modulate.a = 0
	create_tween().tween_property(sprite, "modulate:a", 1.0, 1.6)
	escuela.anunciar("HA APARECIDO EL ARCHIVERO", "No busca tu rostro. Escucha tus pasos.")
	escuela.sonidos.efecto("aviso")

func escuchar(posicion: Vector2, intensidad: float) -> void:
	if escuela.campana.gracia_activa() or intensidad <= 0: return
	# El gafete lo distrae y los puntos seguros no transmiten ruido.
	if ignorar > 0.0 or escuela.en_punto_seguro(posicion): return
	if not activo:
		if intensidad >= 0.7 and escuela.tiempo > 8:
			despertar()
		else:
			return
	if global_position.distance_to(posicion) > 180.0 + intensidad * 1100.0:
		return
	if estado != "INVESTIGANDO":
		reaccion = 0.55
		detectar()
	destino = posicion
	memoria = 10.0
	espera = 0
	estado = "INVESTIGANDO"
	recalcular = 0

func detectar() -> void:
	# GDD: cada vez que el Archivero detecta a Lalo cerca, su cordura baja.
	var jugador: CharacterBody2D = escuela.jugador
	if global_position.distance_to(jugador.global_position) > 520.0:
		return
	jugador.cordura = maxf(0.0, jugador.cordura - 3.0)
	if is_instance_valid(escuela.mente):
		escuela.mente.presenciar(6.0)
	if voz_espera <= 0.0 and is_instance_valid(escuela.relato):
		voz_espera = 28.0
		escuela.relato.voz_archivero()
		escuela.sonidos.efecto("susurro", global_position, -12)

func _physics_process(delta: float) -> void:
	voz_espera = maxf(0.0, voz_espera - delta)
	ignorar = maxf(0.0, ignorar - delta)
	sprite.self_modulate.a = 0.55 if ignorar > 0.0 else 1.0
	if escuela.campana.gracia_activa():
		activo = false
		velocity = Vector2.ZERO
		hide()
		return
	if not escuela.jugando or not activo or not lista:
		return
	if repelido > 0:
		repelido=maxf(0,repelido-delta)
		velocity=Vector2.ZERO
		Animacion.mover(sprite,velocity)
		return
	vision_reloj -= delta
	if vision_reloj <= 0:
		vision_reloj = 0.2
		ver_linterna()
		seguir_de_cerca()
	comprobar_captura()
	if reaccion > 0:
		reaccion = maxf(0,reaccion-delta)
		velocity = Vector2.ZERO
		sprite.pause()
		return
	if not escuela.jugando:
		return
	memoria = maxf(0, memoria - delta)
	if memoria <= 0 and estado == "INVESTIGANDO":
		if revisando or not buscar_escondite():
			estado = "BUSCANDO"
			espera = 2.8 if revisando else 2.5
			if revisando:
				escuela.jugador.mensaje = "Está junto a tu escondite. No te muevas… contén la respiración."
				escuela.sonidos.efecto("susurro", global_position, -14)
	if estado == "BUSCANDO":
		espera -= delta
		velocity = Vector2.ZERO
		Animacion.mover(sprite, velocity)
		# Se queda quieto y ladea la cabeza: está escuchando.
		sprite.rotation = sin(escuela.tiempo * 2.2) * 0.06
		var j: CharacterBody2D = escuela.jugador
		if revisando and j.oculto and global_position.distance_to(j.global_position) < 110.0:
			j.sigilo = maxf(0.0, j.sigilo - 14.0 * delta)
			if j.sigilo <= 0.0:
				revisando = false
				escuela.archivar()
				return
		if espera <= 0:
			volver_patrulla()
		return
	sprite.rotation = lerpf(sprite.rotation, 0.0, 0.2)
	if global_position.distance_to(destino) < (70.0 if revisando else 35.0):
		if estado == "INVESTIGANDO":
			memoria = 0
		else:
			punto = (punto + 1) % puntos.size()
			destino = puntos[punto]
	recalcular -= delta
	if recalcular <= 0:
		recalcular = 0.65
		camino = rejilla.get_point_path(celda_libre(global_position), celda_libre(destino))
		if camino.size() > 1:
			camino.remove_at(0)
	if camino.size() > 0 and global_position.distance_to(camino[0]) < 4:
		camino.remove_at(0)
	velocity = global_position.direction_to(camino[0]) * (velocidad_busqueda * (1.12 if persiguiendo else 1.0) if estado == "INVESTIGANDO" else velocidad_patrulla) if camino.size() > 0 else Vector2.ZERO
	for objeto in get_tree().get_nodes_in_group("interactivos"):
		if objeto.tipo == "puerta" and objeto.is_visible_in_tree() and not objeto.abierto and global_position.distance_to(objeto.global_position) < 60.0:
			objeto.abrir_archivero()
	if camino.size()>0: velocity=velocity.limit_length(global_position.distance_to(camino[0])/maxf(delta,.001))
	move_and_slide()
	atascado = atascado + delta if get_real_velocity().length() < 3 else 0.0
	if atascado > 1.6:
		volver_patrulla()
	Animacion.mover(sprite, get_real_velocity(), estado == "INVESTIGANDO")
	paso -= delta
	if velocity.length() > 2 and paso <= 0:
		paso = 0.36 if estado == "INVESTIGANDO" else 0.62
		escuela.sonidos.efecto("paso_archivero", global_position, -8)

func seguir_de_cerca() -> void:
	# No ve rostros, pero de cerca oye pasos y respiración: si Lalo hace ruido o lleva
	# la linterna a menos de 150 px y a la vista, persigue su posición actual.
	persiguiendo = false
	if estado != "INVESTIGANDO" or revisando:
		return
	var j: CharacterBody2D = escuela.jugador
	if j.oculto or (j.ruido <= 0.0 and not j.linterna):
		return
	if global_position.distance_to(j.global_position) > 150.0:
		return
	var rayo := PhysicsRayQueryParameters2D.create(global_position, j.global_position, 1, [get_rid(), j.get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
		return
	persiguiendo = true
	destino = j.global_position
	memoria = maxf(memoria, 2.5)
	recalcular = minf(recalcular, 0.2)

func buscar_escondite() -> bool:
	# Si pierde a Lalo junto a su escondite, se acerca a revisarlo (una vez cada 25 s por escondite).
	var j: CharacterBody2D = escuela.jugador
	if not j.oculto or not is_instance_valid(j.ultimo_escondite):
		return false
	var escondite: Node2D = j.ultimo_escondite
	if global_position.distance_to(escondite.global_position) > 240.0:
		return false
	var id: int = escondite.get_instance_id()
	if escuela.tiempo - float(revisados.get(id, -100.0)) < 25.0:
		return false
	revisados[id] = escuela.tiempo
	revisando = true
	destino = escondite.global_position
	memoria = 6.0
	recalcular = 0
	return true

func comprobar_captura() -> void:
	var jugador: CharacterBody2D = escuela.jugador
	if ignorar > 0.0 or escuela.en_punto_seguro(jugador.global_position): return
	if not jugador.protegido_en_refugio() and global_position.distance_to(jugador.global_position) < 30:
		var consulta := PhysicsRayQueryParameters2D.create(global_position, jugador.global_position, 1, [get_rid(), jugador.get_rid()])
		if get_world_2d().direct_space_state.intersect_ray(consulta).is_empty():
			escuela.archivar()

func volver_patrulla() -> void:
	# Elegir una salida alcanzable y distante del último ruido, sin consultar a Lalo.
	var anterior := destino
	var mejor := -INF
	var elegido := -1
	for i in range(puntos.size()):
		var ruta := rejilla.get_point_path(celda_libre(global_position),celda_libre(puntos[i]))
		if ruta.size()<2:continue
		var valor: float = puntos[i].distance_to(anterior)
		if valor > mejor:mejor=valor;elegido=i
	memoria=0;espera=0;atascado=0;recalcular=0
	revisando=false;persiguiendo=false;sprite.rotation=0.0
	estado="PATRULLANDO"
	if elegido>=0:
		punto=elegido;destino=puntos[punto]
	else:
		# Si se movieron muebles, reconstruir una sola vez al detectar bloqueo.
		escuela.rutas_pendientes=true
		punto=(punto+1)%puntos.size();destino=puntos[punto]
	camino.clear()

func ver_linterna() -> void:
	var j: CharacterBody2D = escuela.jugador
	if j.oculto or not j.linterna or escuela.campana.bateria <= 0: return
	var diferencia: Vector2 = global_position-j.global_position
	if diferencia.length()>430 or j.apuntado.dot(diferencia.normalized())<0.72: return
	var ray := PhysicsRayQueryParameters2D.create(global_position,j.global_position,1,[get_rid(),j.get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): return
	if estado != "INVESTIGANDO": escuela.jugador.mensaje = "El Archivero vio el haz. Apaga la linterna y cambia de pasillo."
	escuchar(j.global_position,0.8)
