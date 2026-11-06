extends SceneTree
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ")+texto)
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func foto(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v13/"+nombre+".png")
func aceptar() -> void:
	for n in e.interfaz.columna.get_children():
		if n is Button:
			n.pressed.emit()
			return
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://docs/mejoras_v13/guardado_prueba.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.set_process(false); e.campana.set_process(false); e.mente.set_process(false)
	e.archivero.set_physics_process(false); e.archivero.activo = false
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	j.inventario.assign(["Llave maestra","Expediente de Lalo"])
	check(e.campana.interactuar("computo").contains("corriente"),"Cómputo explica cómo conseguir corriente")
	e.alimentar_zona("Computo")
	j.position = Vector2(610,1160)
	e.campana.interactuar("computo")
	await esperar(); await foto("computo_dialogo")
	aceptar()
	check(e.campana.hechos.get("computo",false),"Una sola decisión clara resuelve Cómputo")
	e.campana.interactuar("radio"); e.campana.interactuar("pala")
	e.campana.interactuar("bitacora"); await esperar(12)
	check(e.campana.etapa==2 and e.campana.lugar=="campus","Salida del principal lleva al patio")
	var muro: StaticBody2D = e.get_node("Paredes").get_child(0)
	check(muro.collision_layer==0,"Paredes del edificio oculto no bloquean el patio")
	e.campana.hechos["revision_luz"]=true; e.campana.hechos["revision_agua"]=true
	e.campana.interactuar("memoria_banca")
	var tierra: Node2D = e.campana.exterior.get_node("archivo_enterrado")
	j.position = tierra.position + Vector2(0,55)
	e.campana.interactuar("archivo_enterrado",tierra)
	j.procesar_accion(1.9); await esperar()
	var visual: Node2D = tierra.get_child(tierra.get_child_count()-1)
	check(visual.usb.visible and not e.campana.hechos.get("archivo_enterrado",false),"USB emerge durante la animación sin recogerse automáticamente")
	j.get_node("Camera2D").reset_smoothing()
	e.interfaz.aviso.hide(); e.interfaz.subtitulo.hide()
	await foto("excavacion")
	j.cancelar_accion()
	check(not e.campana.hechos.get("memoria_desenterrada",false),"Cancelar una excavación incompleta no regala la memoria")
	e.campana.interactuar("archivo_enterrado",tierra); j.procesar_accion(3.1); await esperar()
	check(visual.usb.visible and tierra.visible,"USB permanece visible sobre el hoyo")
	check(e.campana.objetivo().contains("Recoge"),"Objetivo distingue excavar de recoger")
	await foto("memoria_visible")
	var datos: Dictionary = e.campana.datos()
	await e.campana.restaurar(datos); await esperar()
	check(visual.usb.visible and not e.campana.hechos.get("archivo_enterrado",false),"Guardar y restaurar conserva la USB pendiente de recoger")
	e.campana.interactuar("archivo_enterrado",tierra)
	e.campana.interactuar("archivo_enterrado",tierra)
	check(j.inventario.count("Memoria USB del patio")==1,"Recoger dos veces no duplica evidencia")
	e.campana.interactuar("prefecta"); await esperar()
	check(e.campana.etapa==3 and not j.inventario.has("Nota de la banca"),"Prefecta recibe la nota y abre Servicios")
	check(e.campana.objetivo().contains("Talleres"),"Talleres tiene objetivo obligatorio y ubicación")
	check(e.campana.interactuar("llave_servicio").contains("Habla"),"La llave espera la intervención de Talleres")
	e.campana.interactuar("talleres"); await esperar(); await foto("talleres_dialogo"); aceptar()
	check(e.campana.hechos.get("talleres",false) and j.inventario.has("Grabación recuperada") and not j.inventario.has("Memoria USB del patio"),"Talleres recibe la USB y devuelve la grabación")
	e.campana.interactuar("llave_servicio")
	e.campana.interactuar("revision_cafe"); aceptar()
	e.campana.interactuar("revision_banos"); aceptar()
	e.campana.interactuar("reporte"); await esperar()
	check(e.campana.etapa==4,"Pruebas y revisiones desbloquean el reporte")
	e.campana.interactuar("guardia"); aceptar(); await esperar()
	check(e.campana.hechos.get("reporte_entregado",false),"Don Chuy recibe el reporte y permite salir")
	e.campana.explorados.clear()
	e.interfaz.mostrar_mapa(); await esperar()
	var plano: Control = e.interfaz.plano_grande.get_child(2)
	check(plano.conocido(Vector2(2500,3000)),"El mapa completo no depende de exploración")
	await foto("mapa_completo")
	e.continuar()
	await e.campana.cambiar_lugar("principal",Vector2(2100,650),false); await esperar()
	check(muro.collision_layer!=0,"Volver restaura las paredes del principal")
	check(e.campana.exterior.get_node("Muro2").collision_layer==0,"El campus oculto no bloquea el principal")
	e.campana.etapa=2
	await e.campana.cambiar_lugar("campus",Vector2(880,1767),false); await esperar()
	check(muro.collision_layer==0 and e.campana.exterior.get_node("Muro2").collision_layer!=0,"Cambios repetidos conservan capas originales")
	check(e.guardar_partida(),"Guardado válido con nuevas evidencias y hechos")
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free(); await esperar(); quit(fallos)
