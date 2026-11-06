extends Node2D
## Señalética y juntas originales. Solo dibujo: no modifica pasos ni colisiones.
func _ready() -> void:
	z_index = -4
func _draw() -> void:
	# Bordes del andador: volumen bajo y línea de orientación hacia servicios.
	for x in [980,1488]:
		draw_line(Vector2(x+4,1240),Vector2(x+4,2460),Color("182d3a"),12)
		draw_line(Vector2(x,1240),Vector2(x,2460),Color("8babb0"),4)
	for y in range(1480,2370,96):
		draw_rect(Rect2(1110,y,110,62),Color("794453"))
		draw_line(Vector2(1114,y+3),Vector2(1216,y+3),Color("b4797b"),2)
		draw_line(Vector2(1114,y+60),Vector2(1216,y+60),Color("432b3b"),3)
	for y in range(1510,2300,240):
		var p := Vector2(1370,y)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-14),p+Vector2(-14,7),p+Vector2(-5,7),p+Vector2(-5,18),p+Vector2(5,18),p+Vector2(5,7),p+Vector2(14,7)]),Color("b9b99a"))
	# Franja de seguridad en la entrada y bancos de luces a ras del suelo.
	for y in range(2010,2150,22):
		draw_line(Vector2(1510,y),Vector2(1570,y-16),Color("d0aa6b"),7)
	for p in [Vector2(994,1570),Vector2(1476,1780),Vector2(994,2200),Vector2(1476,2360)]:
		draw_rect(Rect2(p-Vector2(7,16),Vector2(14,32)),Color("152b37"))
		draw_rect(Rect2(p-Vector2(3,12),Vector2(6,24)),Color("8bc5c3"))
	for dato in [[Vector2(1250,1405),"03  SERVICIOS ↑"],[Vector2(1260,2330),"04  VIGILANCIA ↓"],[Vector2(1350,2000),"01  PRINCIPAL →"]]:
		draw_string(ThemeDB.fallback_font,dato[0],dato[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("c4d1c6"))
	# Islas de vegetación, fuera del paso central.
	for p in [Vector2(820,1510),Vector2(770,1810),Vector2(740,2280)]:
		draw_style_box(jardin(),Rect2(p,Vector2(125,85)))
		for i in range(5):
			var c: Vector2 = p+Vector2(20+i*21,42+sin(i*2)*12)
			draw_circle(c+Vector2(3,6),18,Color("18332f"))
			draw_circle(c,16,Color("547763"))
			draw_arc(c,11,PI,TAU,12,Color("809376"),3,true)
func jardin() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color("243b3d")
	s.border_color=Color("6a8583")
	s.set_border_width_all(5)
	s.set_corner_radius_all(16)
	return s
