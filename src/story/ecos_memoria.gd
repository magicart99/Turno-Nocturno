extends Node2D
## Detalles sin colisiones: desgaste y pistas visuales en los cuatro capítulos.
var escuela: Node2D
const RELATOS = [
 "AULA / 01 · Nos pidieron quedarnos para corregir una lista. Cuando terminó el pase, los ausentes seguíamos dentro.",
 "PATIO / 02 · Conté cuatro pasos detrás de mí. Me detuve. El quinto paso sonó desde mi propia sombra.",
 "SERVICIOS / 03 · La última charola estaba caliente. En el ticket decía mi nombre y una fecha de mañana.",
 "VIGILANCIA / 04 · Chuy no olvidó abrirnos. Alguien cambió la palabra SALIDA por BAJA. Haz que vuelva a leer nuestros nombres."
]
const POSICIONES = [Vector2(1350,670),Vector2(1200,2089),Vector2(1460,1000),Vector2(1840,2719)]
func _ready() -> void:
	escuela=get_parent();z_index=1
	for i in range(4):
		var eco:=preload("res://src/story/testimonio.gd").new()
		eco.name="Testimonio%d"%(i+1);eco.numero=i+1;eco.lugar="principal" if i==0 else "campus"
		eco.frase=RELATOS[i];eco.position=POSICIONES[i];eco.titulo="Recuerdo %02d · escuchar"%(i+1)
		escuela.call_deferred("add_child",eco)
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(escuela) or escuela.campana==null:return
	var principal: bool=escuela.campana.lugar=="principal"
	var cerca: Vector2=escuela.jugador.position
	var centros: Array=[Vector2(500,670),Vector2(1350,670),Vector2(2250,670),Vector2(3100,670)] if principal else [Vector2(1200,2089),Vector2(1050,1673),Vector2(1460,1000),Vector2(1840,2719)]
	for centro in centros:
		if centro.distance_to(cerca)>1100:continue
		# Papeles y marcas discontinuas sugieren pasos hacia las voces.
		for i in range(7):
			var p: Vector2=centro+Vector2(i*25-80,sin(i*2.8)*26)
			draw_set_transform(p,sin(i*3.1)*.4)
			draw_rect(Rect2(-4,-6,8,12),Color(.55,.58,.46,.38))
			draw_line(Vector2(-2,-2),Vector2(2,-2),Color(.10,.17,.19,.6),1)
		draw_set_transform(Vector2.ZERO)
		draw_line(centro+Vector2(-140,42),centro+Vector2(90,42),Color("536b69"),2)
		draw_line(centro+Vector2(90,42),centro+Vector2(120,30),Color("536b69"),2)
		var mensaje: String="PRESENTE" if escuela.jugador.cordura>=45 else "¿PRESENTE?"
		draw_string(preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"),centro+Vector2(-45,52),mensaje,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.72,.78,.70,.42))
