extends SceneTree
const Geo = preload("res://src/world/geometria_campus.gd")
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, nombre: String) -> void:
	print(("OK " if ok else "FALLO ") + nombre)
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func captura(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v7/" + nombre + ".png")
func pulsar(accion: String) -> void:
	var evento := InputEventAction.new()
	evento.action=accion;evento.pressed=true
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await esperar(4)
	evento=InputEventAction.new()
	evento.action=accion;evento.pressed=false
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await esperar(4)
func elegir(indice: int) -> void:
	var botones: Array[Button] = []
	for n in e.interfaz.columna.get_children():
		if n is Button: botones.append(n)
	botones[indice].pressed.emit()
	await esperar()
func ejecutar() -> void:
	e=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e);current_scene=e
	await esperar(8)
	e.Guardado.ruta="res://docs/mejoras_v7/guardado_prueba.json"
	e.partida_iniciada=true;e.jugando=true;e.interfaz.jugar()
	e.archivero.set_physics_process(false)
	var j: CharacterBody2D=e.jugador
	var mini: Control
	for n in e.interfaz.panel.get_parent().get_children():
		if n.get_script() == load("res://src/ui/minimapa.gd"): mini=n
	await esperar(8)
	check(mini.visible,"Radar siempre visible durante la partida")
	check(not e.interfaz.guia.visible,"Flecha lateral retirada")
	e.interfaz.guia.actualizar_ruta()
	check(not e.interfaz.guia.ruta.is_empty(),"Radar dispone de ruta hacia Dirección")
	await captura("radar_interior")
	await pulsar("minimapa")
	check(e.interfaz.menu_actual=="mapa" and not e.jugando,"Gatillo / V abre plano y pausa")
	await captura("plano_escuela")
	await pulsar("minimapa")
	check(e.jugando and not is_instance_valid(e.interfaz.plano_grande),"Misma acción cierra plano y continúa")
	await pulsar("pausa")
	check(e.interfaz.menu_actual=="pausa" and not e.jugando,"Pausa responde una sola vez")
	await pulsar("pausa")
	check(e.jugando,"Segunda pulsación continúa")
	# Eventos de los dos ejes reales de gatillo.
	for eje in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var evento := InputEventJoypadMotion.new()
		evento.device=0;evento.axis=eje;evento.axis_value=1.0
		Input.parse_input_event(evento);Input.flush_buffered_events()
		await esperar()
		check(e.interfaz.menu_actual=="mapa","Gatillo físico abre plano: %d" % eje)
		for valor in [.81,.96,.75]:
			evento=InputEventJoypadMotion.new()
			evento.device=0;evento.axis=eje;evento.axis_value=valor
			Input.parse_input_event(evento);Input.flush_buffered_events()
			await esperar(1)
		check(e.interfaz.menu_actual=="mapa","Mantener gatillo no alterna repetidamente")
		evento=InputEventJoypadMotion.new()
		evento.device=0;evento.axis=eje;evento.axis_value=0.0
		Input.parse_input_event(evento);Input.flush_buffered_events()
		await esperar()
		await pulsar("ui_cancel")
		check(e.jugando and e.interfaz.menu_actual=="","Cerrar plano no vuelve a pausar")
	var gatillos := 0
	for evento in InputMap.action_get_events("minimapa"):
		if evento is InputEventJoypadMotion: gatillos+=1
	check(gatillos==2,"Ambos gatillos configurados")
	j.set_physics_process(false)
	j.sigilo=100;j.agachado=true
	j.actualizar_sigilo(19.9)
	check(j.agachado and j.sigilo>0,"Sigilo disponible a los 19,9 segundos")
	j.actualizar_sigilo(.11)
	check(not j.agachado and j.sigilo_agotado,"Sigilo se agota a los 20 segundos")
	j.sigilo=100;j.sigilo_agotado=false;j.descanso_sigilo=0
	j.apuntado=Vector2.LEFT;j.linterna=true
	j.animar_movimiento(Vector2.RIGHT*112,false)
	check(j.direccion_animacion=="right","Caminar sigue el desplazamiento aunque el ratón mire atrás")
	var escondite: Node2D
	for n in get_nodes_in_group("interactivos"):
		if n.get("titulo") != null and "Casillero" in n.titulo: escondite=n;break
	j.esconder(escondite)
	check(j.duracion_accion==.5,"Entrada al casillero en medio segundo")
	j.procesar_accion(.51)
	check(j.oculto and not j.get_node("Linterna").enabled,"Oculto apaga linterna")
	j.esconder(escondite);j.procesar_accion(.41)
	check(not j.oculto and j.get_node("Linterna").enabled,"Salir restaura linterna sin quedarse invisible")
	check(j.get_node("Linterna").texture.resource_path.ends_with("linterna_suave.png"),"Haz suave instalado")
	j.set_physics_process(true)
	e.campana.etapa=2
	await e.campana.cambiar_lugar("campus",Geo.ENTRADA,false)
	e.interfaz.guia.actualizar_ruta()
	await esperar(8)
	check(mini.plano.lugar=="campus","Radar cambia a cartografía exterior")
	await captura("patio_radar")
	await pulsar("mapa")
	await captura("plano_campus")
	await pulsar("mapa")
	for clave in ["revision_agua","revision_cafe","revision_banos"]:
		e.campana.hechos.erase(clave)
		e.campana.interactuar(clave)
		check(e.interfaz.menu_actual=="dialogo" and not e.campana.hechos.has(clave),"Revisión exige decisión: "+clave)
		await elegir(1)
		check(not e.campana.hechos.has(clave),"Respuesta incorrecta no completa: "+clave)
		e.campana.interactuar(clave)
		if clave=="revision_agua": await captura("historia_patio")
		await elegir(0)
		check(e.campana.hechos.get(clave,false),"Resolución correcta: "+clave)
	e.campana.puzzle=0
	e.campana.mostrar_puzzle()
	for i in range(3): await elegir(i)
	check(e.campana.hechos.get("computo",false),"Reconocer a la de Cómputo completa los tres pasos y libera la bitácora")
	var antes: int=e.relato.cola.size()
	e.campana.completar("archivo_enterrado","test")
	e.campana.completar("archivo_enterrado","test")
	check(e.relato.cola.size()==antes+1,"Testimonio solo una vez; marca persistente")
	check(e.campana.datos().hechos.get("relato_archivo_enterrado",false),"Progreso narrativo se serializa")
	for nombre in ["puerta","murmullo","papeles","radio_estatica"]:
		check(e.sonidos.recursos[nombre].get_length() > .1,"Audio importado: "+nombre)
	check(e.sonidos.variantes_pasos.concrete.size()==4,"Cuatro pasos por superficie")
	if DisplayServer.get_name() != "headless":
		e.jugando=false;e.sonidos.silenciar_ambiente(true)
		e.sonidos.efecto("puerta",j.global_position,-2)
		var pico: float=-100
		for i in range(30):
			await create_timer(.025).timeout
			pico=maxf(pico,AudioServer.get_bus_peak_volume_left_db(0,0))
		check(pico > -40 and pico < 0,"Puerta audible sin saturación: %.1f dB"%pico)
	print("RESULTADO: %d fallos" % fallos)
	quit(fallos)


