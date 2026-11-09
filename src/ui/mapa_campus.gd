extends Control
## Cartografía de la geometría jugable: misma fuente para radar y plano.
const Geo = preload("res://src/world/geometria_campus.gd")
var escuela: Node2D
var radar := false
var suelos: Array[Dictionary] = []
var paredes: Array[Rect2] = []
var lugar := ""
var reloj := 0.0
var escala := 1.0
var origen := Vector2.ZERO
var tiempo := 0.0
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func recopilar(n: Node) -> void:
	if n is CollisionShape2D and n.shape is RectangleShape2D and not n.disabled:
		var cuerpo := n.get_parent()
		if cuerpo is CollisionObject2D and cuerpo.collision_layer & 1 and cuerpo.is_visible_in_tree():
			var tam: Vector2 = n.shape.size * n.global_scale.abs()
			paredes.append(Rect2(n.global_position - tam * 0.5, tam))
	for hijo in n.get_children(): recopilar(hijo)

func actualizar() -> void:
	lugar = escuela.campana.lugar
	suelos.clear()
	paredes.clear()
	var base: Node = escuela.get_node("Pisos") if lugar == "principal" else escuela.campana.exterior
	if not is_instance_valid(base): return
	for n in base.get_children():
		if n is Sprite2D and n.region_enabled and n.region_rect.size.x > 40 and n.region_rect.size.y > 40:
			var color := Color("385267")
			if lugar == "campus":
				var archivo: String = n.texture.resource_path
				color = Color("223c39") if "pasto" in archivo else (Color("35444f") if "asfalto" in archivo else Color("56717a"))
			elif str(n.name).begins_with("Pasillo"): color = Color("637c87")
			suelos.append({"rect": Rect2(n.global_position, n.region_rect.size * n.scale), "color": color, "nombre": str(n.name)})
	recopilar(base if lugar == "campus" else escuela.get_node("Paredes"))
	if lugar == "principal": recopilar(escuela.get_node("Objetos"))

func _process(delta: float) -> void:
	if not is_instance_valid(escuela): return
	tiempo += delta
	reloj -= delta
	if lugar != escuela.campana.lugar or reloj <= 0:
		reloj = 0.7
		actualizar()
	queue_redraw()

func punto(p: Vector2) -> Vector2:
	return origen + p * escala

func caja(r: Rect2, color: Color, borde: bool = false) -> void:
	var visual := Rect2(punto(r.position), r.size * escala)
	if not visual.intersects(Rect2(Vector2.ZERO, size)): return
	draw_rect(visual, color)
	if borde: draw_rect(visual, Color("8aa9b5"), false, 1.0)

