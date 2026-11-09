extends Node2D

const Geo = preload("res://src/world/geometria_campus.gd")
const Guardado = preload("res://src/core/guardado.gd")
var estado: int = 2
var mapa: bool = false
var zonas: Dictionary = {}
var jugando: bool = false
var partida_iniciada: bool = false
var tiempo: float = 0.0
var latido: float = 0.0
var recogidos: Array[String] = []
var archivero: CharacterBody2D
var resonancia: Node2D
var sonidos: Node
var interfaz: CanvasLayer
var transicion: bool = false
var rutas_pendientes: bool = false
var peligro: float = 0.0
var oscuridad: ColorRect
var destino_salida: String = "salir"
var autoguardado: float = 0.0
var campana: Node
var gatillos_mapa: Dictionary = {}
var mente: Node
var inventario_ui: CanvasLayer
var relato: Node
var susto_disponible: bool = true
var susto_espera: float = 0.0
var motivo_fin: String = "archivado"
var cercano_actual: Node2D
var atmosfera: Node2D
var susto_zoom: Tween
const ZOOM_JUEGO := Vector2(1.3, 1.3)
const INTRO: Array[String] = [
	"Última semana del cuatrimestre. Entregas finales, firma de actas, cierre de calificaciones.",
	"Lalo llevaba tres noches sin dormir. Solo le faltaba un trámite en Dirección.",
	"Se sentó a esperar en la recepción. Cerró los ojos un momento.",
	"00:00 · El reloj de pared se detuvo. Las luces del pasillo se apagaron una por una.",
	"Después de las doce, el campus entra en Turno Nocturno.\nQuien sigue adentro no sale hasta cerrar su turno.",
	"Y en los archiveros, algo ya empezó a pasar lista.",
]
const FINAL_ESCAPE: Array[String] = [
	"Don Chuy sella el reporte. La pluma sube con un chirrido largo.",
	"Lalo cruza. Detrás de él, el campus se queda en silencio.",
	"Amanece. El cielo ya no es rojo.",
	"Sigue siendo el mismo estudiante agotado, con la mochila llena de pendientes.",
	"En la caseta, Don Chuy abre la bitácora y escribe: «Noche 2,191: sin novedades».",
	"Mañana a las 00:00, alguien volverá a quedarse dormido en Dirección.\n¿Algo va a cambiar?",
]
const FINAL_LIBERACION: Array[String] = [
	"Don Chuy mira el Sello Roto y asiente. «Léelos en voz alta.»",
	"Lalo pronuncia los nombres que el Archivero había borrado. Uno por uno.",
	"La de Cómputo. El de Talleres. La Prefecta. Los que nadie volvió a nombrar.",
	"Los Ecos cruzan la pluma con él. Esta vez nadie se queda en turno.",
	"Amanece. En el archivo, los expedientes cambian de BAJA a EGRESADO.",
	"Por primera vez en seis años, Don Chuy escribe otra cosa en su bitácora: «Turno cerrado».",
]
const FINAL_ECO: Array[String] = [
	"Tus pasos ya no suenan como tuyos.",
	"Intentas decir tu nombre y solo sale tu matrícula.",
	"El Archivero no necesitó alcanzarte. La presión hizo el trabajo.",
	"EXPEDIENTE CERRADO · MOTIVO: ABANDONO",
]
@onready var jugador: CharacterBody2D = $Jugador

