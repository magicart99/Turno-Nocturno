extends Control
## El indicador apunta al siguiente tramo transitable, no a través de paredes.
var escuela: Node2D
var ruta := PackedVector2Array()
var destino: Node2D
var reloj: float = 0.0
var distancia: float = 0.0
var cerca: bool = false
var direccion := Vector2.UP
var texto: String = ""
var posicion_objetivo := Vector2.ZERO

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func buscar_destino() -> Node2D:
	var c: Node=escuela.campana
	var clave: String=""
	var titulo: String=""
	if c.lugar=="principal" and c.etapa>=2: clave="bitacora"
	elif c.etapa==1:
		if not escuela.jugador.inventario.has("Llave maestra"): titulo="Llave maestra"
		elif not escuela.jugador.inventario.has("Expediente de Lalo"):
			if escuela.zonas.get("Rectoria_Archivo",false): titulo="Expediente de Lalo"
			else: clave="tablero_principal"
		elif not c.hechos.get("computo",false): clave="computo" if escuela.zonas.get("Computo",false) else "tablero_principal"
		elif not c.hechos.get("radio",false): clave="radio"
		elif not c.hechos.get("pala",false): clave="pala"
		else: clave="bitacora"
	elif c.etapa==2:
		for k in ["revision_luz","revision_agua","memoria_banca","archivo_enterrado"]:
			if not c.hechos.get(k,false): clave=k;break
		if clave=="":clave="prefecta"
	elif c.etapa==3:
		for k in ["talleres","llave_servicio","revision_cafe","revision_banos"]:
			if not c.hechos.get(k,false):clave=k;break
		if clave=="":clave="reporte"
	elif c.etapa==4:clave="salida_final" if c.hechos.get("reporte_entregado",false) else "guardia"
	if titulo!="":
		for n in escuela.get_node("Objetos").get_children():
			if n.get("titulo")==titulo and not n.is_queued_for_deletion():return n
	for n in get_tree().get_nodes_in_group("puntos_campana"):
		if n.clave==clave and n.is_visible_in_tree():return n
	return null

func actualizar_ruta() -> void:
	destino=buscar_destino();ruta.clear();texto="";distancia=0
	if not is_instance_valid(destino):return
	texto=destino.titulo
	posicion_objetivo=destino.global_position
	if destino.get("clave")=="salida_final":
		posicion_objetivo=preload("res://src/world/geometria_campus.gd").SALIDA.get_center()
		texto="Cruza la pluma hacia la calle"
	var a: Node=escuela.archivero
	if not a.lista:return
	var origen: Vector2=escuela.jugador.global_position
	var mejor: float=INF
	var espacio: PhysicsDirectSpaceState2D=escuela.jugador.get_world_2d().direct_space_state
	for i in range(16):
		var p: Vector2=posicion_objetivo+Vector2.from_angle(i*TAU/16)*55
		var celda: Vector2i=a.celda_libre(p)
		var fin: Vector2=a.rejilla.get_point_position(celda)
		if fin.distance_to(posicion_objetivo)>85:continue
		var ray := PhysicsRayQueryParameters2D.create(fin,posicion_objetivo,1)
		ray.exclude=[escuela.jugador.get_rid(),a.get_rid(),destino.get_rid()]
		if not espacio.intersect_ray(ray).is_empty():continue
		var candidata: PackedVector2Array=a.rejilla.get_point_path(a.celda_libre(origen),celda)
		if candidata.is_empty():continue
		var largo: float=origen.distance_to(candidata[0])
		for j in range(1,candidata.size()):largo+=candidata[j-1].distance_to(candidata[j])
		if largo<mejor:mejor=largo;ruta=candidata
	distancia=mejor if is_finite(mejor) else 0

func _process(delta: float) -> void:
	visible = false
	if not escuela.jugando: return
	reloj-=delta
	if reloj<=0:reloj=.45;actualizar_ruta()
	if is_instance_valid(destino):
		var origen: Vector2=escuela.jugador.global_position
		cerca=origen.distance_to(posicion_objetivo)<85 and distancia<65 and not ruta.is_empty()
		var siguiente: Vector2=posicion_objetivo
		for p in ruta:
			if origen.distance_to(p)>45:siguiente=p;break
		direccion=origen.direction_to(siguiente)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(destino):return
	draw_style_box(panel(),Rect2(29,205,660,34))
	var centro := Vector2(48,222)
	var color := Color("f3cd7e")
	if cerca:draw_circle(centro,6,color)
	elif not ruta.is_empty():
		var angulo: float=direccion.angle()
		var puntos := PackedVector2Array()
		for p in [Vector2(11,0),Vector2(-7,-8),Vector2(-3,0),Vector2(-7,8)]:puntos.append(centro+p.rotated(angulo))
		draw_colored_polygon(puntos,color)
	var prefijo: String="Interactúa · " if cerca else ("Sigue la flecha · " if not ruta.is_empty() else "Busca el acceso · ")
	draw_string(ThemeDB.fallback_font,Vector2(70,228),prefijo+texto,HORIZONTAL_ALIGNMENT_LEFT,607,15,color)

func panel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color=Color(0.025,0.04,0.05,.88)
	estilo.corner_radius_top_left=5;estilo.corner_radius_bottom_left=5
	return estilo
