extends Control
var tablero: CanvasLayer
var fondo: Texture2D = preload("res://assets/sprites/ui/tablero_usuario.png")
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_texture_rect(fondo,Rect2(0,0,625,648),false)
	draw_rect(Rect2(187,111,260,461),Color("08141a"))
	draw_rect(Rect2(483,43,118,43),Color("071713"))
	for i in range(4):
		var a := Vector2(178,181+i*108)
		var b := Vector2(450,181+tablero.orden.find(i)*108)
		var conectado: bool = i in tablero.conectados
		var ruta := PackedVector2Array()
		for paso in range(41):
			var t: float=paso/40.0
			ruta.append(a.bezier_interpolate(a+Vector2(140,30),b-Vector2(140,30),b,t))
		if not conectado:
			ruta.resize(10)
		var color: Color=tablero.COLORES[i]
		draw_rect(Rect2(b-Vector2(19,36),Vector2(34,72)),Color("152b33"))
		draw_rect(Rect2(b-Vector2(12,28),Vector2(23,56)),color.darkened(.42))
		draw_polyline(ruta,Color("03090e"),16,true)
		draw_polyline(ruta,color.darkened(.45 if not conectado else .13),10,true)
		draw_polyline(ruta,color.lightened(.25),2,true)
		for p in [a,b]:
			draw_rect(Rect2(p-Vector2(7,13),Vector2(14,26)),Color("576866"))
			draw_circle(p,4,color)
		if conectado:
			var indice: int=int(fmod(Time.get_ticks_msec()*.014+i*7,40))
			draw_circle(ruta[indice],4,Color("d1f8df"))
		elif tablero.elegido==i:draw_circle(a,10,color,false,2)