func _ready() -> void:
	add_to_group("control")
	campana = preload("res://src/story/campana.gd").new()
	add_child(campana)
	add_child(preload("res://scenes/detalles_principal.tscn").instantiate())
	preload("res://src/world/pared_v12.gd").renovar($Paredes)
	add_child(preload("res://src/world/mobiliario_aulas.gd").new())
	preload("res://src/world/acabados.gd").desgastar_suelos($Pisos, 1.0)
	preload("res://src/world/acabados.gd").sombras_muebles($Objetos)
	Guardado.configurar()
	get_tree().auto_accept_quit = false
	$Interfaz.hide()
	for objeto in $Objetos.get_children():
		# La alumna tiene ahora un punto interactivo de campaña, sin duplicar su imagen.
		if objeto.name.begins_with("eco_"):
			objeto.hide()
		if objeto.titulo == "Salida":
			objeto.tipo = "salida"
			objeto.add_to_group("interactivos")
		if objeto.has_signal("ruido_emitido"):
			objeto.ruido_emitido.connect(emitir_ruido)
		if objeto.has_signal("recogido"):
			objeto.recogido.connect(al_recoger)
	for monitor in get_tree().get_nodes_in_group("parpadeo"):
		monitor.set_meta("zona","Computo")
		monitor.add_to_group("luces_zona")
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		zonas[luz.get_meta("zona")] = true
		luz.set_meta("energia_base", luz.energy)
	modo_luz(2)
	sonidos = preload("res://src/audio/sonidos.gd").new()
	add_child(sonidos)
	archivero = preload("res://src/enemies/archivero.gd").new()
	add_child(archivero)
	atmosfera = preload("res://src/world/atmosfera.gd").new()
	add_child(atmosfera)
	add_child(preload("res://src/world/ambiente_lugares.gd").new())
	add_child(preload("res://src/story/documentos.gd").new())
	add_child(preload("res://src/ui/tutorial.gd").new())
	crear_puntos_seguros()
	add_child(preload("res://src/ui/indicador_interaccion.gd").new())
	crear_oscuridad()
	interfaz = preload("res://src/ui/interfaz.gd").new()
	interfaz.escuela = self
	add_child(interfaz)
	interfaz.mostrar("inicio")
	mente=preload("res://src/player/cordura.gd").new()
	add_child(mente)
	relato = preload("res://src/story/relato_turno.gd").new()
	add_child(relato)
	add_child(preload("res://src/world/director_terror.gd").new())
	add_child(preload("res://src/story/ecos_memoria.gd").new())
	resonancia = preload("res://src/world/archivo_resonante.gd").new()
	add_child(resonancia)
	var altavoz := preload("res://src/world/altavoz_escolar.gd").new()
	altavoz.name="AltavozEscolar"
	altavoz.position=Vector2(900,640)
	get_node("DetallesPrincipal").add_child(altavoz)
	await get_tree().physics_frame
	await get_tree().physics_frame
	archivero.construir_rutas()
	var entrada: String = get_tree().get_meta("entrada_turno", "inicio")
	get_tree().remove_meta("entrada_turno")
	if entrada == "nuevo":
		iniciar()
	elif entrada == "cargar":
		aplicar_guardado()

func crear_oscuridad() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	oscuridad = ColorRect.new()
	oscuridad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oscuridad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	# Viñeta que respira, grano de película, línea de interferencia y tinte por peligro y cordura.
	shader.code = """shader_type canvas_item;
uniform float peligro = 0.0;
uniform float cordura = 1.0;
void fragment(){
	vec2 p = UV - vec2(0.5);
	float respiro = 0.025*sin(TIME*0.9) + peligro*0.05*sin(TIME*6.0);
	float borde = smoothstep(0.20 - respiro, 0.69, length(p*vec2(1.0,1.1)));
	float grano = fract(sin(dot(floor(FRAGCOORD.xy*0.5) + floor(TIME*14.0), vec2(12.9898,78.233)))*43758.5453);
	float linea = smoothstep(0.995, 1.0, sin(UV.y*3.0 - TIME*0.6)) * (0.04 + peligro*0.12);
	float pulso = (0.5 + 0.5*sin(TIME*7.0))*peligro;
	float locura = 1.0 - cordura;
	vec3 tinte = vec3(0.13*pulso + 0.05*locura, 0.005, 0.015 + 0.025*locura);
	COLOR = vec4(tinte, clamp(borde*0.80 + pulso*0.10 + grano*(0.03 + locura*0.03) + linea, 0.0, 0.95));
}"""
	var material_oscuro := ShaderMaterial.new()
	material_oscuro.shader = shader
	oscuridad.material = material_oscuro
	capa.add_child(oscuridad)

