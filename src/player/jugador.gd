extends CharacterBody2D

const Animacion = preload("res://src/player/animacion_personaje.gd")
var inventario: Array[String] = []
var oculto: bool = false
var linterna: bool = true
var ruido: float = 0.0
var ultimo_escondite: Node2D
var mensaje: String = "Busca la llave en Dirección. El tablero de Entrada alimenta una sola zona."
var energia: float = 100.0
var cordura: float = 100.0
var paso: float = 0.0
var apuntado := Vector2.RIGHT
var sprite: AnimatedSprite2D
var mano: Vector2 = Vector2(0, -34)
var huella_tiempo: float = 0.0
var agachado: bool = false
var accion: String = ""
var avance_accion: float = 0.0
var duracion_accion: float = 1.0
var desplazamiento: Vector2 = Vector2.ZERO
var bloqueo_entrada: float = 0.0
var direccion_animacion: String = "down"
var golpe_anterior: int = -1
var luz_personal: PointLight2D
var sigilo: float = 100.0
var sigilo_agotado: bool = false
var descanso_sigilo: float = 0.0
var jadeo: float = 0.0
var carrera_agotada := false
var refugio_aceptado := false
var distancia_animada := 0.0
var cuadro_previo := -1
## Segunda capa del sprite: muestra el cuadro siguiente al final de cada paso (fundido entre cuadros).
var mezcla: AnimatedSprite2D
const CONSUMO_SIGILO := 5.0
@onready var escuela: Node2D = get_parent()

func _ready() -> void:
	$Sprite.hide()
	sprite = Animacion.crear("lalo")
	add_child(sprite)
	mezcla = AnimatedSprite2D.new()
	mezcla.sprite_frames = sprite.sprite_frames
	mezcla.texture_filter = sprite.texture_filter
	mezcla.modulate.a = 0.0
	add_child(mezcla)
	vestir(Controles.atuendo)
	# Un solo reloj de animación, actualizado junto con la física.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	safe_margin = 0.08
	max_slides = 8
	var pies := CircleShape2D.new()
	pies.radius = 9.0
	$Colision.shape = pies
	$Linterna.texture_scale = 1.0
	$Linterna.offset = Vector2(256,0)
	$Linterna.energy = 1.05
	$Linterna.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	$Linterna.position = mano
	$Camera2D.zoom = Vector2(1.3, 1.3)
	var escucha := AudioListener2D.new()
	add_child(escucha)
	get_viewport().audio_listener_enable_2d = true
	escucha.make_current()
	add_child(preload("res://src/player/equipo_lalo.gd").new())
	# Un brillo cercano permite reconocer la silueta sin revelar habitaciones.
	var gradiente := Gradient.new()
	gradiente.colors = PackedColorArray([Color(0.65,0.75,1,0.45), Color(0,0,0,0)])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 192
	textura.height = 192
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5,0.5)
	textura.fill_to = Vector2(1,0.5)
	var cercania := PointLight2D.new()
	luz_personal = cercania
	cercania.texture = textura
	cercania.energy = 0.38
	cercania.position = Vector2(0,-30)
	cercania.shadow_enabled = true
	add_child(cercania)

