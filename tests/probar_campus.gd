extends SceneTree
const Geo = preload("res://src/world/geometria_campus.gd")
const Guardado = preload("res://src/core/guardado.gd")
var escena: Node2D
var fallos: int = 0
var lineas: Array[String] = []
func _initialize() -> void:
	call_deferred("ejecutar")
func comprobar(valor: bool, texto: String) -> void:
	var linea := ("OK " if valor else "FALLO ") + texto
	print(linea)
	lineas.append(linea)
	if not valor: fallos += 1
func esperar(n: int = 3) -> void:
	for i in range(n): await physics_frame
func buscar(titulo: String) -> Node2D:
	for n in escena.get_node("Objetos").get_children():
		if n.titulo == titulo and not n.is_queued_for_deletion(): return n
	return null
func alcanzable(punto: Node2D, origen: Vector2) -> bool:
	var j: CharacterBody2D=escena.jugador
	var anterior: Vector2=j.position
	var q:=PhysicsShapeQueryParameters2D.new()
	var forma:=CircleShape2D.new()
	forma.radius=12
	q.shape=forma
	q.collision_mask=1
	q.exclude=[j.get_rid(),escena.archivero.get_rid()]
	for radio in [32,48,64,78]:
		for angulo in range(16):
			var p: Vector2=punto.global_position+Vector2.from_angle(angulo*TAU/16)*radio
			q.transform=Transform2D(0,p)
			if not j.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty(): continue
			j.position=p
			if j.mas_cercano()!=punto: continue
			var ruta: PackedVector2Array=escena.archivero.rejilla.get_point_path(escena.archivero.celda_libre(origen),escena.archivero.celda_libre(p))
			if ruta.size()>0:
				j.position=anterior
				return true
	j.position=anterior
	return false
func captura(nombre: String, posicion: Vector2, zoom: float = 1.0) -> void:
	if not "--capturas" in OS.get_cmdline_user_args(): return
	escena.jugando = false
	escena.jugador.position = posicion
	escena.jugador.get_node("Camera2D").zoom = Vector2.ONE * zoom
	escena.jugador.get_node("Camera2D").reset_smoothing()
	escena.interfaz.jugar()
	escena.interfaz.aviso.hide()
	escena.interfaz.subtitulo.hide()
	escena.interfaz.hud.text = "TURNO NOCTURNO · CAMPUS\n" + escena.campana.objetivo()
	escena.interfaz.ayuda.text = ""
	escena.interfaz.barras.text = "REVISIÓN VISUAL · ILUMINACIÓN AUMENTADA"
	escena.oscuridad.hide()
	escena.get_node("Ambiente").color = Color(0.54,0.57,0.6)
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/" + nombre + ".png")