func iniciar() -> void:
	if transicion or partida_iniciada:
		return
	transicion = true
	while not archivero.lista:
		await get_tree().process_frame
	interfaz.fondo.activar(false)
	# La introducción se muestra una vez por sesión; los reintentos empiezan directo.
	if not get_tree().has_meta("intro_vista"):
		get_tree().set_meta("intro_vista", true)
		await secuencia(INTRO)
	partida_iniciada = true
	interfaz.jugar()
	transicion = true
	anunciar("00:00  /  EL ÚLTIMO CUATRIMESTRE", "El campus entró en Turno Nocturno. Encuentra el radio y cierra tu turno.")
	sonidos.efecto("aviso", Vector2.INF, -16)
	jugador.get_node("Camera2D").zoom = Vector2(1.65, 1.65)
	var animacion := create_tween()
	animacion.tween_property(jugador.get_node("Camera2D"), "zoom", Vector2(1.3, 1.3), 3.0)
	await animacion.finished
	transicion = false
	jugando = true
	if not guardar_partida():
		anunciar("NO SE PUDO GUARDAR", "Revisa el permiso de escritura de la carpeta partidas.")

func continuar() -> void:
	if is_instance_valid(inventario_ui): inventario_ui.queue_free()
	inventario_ui=null
	jugador.bloqueo_entrada = 0.18
	interfaz.jugar()
	jugando = true

func pausar() -> void:
	jugando = false
	jugador.sprite.pause()
	archivero.sprite.pause()
	Controles.detener()
	interfaz.mostrar("pausa")

func abrir_tienda() -> void:
	if not jugando or transicion or jugador.accion != "": return
	jugando = false
	jugador.velocity = Vector2.ZERO
	jugador.sprite.pause()
	archivero.sprite.pause()
	interfaz.menu_actual = "tienda"
	inventario_ui = preload("res://src/ui/inventario.gd").new()
	inventario_ui.escuela = self
	inventario_ui.tienda = true
	add_child(inventario_ui)

func _input(evento: InputEvent) -> void:
	if interfaz == null or evento.is_echo(): return
	if evento.is_action_pressed("inventario"):
		if interfaz.menu_actual in ["inventario", "tienda"]: continuar()
		elif jugando and jugador.accion=="" and not transicion:
			jugando=false
			interfaz.menu_actual="inventario"
			inventario_ui=preload("res://src/ui/inventario.gd").new()
			inventario_ui.escuela=self
			add_child(inventario_ui)
		get_viewport().set_input_as_handled()
		return
	# Los gatillos emiten muchas muestras: una apertura por presión completa.
	if evento is InputEventJoypadMotion and evento.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var clave := "%d:%d" % [evento.device,evento.axis]
		var presionado: bool = evento.axis_value > 0.65
		var anterior: bool = gatillos_mapa.get(clave,false)
		gatillos_mapa[clave] = presionado
		if not presionado or anterior: return
	if evento.is_action_pressed("mapa") or evento.is_action_pressed("minimapa"):
		if partida_iniciada and not transicion and jugador.accion == "":
			if interfaz.menu_actual == "mapa": continuar()
			elif jugando: interfaz.mostrar_mapa()
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("ui_cancel"):
		if interfaz.menu_actual in ["dialogo", "mapa", "inventario", "tienda"]:
			continuar()
			get_viewport().set_input_as_handled()
			return
		if interfaz.menu_actual == "opciones":
			interfaz.mostrar("pausa" if partida_iniciada else "inicio")
			get_viewport().set_input_as_handled()
			return
	if evento.is_action_pressed("pausa") and partida_iniciada and not transicion:
		if jugando: pausar()
		elif interfaz.menu_actual in ["pausa","inventario","tienda"]: continuar()
		get_viewport().set_input_as_handled()

func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		salir()
	elif que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for accion in ["izquierda", "derecha", "arriba", "abajo", "correr", "interactuar"]:
			Input.action_release(accion)
		if jugando: pausar()