func _physics_process(delta: float) -> void:
	if not escuela.jugando:
		$Camera2D.offset = Vector2.ZERO
		velocity = Vector2.ZERO
		sprite.pause()
		return
	bloqueo_entrada = maxf(0, bloqueo_entrada - delta)
	actualizar_sigilo(delta)
	luz_personal.enabled = not oculto
	luz_personal.position = sprite.position + Vector2(0,-30)
	luz_personal.energy = 1.1 if accion == "excavar" else 0.38
	if accion != "":
		procesar_accion(delta)
		return
	if bloqueo_entrada <= 0 and Input.is_action_just_pressed("agacharse") and not oculto:
		if sigilo_agotado and not agachado:
			mensaje = "Sin aliento. Recupera al menos 35% de sigilo antes de agacharte."
		else:
			agachado = not agachado
			mensaje = "Agachado: reserva limitada. Vigila el medidor de sigilo." if agachado else "De pie. Recuperando el aliento."
	var entrada := Input.get_vector("izquierda", "derecha", "arriba", "abajo", 0.38)
	if is_instance_valid(escuela.mente) and escuela.mente.inversion > 0: entrada = -entrada
	if energia <= 2: carrera_agotada = true
	if energia >= 25 or not Input.is_action_pressed("correr"): carrera_agotada = false
	var correr := Input.is_action_pressed("correr") and not carrera_agotada and energia > 2.0 and entrada.length() > 0 and not oculto and not agachado
	energia = clampf(energia + ((-15.0 if escuela.campana.refresco > 0 else -24.0) if correr else 11.0) * delta, 0, 100)
	var direccion_entrada := entrada.normalized() if correr else entrada
	var velocidad_objetivo := direccion_entrada * (54.0 if agachado else (205.0 if correr else 112.0)) if not oculto and bloqueo_entrada <= 0 else Vector2.ZERO
	# Arranque y frenado breves: Lalo se siente con peso sin perder respuesta.
	velocity = velocity.move_toward(velocidad_objetivo, (1500.0 if velocidad_objetivo.length() > velocity.length() else 2200.0) * delta)
	move_and_slide()
	var movimiento := get_real_velocity()
	distancia_animada += movimiento.length() * delta
	ruido = (1.0 if correr else 0.18) if movimiento.length() > 3 and not agachado else 0.0
	if escuela.campana.refresco > 0: ruido *= 0.65
	sprite.modulate.a = 0.0 if oculto else 1.0
	$Linterna.enabled = linterna and not oculto
	if Controles.usando_mando and Controles.mando >= 0:
		var palanca := Vector2(Input.get_joy_axis(Controles.mando, JOY_AXIS_RIGHT_X), Input.get_joy_axis(Controles.mando, JOY_AXIS_RIGHT_Y))
		if palanca.length() > 0.34:
			apuntado = palanca.normalized()
		elif movimiento.length() > 3:
			apuntado = movimiento.normalized()
	elif (get_global_mouse_position() - global_position - mano).length() > 8:
		apuntado = (get_global_mouse_position() - global_position - mano).normalized()
	animar_movimiento(movimiento, correr)
	# El cuerpo usa los pies como origen. La luz sale de la mano, a altura del torso.
	mano = Vector2(0, -23 if agachado else -34)
	if linterna and not agachado:
		var manos := {"right": Vector2(25,-34), "left": Vector2(-25,-34), "down": Vector2(-7,-26), "up": Vector2(20,-36)}
		mano = manos[direccion_animacion]
	$Linterna.position = mano + apuntado * (5.0 if not agachado else 16.0)
	# No colocar la fuente al otro lado de una pared pegada a la mano.
	var rayo_luz := PhysicsRayQueryParameters2D.create(global_position + Vector2(0,-12), to_global($Linterna.position), 1, [get_rid()])
	var choque_luz := get_world_2d().direct_space_state.intersect_ray(rayo_luz)
	if not choque_luz.is_empty(): $Linterna.global_position = choque_luz.position - apuntado * 3
	var balanceo: float = sin(distancia_animada / 46.0 * PI) * 0.018 if movimiento.length() > 3 else sin(escuela.tiempo*1.7)*0.006
	$Linterna.rotation = apuntado.angle() + balanceo
	$Linterna.energy = lerpf(0.76,1.12,clampf(escuela.campana.bateria/25.0,0,1))
	if escuela.campana.bateria < 20 and sin(escuela.tiempo * 19.0) * sin(escuela.tiempo * 7.3) > 0.48:
		$Linterna.energy *= 0.3
	# La linterna falla cuando el Archivero está cerca.
	if escuela.peligro > 0.3 and randf() < escuela.peligro * 0.2:
		$Linterna.energy *= randf_range(0.2, 0.65)
	paso -= movimiento.length() * delta
	if movimiento.length() < 3: paso = minf(paso, 8)
	if ruido > 0 and paso <= 0:
		paso = 54.0 if correr else 46.0
		escuela.sonidos.efecto(sonido_paso(), Vector2.INF, -7 if correr else -11)
		escuela.emitir_ruido(global_position, ruido)
		if is_instance_valid(escuela.atmosfera) and (correr or escuela.campana.lugar == "campus"):
			escuela.atmosfera.pisada(global_position, correr)
	if bloqueo_entrada > 0: return
	if Input.is_action_just_pressed("linterna"):
		linterna = not linterna and escuela.campana.bateria > 0
		escuela.sonidos.efecto("linterna")
	if Input.is_action_just_pressed("distraer"):
		distraer()
	if Input.is_action_just_pressed("interactuar"):
		var objetivo: Node2D = ultimo_escondite if oculto else mas_cercano()
		if is_instance_valid(objetivo):
			mensaje = objetivo.interactuar(self)
			if oculto:
				ultimo_escondite = objetivo

