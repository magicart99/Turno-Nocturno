extends SceneTree
const Geo=preload("res://src/world/geometria_campus.gd")
const Guardado=preload("res://src/core/guardado.gd")
var e: Node2D
var fallos: int=0
func _initialize() -> void:call_deferred("ejecutar")
func comprobar(ok: bool,t: String) -> void:
	print(("OK " if ok else "FALLO ")+t)
	if not ok:fallos+=1
func esperar() -> void:
	for i in range(4):await physics_frame
func ejecutar() -> void:
	Guardado.ruta="res://partidas/prueba_guia_v6.json"
	e=load("res://scenes/escuela.tscn").instantiate();root.add_child(e);current_scene=e
	await esperar()
	var g: Control=e.interfaz.guia
	var c: Node=e.campana
	g.actualizar_ruta()
	comprobar(g.destino.titulo=="Llave maestra" and not g.ruta.is_empty(),"Guía inicial alcanza Dirección")
	e.jugador.inventario.append("Llave maestra")
	g.actualizar_ruta()
	comprobar(g.destino.clave=="tablero_principal","Guía indica tablero antes del expediente")
	e.alimentar_zona("Rectoria_Archivo");g.actualizar_ruta()
	comprobar(g.destino.titulo=="Expediente de Lalo" and not g.ruta.is_empty(),"Guía a Rectoría con corriente")
	c.etapa=2
	await c.cambiar_lugar("campus",Geo.ENTRADA,false)
	await esperar()
	var origen: Vector2=Geo.ENTRADA
	var recorrido: float=0
	for clave in ["revision_luz","revision_agua","memoria_banca","archivo_enterrado","prefecta"]:
		e.jugador.position=origen;g.actualizar_ruta()
		comprobar(g.destino.clave==clave and not g.ruta.is_empty(),"Ruta de misión N2: "+clave)
		recorrido+=g.distancia
		if not g.ruta.is_empty():origen=g.ruta[-1]
		c.hechos[clave]=true
	print("RECORRIDO_N2_PX: ",recorrido)
	comprobar(recorrido<2976,"N2 más corto que los 2976 px de v4")
	c.etapa=3;c.actualizar_accesos();await esperar();e.archivero.construir_rutas()
	for clave in ["llave_servicio","revision_cafe","revision_banos","reporte"]:
		e.jugador.position=origen;g.actualizar_ruta()
		comprobar(g.destino.clave==clave and not g.ruta.is_empty(),"Ruta de misión N3: "+clave)
		if not g.ruta.is_empty():origen=g.ruta[-1]
		c.hechos[clave]=true
	c.etapa=4;c.actualizar_accesos();await esperar();e.archivero.construir_rutas()
	e.jugador.position=origen;g.actualizar_ruta()
	comprobar(g.destino.clave=="guardia" and not g.ruta.is_empty(),"Ruta a caseta del guardia")
	comprobar(Geo.adaptar_v4(Vector2(1900,2450))==Geo.ENTRADA,"Partida antigua reaparece en acceso seguro")
	c.hechos["reporte_entregado"]=true;c.actualizar_accesos();await esperar();e.archivero.construir_rutas()
	g.actualizar_ruta()
	comprobar(g.destino.clave=="salida_final" and not g.ruta.is_empty(),"Ruta a salida desbloqueada")
	comprobar(Geo.SALIDA.has_point(g.posicion_objetivo),"Flecha final cruza la pluma hasta el área de victoria")
	Guardado.ruta="res://partidas/prueba_guia_v6.json"
	e.guardar_partida()
	var viejo: Dictionary=Guardado.leer()
	viejo.campana.mapa_version=4;viejo.jugador.posicion=[1900,2450];viejo.archivero.posicion=[2150,1600];viejo.archivero.destino=[2150,1600]
	Guardado.guardar(viejo)
	await e.aplicar_guardado();e.jugando=false
	comprobar(e.jugador.position==Geo.ENTRADA and e.archivero.position==Geo.ARCHIVERO,"Cargar v4 recoloca jugador y enemigo en puntos seguros")
	comprobar(c.etapa==4 and c.hechos.get("reporte_entregado",false),"Migrar conserva avance de misiones")
	for sufijo in ["",".bak",".tmp"]:DirAccess.remove_absolute(Guardado.ruta+sufijo)
	if "--capturas" in OS.get_cmdline_user_args():
		e.interfaz.jugar();e.interfaz.aviso.hide();e.interfaz.aviso.modulate.a=0;e.interfaz.subtitulo.hide();e.oscuridad.hide()
		e.get_node("Ambiente").color=Color(.65,.68,.7)
		e.jugador.get_node("Camera2D").enabled=false
		var cam:=Camera2D.new();e.add_child(cam);cam.position=Vector2(1600,1600);cam.zoom=Vector2(.21,.21)
		await create_timer(.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/capturas_anteriores/campus_v6_general.png")
		cam.queue_free();e.jugador.get_node("Camera2D").enabled=true
		c.etapa=2;c.hechos.clear();c.gracia_patio=60;e.jugador.position=Geo.ENTRADA;e.jugador.get_node("Camera2D").zoom=Vector2(.85,.85)
		e.jugador.get_node("Camera2D").reset_smoothing();e.jugando=true
		await create_timer(.7).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/capturas_anteriores/campus_v6_guia.png")
	print("RESULTADO: %d fallos"%fallos)
	quit(fallos)