func _process(delta: float) -> void:
	if not jugando:
		return
	tiempo += delta
	autoguardado += delta
	if autoguardado > 30.0 and puede_guardar() and not jugador.oculto:
		autoguardado = 0
		jugador.mensaje = "Guardado automático en lugar seguro." if guardar_partida() else "No se pudo guardar. Intenta guardar con F5 desde un lugar seguro."
	if tiempo > 22 and not archivero.activo:
		archivero.despertar()
	if rutas_pendientes:
		rutas_pendientes = false
		await get_tree().physics_frame
		archivero.construir_rutas()
	var distancia: float = jugador.global_position.distance_to(archivero.global_position)
	susto_espera = maxf(0, susto_espera - delta)
	if distancia > 650: susto_disponible = true
	if archivero.activo and distancia < 390 and susto_disponible and susto_espera <= 0 and not jugador.oculto:
		susto_disponible = false
		susto_espera = 16
		sonidos.efecto("grito", archivero.position, -16)
		anunciar("ALGO SE ACERCA", "Escucha de qué lado vienen los pasos. Busca dónde ocultarte.")
		# GDD: cada susto desgasta la cordura.
		jugador.cordura = maxf(0.0, jugador.cordura - 4.0)
		sacudir_camara(0.12)
	peligro = clampf(1.0 - distancia / 480.0, 0, 1) if archivero.activo else 0.0
	oscuridad.material.set_shader_parameter("peligro", peligro)
	oscuridad.material.set_shader_parameter("cordura", clampf(jugador.cordura / 100.0, 0, 1))
	# Temblor por peligro y un vaivén lento de respiración, siempre presente.
	var respiracion := Vector2(sin(tiempo * 0.55), sin(tiempo * 0.8)) * 1.4
	jugador.get_node("Camera2D").offset = Vector2(sin(tiempo*29), sin(tiempo*37)) * peligro * peligro * 2.5 + respiracion
	# Cordura: -1 punto cada 10 segundos en cordura.gd; distorsión progresiva.
	latido -= delta
	if peligro > 0.12 and latido <= 0:
		latido = lerpf(1.4, 0.55, peligro)
		sonidos.efecto("latido", Vector2.INF, lerpf(-25, -9, peligro))
		Controles.vibrar(peligro * 0.55, 0.16)
	if Input.is_action_just_pressed("guardar"):
		guardar_manual()
	var objetivo: String = campana.objetivo()
	interfaz.hud.text = "TURNO NOCTURNO    /    %02d:%02d\n%s" % [int(tiempo / 60.0), int(tiempo) % 60, objetivo]
	interfaz.barras.text = "CORDURA %03d   /   RESISTENCIA %03d   /   RUIDO %s   /   OBJETOS %d" % [ceili(jugador.cordura), int(jugador.energia), "ALTO" if jugador.ruido > 0.5 else ("BAJO" if jugador.ruido > 0 else "SILENCIO"), jugador.inventario.size()]
	if campana.gracia_activa():
		interfaz.hud.text += "\nRECOLECTA Y EXPLORA · %02d s antes del Archivero" % ceili(campana.gracia_patio)
	interfaz.hud.modulate = Color("ffc4a8") if campana.gracia_activa() and campana.gracia_patio <= 10 else Color.WHITE
	interfaz.barras.text += "   /   MOCHILA %d/6" % preload("res://src/player/mochila.gd").usados(jugador.inventario)
	interfaz.barras.text += "   /   PILA %d%%   /   $%d" % [int(campana.bateria), campana.monedas]
	interfaz.barras.text += "\nSIGILO %d%% · %.1f s disponibles  /  CIRCUITO: %s"%[int(jugador.sigilo),jugador.sigilo/5.0,campana.alimentado.replace("_"," ") if campana.alimentado!="" else "NINGUNO"]
	if jugador.agachado: interfaz.barras.text += "  ·  AGACHADO"
	var cercano: Node2D = jugador.ultimo_escondite if jugador.oculto else jugador.mas_cercano()
	cercano_actual = cercano if is_instance_valid(cercano) else null
	var ayuda: String = "[%s] %s" % [Controles.boton_interaccion(), "Salir del escondite" if jugador.oculto else cercano.titulo] if is_instance_valid(cercano) else ""
	if jugador.accion != "": ayuda = ("EXCAVANDO" if jugador.accion == "excavar" else ("ENTRANDO AL ESCONDITE" if jugador.accion == "entrar" else "SALIENDO DEL ESCONDITE")) + " · %d%%" % int(100 * jugador.avance_accion / jugador.duracion_accion)
	# Los controles se recuerdan solo los primeros minutos; después la pantalla queda limpia.
	var controles: String = ("B / Círculo: sigilo · LT / RT: plano · Y: mochila · RB: distraer · Start: pausa" if Controles.usando_mando else "C / Ctrl: sigilo · V / Tab: plano · I: mochila · Esc: pausa") if tiempo < 150.0 else ""
	interfaz.ayuda.text = ayuda + "\n" + jugador.mensaje + "\n" + controles
	for luz in get_tree().get_nodes_in_group("parpadeo"):
		luz.enabled = zonas.get("Computo",false) and not campana.hechos.get("computo",false)
		luz.energy = float(luz.get_meta("energia_base", 0.5)) * (0.8 + 0.2 * sin(tiempo * 9.0))