func animar_movimiento(movimiento: Vector2, correr: bool) -> void:
	if movimiento.length() > 3:
		var horizontal: String = "right" if movimiento.x > 0 else "left"
		var vertical: String = "down" if movimiento.y > 0 else "up"
		if direccion_animacion not in [horizontal, vertical]:
			direccion_animacion = horizontal if absf(movimiento.x) >= absf(movimiento.y) else vertical
		# Histéresis: una diagonal no alterna los cuadros por pequeñas variaciones.
		if absf(movimiento.x) > absf(movimiento.y) * 1.12:
			direccion_animacion = "right" if movimiento.x > 0 else "left"
		elif absf(movimiento.y) > absf(movimiento.x) * 1.12:
			direccion_animacion = "down" if movimiento.y > 0 else "up"
	if linterna and not agachado and accion == "" and movimiento.length() < 3:
		direccion_animacion = ("right" if apuntado.x > 0 else "left") if absf(apuntado.x) > absf(apuntado.y) else ("down" if apuntado.y > 0 else "up")
	var anim: String = "crouch_" + ("right" if direccion_animacion == "left" else direccion_animacion) if agachado else direccion_animacion
	if linterna and not agachado: anim = "torch_" + direccion_animacion
	sprite.flip_h = agachado and direccion_animacion == "left"
	var escala_objetivo := Vector2.ONE * (0.19 if agachado else (0.25 if linterna else 0.26))
	sprite.scale = sprite.scale.lerp(escala_objetivo,clampf(get_physics_process_delta_time()*18,0,1))
	sprite.offset = Vector2(0, -160 if agachado or linterna else -135)
	sprite.position = Vector2.ZERO
	if movimiento.length() < 3 and not oculto:
		# Respiración: el pecho sube y baja (escala), más rápido si está jadeando.
		var respiro: float = sin(escuela.tiempo * (8.0 if jadeo > 0 else 2.4)) * (0.03 if jadeo > 0 else 0.012)
		sprite.scale.y *= 1.0 + respiro
		sprite.position.y = minf(0.0, respiro * 20.0)
	sprite.speed_scale = clampf(movimiento.length() / (54.0 if agachado else 112.0), 0.45, 1.65)
	if sprite.animation != anim: sprite.animation = anim
	sprite.pause()
	sprite.skew = 0.0
	var mezcla_alfa := 0.0
	if movimiento.length() > 3 and not oculto:
		var zancada := 44.0 if agachado else (86.0 if correr else 72.0)
		var fase := fposmod(distancia_animada / zancada, 1.0)
		var cuadros := sprite.sprite_frames.get_frame_count(anim)
		var avance: float = fase * cuadros
		var cuadro := mini(int(avance), cuadros - 1)
		# Apoyo del pie: compresión mínima en los cuadros de contacto.
		if cuadro != cuadro_previo and cuadro % 2 == 0:
			sprite.scale.y *= 0.975 if not correr else 0.955
		cuadro_previo = cuadro
		sprite.set_frame_and_progress(cuadro, 0)
		# Rebote de cadera y balanceo leve hacia donde avanza (rotación, sin deformar el pixel art).
		sprite.position.y = -absf(sin(fase * TAU)) * (2.2 if correr else 0.9)
		var inclinacion: float = clampf(movimiento.x / 205.0, -1.0, 1.0) * (0.05 if correr else 0.02)
		sprite.rotation = lerpf(sprite.rotation, inclinacion + sin(fase * TAU) * (0.02 if correr else 0.008), 0.35)
		# Fundido al cuadro siguiente en el último tramo de cada paso.
		mezcla_alfa = smoothstep(0.55, 1.0, avance - cuadro) * 0.55
		mezcla.animation = anim
		mezcla.frame = (cuadro + 1) % cuadros
	else:
		sprite.frame = 0
		cuadro_previo = -1
		sprite.rotation = lerpf(sprite.rotation,0,0.25)
	copiar_mezcla(mezcla_alfa)

