extends StaticBody2D
## Distracción opcional: anuncia desde un lugar fijo después de permitir alejarse.
var tipo := "campana"
var titulo := "Altavoz · programar aviso"
var pendiente := 0.0
var descanso := 0.0
var escuela: Node2D
func _ready() -> void:
	collision_layer=0
	escuela=get_tree().get_first_node_in_group("control")
	add_to_group("interactivos")
	var nombre := Label.new()
	nombre.text="AVISOS";nombre.position=Vector2(-24,-42)
	nombre.add_theme_font_size_override("font_size",11)
	add_child(nombre)
func interactuar(_jugador: CharacterBody2D) -> String:
	if pendiente>0:return "Aviso programado. Aléjate sin correr."
	if descanso>0:return "El altavoz se está enfriando: %d s."%ceili(descanso)
	escuela.interfaz.elegir("CONTROL DE AVISOS", "La lista de asistencia todavía está grabada. Puedes reproducirla dentro de tres segundos para atraer al Archivero aquí.\nBusca un refugio o aprovecha para cruzar el pasillo.", ["Programar aviso · 3 segundos", "Dejar en silencio"],func(i: int):
		if i==0:
			pendiente=3.0
			escuela.jugador.mensaje="Aviso en 3 segundos. Aléjate en silencio."
	)
	return "Altavoz escolar: distracción con retardo."
func _process(delta: float) -> void:
	if not escuela.jugando:return
	descanso=maxf(0,descanso-delta)
	if pendiente>0:
		pendiente=maxf(0,pendiente-delta)
		if pendiente==0:
			escuela.sonidos.efecto("radio_estatica",global_position,-12)
			escuela.emitir_ruido(global_position,1.3)
			descanso=25
			escuela.relato.decir("ALTAVOZ · Lista de asistencia… Lalo: presente. Los demás nombres se pierden entre interferencias.")
	queue_redraw()
func _draw() -> void:
	draw_style_box(estilo(),Rect2(-20,-24,40,32))
	for i in range(5):draw_line(Vector2(-13,-18+i*4),Vector2(9,-18+i*4),Color("58717a"),1.5)
	draw_circle(Vector2(14,-16),2,Color("efc76a") if pendiente>0 else Color("74b8a0"))
func estilo() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color=Color("15232d");caja.border_color=Color("7c9299")
	caja.set_border_width_all(2);caja.set_corner_radius_all(3)
	return caja