func emitir_ruido(posicion: Vector2, intensidad: float) -> void:
	if jugando:
		if is_instance_valid(resonancia): resonancia.registrar(posicion,intensidad)
		archivero.escuchar(posicion, intensidad * (1.35 if campana.lugar == "campus" else 1.0))

func anunciar(titulo: String, detalle: String) -> void:
	interfaz.anunciar(titulo, detalle)

func crear_puntos_seguros() -> void:
	# Uno por nivel: sala de espera de Entrada, cafetería y caseta de Don Chuy.
	var PuntoSeguro = preload("res://src/world/punto_seguro.gd")
	var espera_entrada: Vector2 = Vector2(2112, 1120)
	for objeto in $Objetos.get_children():
		if objeto.get("titulo") == "Sofa de espera": espera_entrada = objeto.global_position + Vector2(0, 46)
	for dato in [["principal", "Sala de espera", "", espera_entrada], ["campus", "Cafetería", "tienda", Vector2(0, 70)], ["campus", "Caseta de Don Chuy", "guardia", Vector2(-40, 60)]]:
		var punto := PuntoSeguro.new() as Node2D
		punto.name = "PuntoSeguro_" + str(dato[1]).replace(" ", "_")
		punto.set("lugar", dato[0])
		punto.set("nombre_punto", dato[1])
		punto.set("ancla", dato[2])
		if dato[2] == "": punto.position = dato[3]
		else: punto.set("desplazamiento", dato[3])
		add_child(punto)

func en_punto_seguro(p: Vector2) -> bool:
	for punto in get_tree().get_nodes_in_group("puntos_seguros"):
		if punto.contiene(p):
			return true
	return false

func al_recoger(titulo: String) -> void:
	if is_instance_valid(relato):
		relato.objeto_recogido(titulo)

func secuencia(lineas: Array[String], amanecer: bool = false) -> void:
	# Las pruebas sin ventana no esperan secuencias de texto.
	if DisplayServer.get_name() == "headless":
		return
	var capa := preload("res://src/ui/secuencia_texto.gd").new()
	capa.lineas = lineas
	capa.amanecer = amanecer
	add_child(capa)
	await capa.terminada

func recuerdo_pausado(lineas: Array[String]) -> void:
	# Flashback: el turno se detiene mientras se cuenta el recuerdo.
	if not jugando or transicion:
		return
	jugando = false
	transicion = true
	await secuencia(lineas)
	transicion = false
	continuar()