func vestir(indice: int) -> void:
	# Atuendo cosmético: el mismo material para el sprite y su capa de fundido.
	sprite.material = preload("res://src/player/atuendo.gd").material(indice)
	mezcla.material = sprite.material

func copiar_mezcla(alfa: float) -> void:
	if not is_instance_valid(mezcla):
		return
	mezcla.visible = alfa > 0.01 and sprite.modulate.a > 0.5
	if not mezcla.visible:
		return
	mezcla.pause()
	mezcla.position = sprite.position
	mezcla.scale = sprite.scale
	mezcla.offset = sprite.offset
	mezcla.rotation = sprite.rotation
	mezcla.flip_h = sprite.flip_h
	mezcla.modulate.a = alfa

func actualizar_sigilo(delta: float) -> void:
	jadeo=maxf(0,jadeo-delta)
	if agachado and not oculto:
		sigilo=maxf(0,sigilo-delta*CONSUMO_SIGILO)
		if sigilo<=0:
			agachado=false;sigilo_agotado=true;descanso_sigilo=2.5;jadeo=1.5
			escuela.sonidos.efecto("jadeo",Vector2.INF,-12)
			escuela.emitir_ruido(global_position,.85)
			Controles.vibrar(.25,.15)
			mensaje="Te quedaste sin aliento. ¡El jadeo puede delatarte!"
	else:
		var recuperacion: float=maxf(0,delta-descanso_sigilo)
		descanso_sigilo=maxf(0,descanso_sigilo-delta)
		sigilo=minf(100,sigilo+recuperacion*(3.0 if oculto else 7.0))
		if sigilo>=35:sigilo_agotado=false

func esconder(objeto: Node2D) -> void:
	if accion != "": return
	ultimo_escondite = objeto
	refugio_aceptado = not oculto and (not escuela.archivero.activo or global_position.distance_to(escuela.archivero.global_position) >= 30)
	accion = "salir" if oculto else "entrar"
	avance_accion = 0
	duracion_accion = (0.5 if "Casillero" in objeto.titulo else 0.7) if not oculto else 0.4
	desplazamiento = (objeto.global_position - global_position).limit_length(50)
	velocity = Vector2.ZERO
	ruido = 0
	$Linterna.enabled = false
	escuela.sonidos.efecto("papel", Vector2.INF, -12)
	if accion == "entrar": escuela.emitir_ruido(global_position, 0.12)

func excavar(punto: Node2D) -> void:
	if accion != "" or oculto: return
	accion = "excavar"
	avance_accion = 0
	duracion_accion = 3.0
	golpe_anterior = -1
	if is_instance_valid(punto): apuntado = (punto.global_position-global_position).normalized()
	velocity = Vector2.ZERO
	ruido = 0
	$Linterna.enabled = false

