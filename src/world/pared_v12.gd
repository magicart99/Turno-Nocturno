extends Node2D
## La misma silueta define dibujo, colisión y sombra; sin texturas estiradas.
var rect := Rect2()
## "acabado": remate superior (z 4). "cara": frente del muro y sombra de contacto, bajo los personajes.
var modo := "acabado"
const ALTO_CARA := 26.0

static func renovar(raiz: Node) -> int:
	var cantidad := 0
	for n in raiz.get_children():
		if n is StaticBody2D and str(n.name).begins_with("Muro") and not n.has_node("AcabadoV12"):
			var c := n.get_node_or_null("Colision") as CollisionShape2D
			if c and c.shape is RectangleShape2D:
				for hijo in n.get_children():
					if hijo is Sprite2D: hijo.hide()
				var acabado := load("res://src/world/pared_v12.gd").new() as Node2D
				acabado.name = "AcabadoV12"
				acabado.position = c.position
				acabado.rect = Rect2(-c.shape.size * 0.5, c.shape.size)
				acabado.z_index = 4
				n.add_child(acabado)
				# Vista 3/4: el frente del muro se dibuja hacia el sur, detrás de Lalo y los muebles.
				var cara := load("res://src/world/pared_v12.gd").new() as Node2D
				cara.name = "CaraV16"
				cara.set("modo", "cara")
				cara.position = c.position
				cara.set("rect", acabado.rect)
				n.add_child(cara)
				var sombra := n.get_node_or_null("Sombra") as LightOccluder2D
				if sombra:
					var r: Rect2 = acabado.rect
					var pol := OccluderPolygon2D.new()
					pol.polygon = PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
					sombra.position = c.position
					sombra.occluder = pol
				cantidad += 1
		else: cantidad += renovar(n)
	return cantidad

func _draw() -> void:
	if modo == "cara":
		dibujar_cara()
		return
	draw_rect(rect, Color("4a4741"))
	var interior := rect.grow(-2)
	if interior.has_area(): draw_rect(interior, Color("8a857b"))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y),Color("b3ad9f"),1)
	draw_line(Vector2(rect.position.x,rect.end.y-2),rect.end-Vector2(0,2),Color("34312c"),3)
	# Juntas alineadas y pequeñas manchas, siempre dentro de la pared física.
	if rect.size.x > rect.size.y:
		for x in range(int(rect.position.x)+48,int(rect.end.x)-2,48):
			draw_line(Vector2(x,rect.position.y+2),Vector2(x,rect.end.y-3),Color("6f6a61"),1)
	else:
		for y in range(int(rect.position.y)+48,int(rect.end.y)-2,48):
			draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color("6f6a61"),1)

	# Grietas y humedad quedan dentro de la silueta física, sin salientes invisibles.
	var horizontal := rect.size.x > rect.size.y
	var largo := rect.size.x if horizontal else rect.size.y
	for i in range(24, int(largo)-12, 83):
		var centro := rect.position + (Vector2(i,rect.size.y*.5) if horizontal else Vector2(rect.size.x*.5,i))
		var grieta := PackedVector2Array([centro+Vector2(-3,-5),centro,centro+Vector2(-2,4)])
		draw_polyline(grieta,Color("273237"),1,true)
		if horizontal:
			draw_rect(Rect2(centro.x-9,rect.end.y-5,18,3),Color(.12,.19,.17,.55))

func dibujar_cara() -> void:
	var horizontal := rect.size.x > rect.size.y
	if not horizontal:
		# Muros verticales: solo sombra de contacto a ambos lados.
		for i in range(4):
			var a: float = 0.2 * (1.0 - i / 4.0)
			draw_rect(Rect2(rect.position.x - 2.0 * (i + 1), rect.position.y, 2.0, rect.size.y), Color(0, 0, 0, a))
			draw_rect(Rect2(rect.end.x + 2.0 * i, rect.position.y, 2.0, rect.size.y), Color(0, 0, 0, a))
		return
	var cara := Rect2(rect.position.x, rect.end.y, rect.size.x, ALTO_CARA)
	# Pintura gastada: más clara arriba, zócalo oscuro abajo.
	draw_rect(cara, Color("cdc8bd"))
	draw_rect(Rect2(cara.position, Vector2(cara.size.x, 3)), Color("e3dfd5"))
	draw_rect(Rect2(cara.position.x, cara.end.y - 6, cara.size.x, 6), Color("6d665b"))
	draw_line(Vector2(cara.position.x, cara.end.y - 6), Vector2(cara.end.x, cara.end.y - 6), Color("4a453d"), 1)
	var azar := RandomNumberGenerator.new()
	azar.seed = int(absf(global_position.x) * 7.0 + absf(global_position.y) * 13.0)
	for x in range(int(cara.position.x) + 48, int(cara.end.x) - 2, 48):
		draw_line(Vector2(x, cara.position.y + 3), Vector2(x, cara.end.y - 6), Color("bdb7ab"), 1)
	# Escurrimientos de humedad y pintura desconchada en posiciones estables.
	for i in range(int(cara.size.x / 70.0)):
		var x: float = cara.position.x + azar.randf_range(8, cara.size.x - 8)
		var largo: float = azar.randf_range(6, ALTO_CARA - 6)
		draw_line(Vector2(x, cara.position.y + 3), Vector2(x, cara.position.y + 3 + largo), Color(0.45, 0.42, 0.35, 0.45), azar.randf_range(1.5, 3.0))
		if azar.randf() < 0.4:
			draw_rect(Rect2(x + 6, cara.position.y + azar.randf_range(5, 14), azar.randf_range(5, 11), azar.randf_range(3, 6)), Color("a59f92"))
	# Sombra de contacto en el piso al pie del zócalo.
	for i in range(5):
		draw_rect(Rect2(cara.position.x, cara.end.y + 2.0 * i, cara.size.x, 2.0), Color(0, 0, 0, 0.26 * (1.0 - i / 5.0)))
