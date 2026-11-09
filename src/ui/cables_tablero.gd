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
	# Cable suelto que Lalo sostiene: sigue al puntero o al terminal enfocado.
	if tablero.elegido >= 0 and not tablero.terminado:
		var origen := Vector2(178,181+tablero.elegido*108)
		var fin: Vector2 = tablero.punto_vivo().clamp(Vector2(10,10), size-Vector2(10,10))
		var vivo := PackedVector2Array()
		for paso in range(25):
			var t: float = paso/24.0
			vivo.append(origen.bezier_interpolate(origen+Vector2(110,40),fin+Vector2(-80,30),fin,t))
		var tono: Color = tablero.COLORES[tablero.elegido]
		var pulso: float = 0.5+0.5*sin(Time.get_ticks_msec()*.012)
		draw_polyline(vivo,Color("03090e"),14,true)
		draw_polyline(vivo,tono.darkened(.25),8,true)
		draw_polyline(vivo,tono.lightened(.35),2,true)
		draw_circle(fin,6+pulso*2,tono.lightened(.3))
		draw_circle(fin,12+pulso*6,Color(tono,.15))
	for c in tablero.chispas:
		var p: Vector2 = c["p"]
		var v: Vector2 = c["v"]
		var vida: float = clampf(float(c["t"])/0.3,0,1)
		var brillo: Color = c["c"]
		draw_line(p,p-v*0.035,Color(brillo,vida),2.0)
	# Interferencia del susto: algo escribe desde dentro de la caja.
	if tablero.glitch > 0:
		var g: float = clampf(tablero.glitch,0,1)
		for i in range(7):
			draw_rect(Rect2(0,randf_range(0,size.y),size.x,randf_range(2,10)),Color(.9,.1,.12,.16*g))
		draw_string(tablero.FUENTE_TITULO,Vector2(110+randf_range(-6,6),340+randf_range(-4,4)),"NO LO CONECTES",HORIZONTAL_ALIGNMENT_LEFT,-1,46,Color(.95,.15,.12,.85*g))