func sacudir_camara(fuerza: float = 0.1) -> void:
	var camara: Camera2D = jugador.get_node("Camera2D")
	if susto_zoom:
		susto_zoom.kill()
	susto_zoom = create_tween()
	susto_zoom.tween_property(camara, "zoom", ZOOM_JUEGO * (1.0 + fuerza), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	susto_zoom.tween_property(camara, "zoom", ZOOM_JUEGO, 0.9).set_trans(Tween.TRANS_SINE)
	Controles.vibrar(0.6, 0.2)

func convertir_en_eco() -> void:
	# GDD: con la cordura en cero Lalo no muere; se convierte en un Eco.
	if not jugando:
		return
	jugando = false
	transicion = true
	motivo_fin = "eco"
	jugador.sprite.pause()
	archivero.sprite.pause()
	Controles.vibrar(0.5, 0.6)
	sonidos.efecto("susurro", Vector2.INF, -8)
	await secuencia(FINAL_ECO)
	transicion = false
	Controles.detener()
	interfaz.mostrar("muerte")

func archivar() -> void:
	if not jugando:
		return
	jugando = false
	transicion = true
	motivo_fin = "archivado"
	jugador.sprite.pause()
	archivero.sprite.pause()
	Controles.vibrar(0.75, 0.4)
	await interfaz.reproducir_muerte()
	transicion = false
	Controles.detener()
	interfaz.mostrar("muerte")

func ganar() -> void:
	if transicion:
		return
	jugando = false
	transicion = true
	Controles.detener()
	sonidos.efecto("recoger")
	await secuencia(FINAL_LIBERACION if campana.final_liberado else FINAL_ESCAPE, true)
	transicion = false
	interfaz.mostrar("victoria")
	# Recompensas permanentes: sudaderas nuevas en Opciones.
	var nuevas: Array[String] = []
	if Controles.desbloquear(1): nuevas.append("Guinda")
	if campana.final_liberado and Controles.desbloquear(2): nuevas.append("Verde UT")
	if not nuevas.is_empty():
		anunciar("RECOMPENSA DESBLOQUEADA", "Sudadera %s · elígela en Controles y opciones." % " y ".join(PackedStringArray(nuevas)))

func modo_luz(modo: int) -> void:
	estado = modo
	$Ambiente.color = Color(0.32, 0.37, 0.45) if modo == 0 else Color(0.045, 0.06, 0.09)
	for zona in zonas:
		zonas[zona] = zona == "Exterior_Caseta" or (modo != 1 and zona == "Entrada")
	campana.alimentado = "Entrada" if modo != 1 else ""
	actualizar_luces()

func alimentar_zona(zona: String) -> void:
	for z in zonas: zonas[z] = z == "Exterior_Caseta"
	if zona != "": zonas[zona] = true
	campana.alimentado=zona
	actualizar_luces()

func alternar_zona(zona: String) -> void:
	alimentar_zona("" if zonas.get(zona,false) else zona)

func alternar_general() -> void:
	campana.elegir_circuito()

func actualizar_luces() -> void:
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		luz.enabled = zonas.get(luz.get_meta("zona"), false)
	for lampara in get_tree().get_nodes_in_group("lamparas"):
		lampara.texture = load("res://assets/sprites/lampara_encendida.png" if zonas.get(lampara.get_meta("zona"), false) else "res://assets/sprites/lampara_apagada.png")

func puede_guardar() -> bool:
	return partida_iniciada and jugador.accion == "" and not transicion and (jugando or interfaz.menu_actual in ["pausa", "inventario", "tienda", "mapa"]) and (not archivero.activo or (jugador.global_position.distance_to(archivero.global_position) > 420 and archivero.estado != "INVESTIGANDO"))

func guardar_manual() -> void:
	if not puede_guardar():
		anunciar("NO ES UN LUGAR SEGURO", "Aléjate del Archivero y espera a que deje de investigar.")
		return
	var correcto := guardar_partida()
	anunciar("PARTIDA GUARDADA" if correcto else "NO SE PUDO GUARDAR", "Puedes continuar este turno desde el menú." if correcto else "Revisa el permiso de escritura de la carpeta partidas.")

func guardar_partida() -> bool:
	var objetos := {}
	for objeto in $Objetos.get_children():
		if objeto.is_queued_for_deletion():
			continue
		if objeto.tipo in ["puerta", "empujar"]:
			objetos[str(objeto.name)] = {"posicion": [objeto.position.x, objeto.position.y], "abierto": objeto.abierto}
	var datos := {"version": 1, "tiempo": tiempo, "estado_luz": estado, "zonas": zonas.duplicate(), "recogidos": recogidos.duplicate(), "objetos": objetos,
		"jugador": {"posicion": [jugador.position.x, jugador.position.y], "inventario": jugador.inventario.duplicate(), "energia": jugador.energia, "cordura": jugador.cordura, "linterna": jugador.linterna, "agachado": jugador.agachado, "sigilo": jugador.sigilo, "sigilo_agotado": jugador.sigilo_agotado, "descanso_sigilo": jugador.descanso_sigilo, "escondite": str(jugador.ultimo_escondite.name) if jugador.oculto and is_instance_valid(jugador.ultimo_escondite) else ""},
		"archivero": {"posicion": [archivero.position.x, archivero.position.y], "destino": [archivero.destino.x, archivero.destino.y], "activo": archivero.activo, "estado": archivero.estado, "memoria": archivero.memoria, "espera": archivero.espera}}
	datos["campana"] = campana.datos()
	return Guardado.guardar(datos)

func cargar() -> void:
	if Guardado.leer().is_empty():
		anunciar("NO HAY PARTIDA VÁLIDA", "Inicia un nuevo turno.")
		return
	reiniciar("cargar")

func reiniciar(entrada: String) -> void:
	Controles.detener()
	get_tree().set_meta("entrada_turno", entrada)
	get_tree().reload_current_scene()

func aplicar_guardado() -> void:
	var datos := Guardado.leer()
	if datos.is_empty():
		interfaz.mostrar("inicio")
		return
	tiempo = datos.tiempo
	estado = int(datos.get("estado_luz", 2))
	zonas.merge(datos.zonas, true)
	actualizar_luces()
	jugador.position = Vector2(datos.jugador.posicion[0], datos.jugador.posicion[1])
	jugador.inventario.assign(datos.jugador.inventario)
	jugador.energia = datos.jugador.energia
	# El punto seguro devuelve un mínimo de cordura para no reaparecer convertido en Eco.
	jugador.cordura = maxf(float(datos.jugador.cordura), 20.0)
	jugador.linterna = datos.jugador.linterna
	jugador.agachado = bool(datos.jugador.get("agachado",false))
	jugador.sigilo = float(datos.jugador.get("sigilo",100.0))
	jugador.sigilo_agotado = bool(datos.jugador.get("sigilo_agotado",false))
	jugador.descanso_sigilo = float(datos.jugador.get("descanso_sigilo",0.0))
	jugador.bloqueo_entrada = 0.18
	await campana.restaurar(datos.get("campana", {}))
	recogidos.assign(datos.recogidos)
	for objeto in $Objetos.get_children():
		if str(objeto.name) in recogidos:
			objeto.queue_free()
		elif datos.objetos.has(str(objeto.name)):
			var valor: Dictionary = datos.objetos[str(objeto.name)]
			objeto.position = Vector2(valor.posicion[0], valor.posicion[1])
			if objeto.tipo == "puerta":
				objeto.establecer_puerta(valor.abierto)
	var escondite := $Objetos.get_node_or_null(NodePath(str(datos.jugador.get("escondite", "")))) if not str(datos.jugador.get("escondite", "")).is_empty() else null
	if is_instance_valid(escondite) and escondite.tipo == "escondite":
		jugador.oculto = true
		jugador.ultimo_escondite = escondite
	archivero.position = Vector2(datos.archivero.posicion[0], datos.archivero.posicion[1])
	archivero.destino = Vector2(datos.archivero.destino[0], datos.archivero.destino[1])
	if campana.lugar == "campus" and int(datos.get("campana",{}).get("mapa_version",3)) < Geo.VERSION:
		archivero.position = Geo.ARCHIVERO
		archivero.destino = Geo.ARCHIVERO
	archivero.activo = datos.archivero.activo
	if campana.gracia_activa(): archivero.activo = false
	archivero.visible = archivero.activo
	archivero.estado = datos.archivero.estado
	archivero.memoria = datos.archivero.memoria
	archivero.espera = datos.archivero.espera
	jugador.get_node("Camera2D").reset_smoothing()
	await get_tree().physics_frame
	await get_tree().physics_frame
	archivero.construir_rutas()
	partida_iniciada = true
	jugando = true
	interfaz.jugar()
	anunciar("TURNO RECUPERADO", "Tu expediente todavía sigue abierto.")

func salir() -> void:
	solicitar_salida("salir")

func solicitar_salida(destino: String) -> void:
	destino_salida = destino
	if partida_iniciada and (jugando or interfaz.menu_actual in ["pausa", "opciones", "confirmar_salida", "inventario", "tienda", "mapa"]):
		var seguro := puede_guardar()
		jugando = false
		if not seguro or not guardar_partida():
			# La mochila está sobre los diálogos: retirarla antes de pedir salida.
			if is_instance_valid(inventario_ui): inventario_ui.queue_free()
			inventario_ui = null
			Controles.detener()
			interfaz.mostrar("confirmar_salida")
			return
	confirmar_salida()

func confirmar_salida() -> void:
	Controles.detener()
	Controles.guardar_opciones()
	if destino_salida == "menu":
		reiniciar("inicio")
	else:
		get_tree().quit()
