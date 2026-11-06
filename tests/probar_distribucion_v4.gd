extends SceneTree
const Geo = preload("res://src/world/geometria_campus.gd")
var escena: Node2D
var fallos: int = 0
var informe: Array[String] = []
func _initialize() -> void: call_deferred("ejecutar")
func comprobar(ok: bool, texto: String) -> void:
	informe.append(("OK " if ok else "FALLO ")+texto)
	print(informe[-1])
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n): await physics_frame
func longitud(origen: Vector2, destino: Vector2) -> float:
	var a: CharacterBody2D=escena.archivero
	var ruta: PackedVector2Array=a.rejilla.get_point_path(a.celda_libre(origen),a.celda_libre(destino))
	if ruta.is_empty(): return INF
	var total: float=0
	for i in range(1,ruta.size()):total+=ruta[i].distance_to(ruta[i-1])
	return total
func captura(nombre: String, pos: Vector2, zoom: float) -> void:
	if not "--capturas" in OS.get_cmdline_user_args():return
	escena.jugando=false
	escena.jugador.position=pos
	escena.jugador.get_node("Camera2D").zoom=Vector2.ONE*zoom
	escena.jugador.get_node("Camera2D").reset_smoothing()
	escena.get_node("Ambiente").color=Color(.72,.75,.72)
	escena.oscuridad.hide()
	escena.interfaz.panel.hide();escena.interfaz.aviso.hide();escena.interfaz.subtitulo.hide()
	escena.interfaz.hud.text="CAMPUS COMPACTO · DISTRIBUCIÓN V4"
	escena.interfaz.hud.show();escena.interfaz.barras.hide();escena.interfaz.ayuda.hide()
	await create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/"+nombre+".png")
func ejecutar() -> void:
	escena=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena);current_scene=escena
	await esperar()
	escena.Guardado.ruta="res://partidas/prueba_distribucion_v4.json"
	var c: Node=escena.campana
	c.etapa=2
	await c.cambiar_lugar("campus",Geo.ENTRADA,false)
	escena.archivero.construir_rutas()
	var recorrido: float=0
	var desde: Vector2=Geo.ENTRADA
	for clave in ["revision_luz","revision_agua","memoria_banca","archivo_enterrado","prefecta"]:
		var hasta: Vector2=c.exterior.get_node(clave).position
		var tramo: float=longitud(desde,hasta)
		comprobar(is_finite(tramo),"Objetivo N2 conectado: "+clave)
		recorrido+=tramo;desde=hasta
	comprobar(recorrido < 4300,"Recorrido N2 sin rodeos: %.0f px · %.1f s caminando"%[recorrido,recorrido/112])
	comprobar(Geo.TAMANO.y==4200,"Altura del campus reducida de 7200 a 4200")
	var d: Dictionary=c.datos()
	d.erase("mapa_version")
	escena.jugador.position=Vector2(2410,3650)
	await c.restaurar(d)
	comprobar(escena.jugador.position==Geo.ENTRADA,"Partida antigua del patio migra a la entrada nueva")
	escena.jugador.position=Vector2(3370,6210)
	await c.restaurar(d)
	comprobar(escena.jugador.position==Vector2(2470,3500),"Partida antigua de caseta migra sin perder misiones")
	escena.jugador.position=Vector2(1650,900)
	await c.restaurar(d)
	var q := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius=12
	q.shape=forma;q.collision_mask=1
	q.exclude=[escena.jugador.get_rid(),escena.archivero.get_rid()]
	q.transform=Transform2D(0,escena.jugador.position)
	comprobar(escena.jugador.get_world_2d().direct_space_state.intersect_shape(q).is_empty(),"Partida antigua de comedor migra a un pasillo libre de muebles")
	c.etapa=4;c.actualizar_accesos();await esperar()
	await captura("campus_v4_general",Vector2(1550,2110),.155)
	await captura("campus_v4_cafeteria",Vector2(1450,760),.57)
	await captura("campus_v4_patio",Vector2(1840,2350),.78)
	await captura("campus_v4_estacionamiento",Vector2(2020,3450),.55)
	informe.append("RESULTADO: %d fallos"%fallos)
	FileAccess.open("res://docs/pruebas_distribucion_v4.txt",FileAccess.WRITE).store_string("\n".join(informe))
	print(informe[-1]);quit(fallos)
