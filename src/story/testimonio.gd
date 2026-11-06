extends StaticBody2D
## Microescena opcional: escuchar en vez de recoger; se puede abandonar libremente.
var tipo := "campana"
var titulo := "Escuchar el recuerdo"
var numero := 1
var lugar := "principal"
var frase := ""
var esperando := false
var progreso := 0.0
var origen := Vector2.ZERO
var escuela: Node2D
var rotulo: Label
func _ready() -> void:
	collision_layer=0;escuela=get_parent();add_to_group("interactivos");add_to_group("recuerdos")
	rotulo=Label.new();rotulo.text="REC / %02d"%numero;rotulo.position=Vector2(-32,-48)
	rotulo.add_theme_font_override("font",preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"));rotulo.add_theme_font_size_override("font_size",18)
	rotulo.modulate=Color("b7c7b4");add_child(rotulo)
func marca() -> String:return "testimonio_%d"%numero
func interactuar(_j: CharacterBody2D) -> String:
	if escuela.campana.hechos.get(marca(),false):escuela.relato.decir(frase);return "Testimonio conservado en la mochila."
	escuela.interfaz.elegir("NO ES UNA GRABACIÓN", "El sonido viene del suelo, pero solo aparece cuando apagas la linterna.\nPermanece aquí cinco segundos sin moverte para escuchar. Puedes alejarte en cualquier momento.", ["Escuchar · apagar la linterna", "Seguir mi camino"],func(i: int):
		if i==0:
			escuela.jugador.linterna=false;esperando=true;progreso=0;origen=escuela.jugador.position
	)
	return "Una voz está intentando terminar una frase."
func _process(delta: float) -> void:
	visible=escuela.campana.lugar==lugar and escuela.campana.etapa>=numero
	if not visible:esperando=false;return
	if not escuela.jugando:return
	if esperando:
		var j: CharacterBody2D=escuela.jugador
		if j.linterna or j.position.distance_to(origen)>20 or j.oculto or j.accion!="":
			esperando=false;progreso=0;j.mensaje="El recuerdo se desvaneció. Puedes intentarlo de nuevo."
		else:
			progreso+=delta;j.mensaje="ESCUCHANDO · %d / 5 s · no enciendas la linterna"%mini(5,int(progreso))
			if progreso>=5:
				esperando=false;escuela.campana.hechos[marca()]=true
				escuela.relato.decir(frase);escuela.mente.presenciar(20)
				escuela.sonidos.efecto("eco_%d"%numero,global_position,-24)
				j.mensaje="Testimonio recuperado. Puedes leerlo en I / Y → Testimonios."
	queue_redraw()
func _draw() -> void:
	var color:=Color("d5b478") if esperando else Color("536b69")
	draw_circle(Vector2.ZERO,18,Color(.03,.06,.07,.5))
	draw_arc(Vector2.ZERO,18,0,TAU,24,color,1.5,true)
	for i in range(7):
		var altura: float=4+absf(sin(escuela.tiempo*2+i))*10 if esperando else 3+absf(sin(i*2))*8
		draw_line(Vector2(-12+i*4,-altura/2),Vector2(-12+i*4,altura/2),color,2)
	if esperando:draw_arc(Vector2.ZERO,23,-PI/2,-PI/2+TAU*minf(1,progreso/5),32,Color("b7c7b4"),2,true)