func ejecutar() -> void:
	escena = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	await esperar(5)
	Guardado.ruta = "res://partidas/prueba_campus.json"
	var j: CharacterBody2D = escena.jugador
	var c: Node = escena.campana
	var a: CharacterBody2D = escena.archivero
	for nombre in ["paso","puerta","ambiente","paso_exterior","paso_archivero","grito","alarma"]:
		var audio: AudioStream=escena.sonidos.recursos[nombre]
		comprobar(audio!=null and audio.get_length()>0,"Audio importado: %s · %.2f s"%[nombre,audio.get_length()])
	comprobar(escena.interfaz.menu_actual == "inicio", "Inicio con foco de menú antes de jugar")
	comprobar(root.gui_get_focus_owner() is Button, "Botón inicial enfocado sin ratón")
	var aulas := 0
	var banos := 0
	for obj in escena.get_node("Objetos").get_children():
		if obj.titulo.begins_with("Puerta: Aula_"): aulas += 1
		if obj.titulo.begins_with("Puerta: Bano_"): banos += 1
	comprobar(aulas == 9 and banos == 2,"Conserva 9 aulas y 2 baños del principal")
	for punto in get_nodes_in_group("puntos_campana"):
		comprobar(alcanzable(punto,Vector2(2112,670)),"Interacción seleccionable en principal: "+punto.clave)
	for accion in ["interactuar","linterna","correr","pausa","distraer","mapa","ui_accept","ui_cancel","ui_up","ui_down"]:
		var universal := false
		for evento in InputMap.action_get_events(accion):
			if evento is InputEventJoypadButton and evento.device == -1: universal = true
		comprobar(universal,"Mando de cualquier ID: " + accion)
	var controles := root.get_node("Controles")
	for id in [0,3]:
		var evento := InputEventJoypadButton.new()
		evento.device = id
		evento.button_index = JOY_BUTTON_X
		evento.pressed = true
		Input.parse_input_event(evento)
		Input.flush_buffered_events()
		await esperar()
		comprobar(Input.is_action_pressed("linterna"),"Botón X/Cuadrado reconocido en dispositivo %d" % id)
		var soltar := evento.duplicate() as InputEventJoypadButton
		soltar.pressed = false
		Input.parse_input_event(soltar)
		Input.flush_buffered_events()
		await esperar()
	escena.iniciar()
	await create_timer(3.3).timeout
	comprobar(escena.jugando,"Inicio no pierde pulsación durante preparación")
	comprobar(j.get_node("Linterna").position.y < -20,"Linterna nace en torso/mano, no pies")
	escena.jugando = false
	c.interactuar("bitacora")
	comprobar(c.etapa == 1 and c.lugar == "principal","No permite salir sin obligaciones")
	buscar("Llave maestra").interactuar(j)
	escena.alternar_zona("Rectoria_Archivo")
	buscar("Expediente de Lalo").interactuar(j)
	await esperar()
	escena.alimentar_zona("Computo")
	c.interactuar("computo")
	for paso in range(3):
		# Resuelve el mismo menú que usa el jugador, no escribe el estado del puzle.
		var botones: Array[Button] = []
		for nodo in escena.interfaz.columna.get_children():
			if nodo is Button: botones.append(nodo)
		botones[paso].pressed.emit()
		await esperar()
	comprobar(c.hechos.get("computo",false),"Puzle completo desbloquea bitácora")
	c.interactuar("radio"); c.interactuar("pala")
	await captura("campus_01_principal",Vector2(2112,1110),0.9)
	c.interactuar("bitacora")
	await esperar(8)
	comprobar(c.etapa == 2 and c.lugar == "campus","Bitácora abre el nivel 2")
	var bloqueada: PackedVector2Array=a.rejilla.get_point_path(a.celda_libre(j.position),a.celda_libre(Vector2(1540,950)))
	comprobar(bloqueada.is_empty(),"No se puede entrar a servicios antes de autorización")
	comprobar(not escena.get_node("Paredes").can_process(),"Colisiones del interior se desactivan al salir")
	c.interactuar("prefecta")
	comprobar(c.etapa == 2,"Prefecta exige revisiones y memorias")
	c.interactuar("revision_luz")
	for indice in range(4):
		var tablero: CanvasLayer=c.tablero
		var fuente: Button=tablero.fuentes[indice]
		fuente.pressed.emit()
		for destino in tablero.destinos:
			if destino.text==fuente.text:destino.pressed.emit();break
		await esperar()
	c.tablero.fase=0.0
	c.tablero.estabilizar()
	await esperar()
	for clave in ["revision_agua","memoria_banca","archivo_enterrado"]:
		c.interactuar(clave)
		if clave == "revision_agua": await resolver_revision()
	await create_timer(3.2).timeout
	c.interactuar("prefecta")
	await esperar()
	comprobar(c.etapa == 3 and c.exterior.get_node("PuertaSegundo/Colision").disabled,"Nivel 3 desbloquea físicamente su puerta")
	await captura("campus_02_patio",Vector2(1840,2450),0.8)
	await captura("campus_03_servicios",Vector2(1530,800),0.58)
	c.interactuar("reporte")
	comprobar(c.etapa == 3,"Reporte exige llave y revisiones")
	for clave in ["llave_servicio","revision_cafe","revision_banos"]:
		c.interactuar(clave)
		if clave != "llave_servicio": await resolver_revision()
	c.interactuar("reporte")
	await esperar(4)
	comprobar(c.etapa == 4 and c.exterior.get_node("RejaParking/Colision").disabled,"Nivel 4 abre estacionamiento")
	comprobar(not c.exterior.get_node("PlumaSalida/Colision").disabled,"Pluma cerrada hasta entregar reporte")
	# Rutas físicas sobre geometría real: portales y objetos obligatorios.
	a.construir_rutas()
	for punto in get_nodes_in_group("puntos_campana"):
		if not punto.is_visible_in_tree() or punto.consumible or punto.clave in ["volver_principal","salida_final"]: continue
		var ruta: PackedVector2Array = a.rejilla.get_point_path(a.celda_libre(Geo.ENTRADA),a.celda_libre(punto.global_position))
		comprobar(ruta.size()>0,"Ruta física a " + punto.clave)
		comprobar(alcanzable(punto,Geo.ENTRADA),"Interacción seleccionable en campus: "+punto.clave)
	c.interactuar("moneda_0"); c.interactuar("moneda_0")
	comprobar(c.monedas == 1,"Moneda persistente no se duplica")
	j.cordura = 30
	c.comprar(0)
	comprobar(c.monedas == 0 and j.cordura == 60,"Compra aplica coste y recuperación")
	j.position = Geo.PARKING
	c.bateria = 41
	var ok: bool = escena.guardar_partida()
	if not ok: DirAccess.copy_absolute(Guardado.ruta+".tmp","res://docs/diagnostico_guardado.json")
	comprobar(ok,"Guarda posición exterior, etapa y batería")
	var guardado := Guardado.leer()
	comprobar(guardado.get("campana",{}).get("etapa",0)==4,"Guardado incluye avance de campaña")
	c.etapa=1;c.hechos.clear();c.bateria=0
	await escena.aplicar_guardado()
	escena.jugando=false
	comprobar(c.etapa==4 and c.bateria>40 and c.lugar=="campus" and j.position.distance_to(Geo.PARKING)<5,"Carga restaura exterior y desbloqueos")
	await captura("campus_04_caseta",Vector2(2470,3520),0.85)
	if "--capturas" in OS.get_cmdline_user_args():
		escena.get_node("Ambiente").color=Color(0.045,0.06,0.095)
		escena.oscuridad.show()
		escena.interfaz.barras.text="CORDURA %d   /   PILA %d%%   /   NIVEL 4"%[int(j.cordura),int(c.bateria)]
		escena.interfaz.ayuda.text="[E / A / Cruz] Don Chuy · entregar reporte"
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/capturas_anteriores/campus_05_nocturno.png")
	c.interactuar("guardia")
	var aceptar: Button
	for nodo in escena.interfaz.columna.get_children():
		if nodo is Button: aceptar=nodo;break
	aceptar.pressed.emit()
	await esperar()
	comprobar(c.hechos.get("reporte_entregado",false) and c.exterior.get_node("PlumaSalida/Colision").disabled,"Don Chuy recibe reporte y abre salida")
	j.position=Geo.SALIDA.get_center()
	escena.jugando=true
	for i in range(12):
		await process_frame
		await physics_frame
		if escena.interfaz.menu_actual=="victoria": break
	comprobar(escena.interfaz.menu_actual=="victoria","Cruzar salida termina campaña")
	lineas.append("RESULTADO: %d fallos" % fallos)
	FileAccess.open("res://docs/pruebas_campus.txt",FileAccess.WRITE).store_string("\n".join(lineas))
	for sufijo in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(Guardado.ruta+sufijo)
	print(lineas[-1])
	quit(fallos)


func resolver_revision() -> void:
	for boton in escena.interfaz.columna.get_children():
		if boton is Button:
			boton.pressed.emit()
			break
	await esperar()