func _draw() -> void:
	if not is_instance_valid(escuela): return
	var interior: bool = escuela.campana.lugar == "principal"
	var limites := Vector2(3840, 1344) if interior else Vector2(Geo.TAMANO)
	escala = 0.19 if interior else 0.16
	if radar: origen = size * 0.5 - escuela.jugador.global_position * escala
	else:
		escala = minf((size.x - 36) / limites.x, (size.y - 50) / limites.y)
		origen = (size - limites * escala) * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color("0e1c27"))
	if not radar:
		# Cuadrícula de plano técnico.
		var paso := 40.0
		for x in range(0, int(size.x / paso) + 1):
			draw_line(Vector2(x * paso, 0), Vector2(x * paso, size.y), Color(0.3, 0.45, 0.55, 0.08), 1.0)
		for y in range(0, int(size.y / paso) + 1):
			draw_line(Vector2(0, y * paso), Vector2(size.x, y * paso), Color(0.3, 0.45, 0.55, 0.08), 1.0)
	for suelo in suelos: caja(suelo.rect, suelo.color, not str(suelo.nombre).begins_with("Pasillo") and interior)
	if not interior:
		caja(Geo.PRINCIPAL, Color("384b66"), true)
		caja(Geo.SERVICIOS, Color("3f5870"), true)
		caja(Geo.ESTACIONAMIENTO, Color("303f4b"), true)
		caja(Rect2(187,1653,366,612),Color("426c60"),true)
		caja(Rect2(1100,1450,130,925),Color("8e5464"))
	for pared in paredes: caja(pared, Color("a4b7bb") if interior else Color("79908d"))
	var guia: Control = escuela.interfaz.guia
	if is_instance_valid(guia) and not radar:
		for i in range(1, guia.ruta.size()):
			if not conocido(guia.ruta[i]) or not conocido(guia.ruta[i-1]): continue
			# Ruta con guiones que avanzan hacia el destino.
			var a := punto(guia.ruta[i-1])
			var b := punto(guia.ruta[i])
			draw_line(a, b, Color(0.96, 0.8, 0.45, 0.25), 4, true)
			var largo := a.distance_to(b)
			var d := fposmod(tiempo * 30.0, 12.0)
			while d < largo:
				draw_line(a.lerp(b, d / largo), a.lerp(b, minf(d + 6.0, largo) / largo), Color("f4cb72"), 2.5, true)
				d += 12.0
	if not radar:
		draw_string(fuente,Vector2(16,22),"PLANO COMPLETO · sigue la ruta dorada",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b3c4be"))
		if interior:
			for suelo in suelos:
				if not str(suelo.nombre).begins_with("Pasillo") and conocido(suelo.rect.get_center()):
					var nombre: String = str(suelo.nombre).replace("_", " ").replace("Rectoria Archivo", "RECTORÍA").replace("Direccion", "DIRECCIÓN").replace("Computo", "CÓMPUTO")
					rotulo(punto(suelo.rect.get_center()) + Vector2(0,-15), nombre.to_upper(), 12)
		else:
			for dato in [["PRINCIPAL",Geo.PRINCIPAL.get_center()],["SERVICIOS",Vector2(1450,360)],["CAFETERÍA",Vector2(930,470)],["BAÑOS",Vector2(900,1000)],["OFICINAS",Vector2(2120,850)],["CANCHA",Vector2(370,1900)],["PATIO",Vector2(760,1650)],["ESTACIONAMIENTO",Vector2(1400,2820)],["CASETA",Vector2(2480,2630)]]:
				if conocido(dato[1]): rotulo(punto(dato[1]),dato[0],13)
		for objeto in get_tree().get_nodes_in_group("interactivos"):
			if not objeto.is_visible_in_tree() or objeto.is_queued_for_deletion() or not conocido(objeto.global_position): continue
			if objeto.get("tipo") == "recoger" or objeto.is_in_group("puntos_campana"):
				if objeto.get("clave") != null and escuela.campana.hechos.get(objeto.clave,false): continue
				draw_circle(punto(objeto.global_position),2.5,Color("81afa9"))
	if is_instance_valid(guia) and is_instance_valid(guia.destino) and conocido(guia.posicion_objetivo):
		var objetivo: Vector2 = punto(guia.posicion_objetivo)
		if radar: objetivo = size*0.5 + (objetivo-size*0.5).limit_length(size.x*0.42)
		var onda := fposmod(tiempo, 1.4) / 1.4
		draw_arc(objetivo, 8.0 + onda * 16.0, 0, TAU, 32, Color(0.96, 0.8, 0.45, (1.0 - onda) * 0.8), 2.0, true)
		draw_circle(objetivo, 8, Color("14222c"))
		draw_arc(objetivo, 8, 0, TAU, 24, Color("f4cb72"),2,true)
		draw_string(ThemeDB.fallback_font,objetivo+Vector2(-3,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe5a1"))
	# Refugios reales, con la misma geometría del nivel activo.
	for refugio in get_tree().get_nodes_in_group("interactivos"):
		if refugio.get("tipo") != "escondite" or not refugio.is_visible_in_tree() or not conocido(refugio.global_position): continue
		var sitio := punto(refugio.global_position)
		if radar and sitio.distance_to(size*.5)>size.x*.43:continue
		draw_rect(Rect2(sitio-Vector2(3,4),Vector2(6,8)),Color("9adfc5"),false,1.5)
	for recuerdo in get_tree().get_nodes_in_group("recuerdos"):
		if not recuerdo.is_visible_in_tree() or not conocido(recuerdo.global_position):continue
		var sitio := punto(recuerdo.global_position)
		if radar and sitio.distance_to(size*.5)>size.x*.43:continue
		var color := Color("536b69") if escuela.campana.hechos.get(recuerdo.marca(),false) else Color("b7c7b4")
		draw_arc(sitio,5,0,TAU,16,color,1.5,true)
		draw_circle(sitio,1.5,color)
	var jugador := punto(escuela.jugador.global_position)
	# Cono de la linterna y pulso de posición.
	if escuela.jugador.linterna:
		var ang: float = escuela.jugador.apuntado.angle()
		var cono := PackedVector2Array([jugador, jugador + Vector2.from_angle(ang - 0.4) * 34.0, jugador + Vector2.from_angle(ang + 0.4) * 34.0])
		draw_colored_polygon(cono, Color(1.0, 0.95, 0.7, 0.16))
	draw_arc(jugador, 11.0 + sin(tiempo * 4.0) * 2.0, 0, TAU, 24, Color(0.63, 1.0, 0.88, 0.45), 1.5, true)
	draw_circle(jugador,9,Color("112b35"))
	var triangulo := PackedVector2Array()
	for v in [Vector2(10,0),Vector2(-6,-6),Vector2(-3,0),Vector2(-6,6)]: triangulo.append(jugador+v.rotated(escuela.jugador.apuntado.angle()))
	draw_colored_polygon(triangulo, Color("a2ffe1"))

func rotulo(p: Vector2, texto: String, tam: int) -> void:
	var ancho := fuente.get_string_size(texto,HORIZONTAL_ALIGNMENT_LEFT,-1,tam+1).x
	draw_string_outline(fuente,p-Vector2(ancho/2,0),texto,HORIZONTAL_ALIGNMENT_LEFT,-1,tam+1,4,Color("14202b"))
	draw_string(fuente,p-Vector2(ancho/2,0),texto,HORIZONTAL_ALIGNMENT_LEFT,-1,tam+1,Color("e5eff1"))


func conocido(_p: Vector2) -> bool:
	return true
