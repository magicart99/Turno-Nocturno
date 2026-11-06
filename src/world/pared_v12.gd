extends Node2D
## La misma silueta define dibujo, colisión y sombra; sin texturas estiradas.
var rect := Rect2()

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
	draw_rect(rect, Color("37444a"))
	var interior := rect.grow(-2)
	if interior.has_area(): draw_rect(interior, Color("586166"))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y),Color("7b817b"),1)
	draw_line(Vector2(rect.position.x,rect.end.y-2),rect.end-Vector2(0,2),Color("202d34"),3)
	# Juntas alineadas y pequeñas manchas, siempre dentro de la pared física.
	if rect.size.x > rect.size.y:
		for x in range(int(rect.position.x)+48,int(rect.end.x)-2,48):
			draw_line(Vector2(x,rect.position.y+2),Vector2(x,rect.end.y-3),Color("465158"),1)
	else:
		for y in range(int(rect.position.y)+48,int(rect.end.y)-2,48):
			draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color("465158"),1)

	# Grietas y humedad quedan dentro de la silueta física, sin salientes invisibles.
	var horizontal := rect.size.x > rect.size.y
	var largo := rect.size.x if horizontal else rect.size.y
	for i in range(24, int(largo)-12, 83):
		var centro := rect.position + (Vector2(i,rect.size.y*.5) if horizontal else Vector2(rect.size.x*.5,i))
		var grieta := PackedVector2Array([centro+Vector2(-3,-5),centro,centro+Vector2(-2,4)])
		draw_polyline(grieta,Color("273237"),1,true)
		if horizontal:
			draw_rect(Rect2(centro.x-9,rect.end.y-5,18,3),Color(.12,.19,.17,.55))