func procesar_accion(delta: float) -> void:
	sprite.pause()
	velocity = Vector2.ZERO
	ruido = 0
	avance_accion += delta
	sprite.skew = 0.0
	copiar_mezcla(0.0)
	var t: float = clampf(avance_accion / duracion_accion,0,1)
	sprite.scale = Vector2.ONE * 0.20
	sprite.offset = Vector2(0,-160)
	sprite.speed_scale = 1.0
	if accion == "excavar":
		var vertical: bool = absf(apuntado.y) > absf(apuntado.x)
		sprite.flip_h = not vertical and apuntado.x < 0
		sprite.animation = ("dig_down" if apuntado.y > 0 else "dig_up") if vertical else "dig"
		sprite.frame = int(avance_accion * 5) % 4 if vertical else int(avance_accion * 3) % 2
		if not vertical: sprite.offset.x = 16 if sprite.frame == 0 else 70
		sprite.modulate.a = 1
		sprite.position.y = -sin(t * PI * 6.0) * 2.0
		sprite.rotation = sin(t * PI * 6.0) * 0.04
		var golpe: int = int(avance_accion * 1.5)
		if golpe != golpe_anterior:
			golpe_anterior = golpe
			escuela.sonidos.efecto("paso_exterior", Vector2.INF, -5)
			escuela.emitir_ruido(global_position, 0.8)
		mensaje = "EXCAVANDO  %d%%  ·  La tierra se mueve…" % int(t*100)
	else:
		var entrada: bool = accion == "entrar"
		var fase: float = t if entrada else 1-t
		var casillero: bool = is_instance_valid(ultimo_escondite) and "Casillero" in ultimo_escondite.titulo
		if casillero:
			ultimo_escondite.animar_escondite(sin(t * PI))
			sprite.scale = Vector2.ONE * 0.26
			sprite.offset = Vector2(0,-135)
			sprite.animation = "up" if desplazamiento.y < 0 else "down"
			sprite.flip_h = false
			sprite.frame = int(avance_accion * 7) % 4
		else:
			var vertical: bool = absf(desplazamiento.y) > absf(desplazamiento.x)
			sprite.animation = ("crawl_down" if desplazamiento.y > 0 else "crawl_up") if vertical else "crawl"
			sprite.flip_h = not vertical and desplazamiento.x < 0
			sprite.frame = int(avance_accion * 5) % (4 if vertical else 2)
		sprite.position = desplazamiento * fase
		sprite.modulate.a = 1.0 - smoothstep(0.45,1.0,fase)
		if not entrada: oculto = false
	if t >= 1:
		if accion == "excavar":
			mensaje = escuela.campana.completar("memoria_desenterrada", "¡Una memoria USB! Pulsa interactuar junto al hoyo para recogerla y llevarla a la Prefecta.")
		else:
			oculto = accion == "entrar"
			mensaje = "Oculto. %s para salir." % Controles.boton_interaccion() if oculto else "Saliste del escondite."
		$Linterna.enabled = linterna and not oculto
		luz_personal.enabled = not oculto
		accion = ""
		bloqueo_entrada = 0.15
		sprite.position = Vector2.ZERO
		animar_movimiento(Vector2.ZERO,false)
		sprite.modulate.a = 0 if oculto else 1

func cancelar_accion() -> void:
	if is_instance_valid(ultimo_escondite): ultimo_escondite.animar_escondite(0)
	accion = ""
	refugio_aceptado = false
	oculto = false
	sprite.position = Vector2.ZERO
	sprite.modulate.a = 1
	velocity = Vector2.ZERO

func distraer() -> void:
	if oculto:
		return
	if not inventario.has("Grapadora"):
		mensaje = "Necesitas recoger una grapadora para hacer ruido a distancia."
		return
	inventario.erase("Grapadora")
	var destino := global_position + apuntado * 260.0
	var consulta := PhysicsRayQueryParameters2D.create(global_position, destino, 1, [get_rid()])
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	if not impacto.is_empty():
		destino = impacto.position - apuntado * 20.0
	escuela.sonidos.efecto("sello", destino, -10)
	escuela.emitir_ruido(destino, 1.6)
	mensaje = "La grapadora golpeó el suelo. Aléjate en silencio."

func mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var distancia: float = 82.0
	for candidato in get_tree().get_nodes_in_group("interactivos"):
		if candidato.is_queued_for_deletion() or not candidato.is_visible_in_tree() or not candidato.can_process():
			continue
		var d: float = global_position.distance_to(candidato.global_position)
		if d >= distancia:
			continue
		var consulta := PhysicsRayQueryParameters2D.create(global_position, candidato.global_position, 1, [get_rid()])
		var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
		if not impacto.is_empty() and impacto.collider != candidato:
			continue
		distancia = d
		mejor = candidato
	return mejor

func sonido_paso() -> String:
	if AudioManager.zona(escuela) == "banos": return "paso_baldosa"
	if escuela.campana.lugar != "campus": return "paso"
	for piso in escuela.campana.exterior.get_children():
		if piso is Sprite2D and piso.region_enabled and piso.texture:
			var archivo: String = piso.texture.resource_path
			if "concreto" in archivo or "azulejo" in archivo or "asfalto" in archivo:
				if Rect2(piso.global_position,piso.region_rect.size*piso.scale).has_point(global_position): return "paso"
	return "paso_exterior"

func protegido_en_refugio() -> bool:
	return oculto or (accion == "entrar" and refugio_aceptado)
