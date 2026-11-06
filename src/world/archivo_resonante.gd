extends Node2D
## El campus devuelve los pasos que registró, sin conocer posiciones futuras.
var ecos: Array[Dictionary] = []
var enfriamiento := 0.0
var zona := ""
var muestreo := 0.0
var rastro: Array[Vector2] = []
@onready var e: Node2D = get_parent()

func registrar(p: Vector2, intensidad: float) -> void:
	if intensidad < 0.5 or enfriamiento > 0 or e.campana.gracia_activa(): return
	if ecos.size() >= 3: return
	ecos.append({"pos":p,"resta":randf_range(7,12),"zona":e.campana.lugar})
	enfriamiento = 9.0
	e.jugador.mensaje = "La escuela ha registrado tus pasos. Algo los repetirá."

func _process(delta: float) -> void:
	if not e.jugando: return
	if zona != e.campana.lugar:
		zona = e.campana.lugar
		ecos.clear()
		rastro.clear()
	enfriamiento = maxf(0,enfriamiento-delta)
	for i in range(ecos.size()-1,-1,-1):
		ecos[i].resta -= delta
		if ecos[i].resta <= 0:
			var p: Vector2 = ecos[i].pos
			e.sonidos.efecto("paso_archivero",p,-15)
			e.archivero.escuchar(p,0.65)
			ecos.remove_at(i)
	muestreo -= delta
	if muestreo <= 0:
		muestreo = 0.45
		explorar()
		if rastro.is_empty() or rastro.back().distance_to(e.jugador.position)>20:
			rastro.append(e.jugador.position)
			if rastro.size()>14: rastro.pop_front()
	queue_redraw()

func explorar() -> void:
	var centro := Vector2i(e.jugador.position / 128.0)
	for x in range(-2,3):
		for y in range(-2,3):
			var celda := centro+Vector2i(x,y)
			var p := Vector2(celda)*128+Vector2(64,64)
			if p.distance_to(e.jugador.position)>280: continue
			var ray := PhysicsRayQueryParameters2D.create(e.jugador.position,p,1,[e.jugador.get_rid(),e.archivero.get_rid()])
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				e.campana.explorados["%s:%d:%d" % [zona,celda.x,celda.y]] = true

func _draw() -> void:
	if not e.jugando or e.jugador.cordura>60: return
	# Huellas imposibles: persisten sobre el trayecto reciente.
	for i in range(rastro.size()):
		var alpha: float = (1.0-e.jugador.cordura/60.0)*0.16*float(i+1)/maxi(1,rastro.size())
		draw_ellipse_foot(rastro[i],alpha,i)

func draw_ellipse_foot(p: Vector2, alpha: float, i: int) -> void:
	draw_rect(Rect2(p+Vector2(-7 if i%2==0 else 4,-2),Vector2(3,7)),Color(.6,.72,.69,alpha))
