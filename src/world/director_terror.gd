extends Node2D
## Niebla de patio, Ecos fugaces y oscilación de la única línea alimentada.
var espera: float = 22.0
var oscilacion: float = 0.0
var restaurar: bool = false
var eco: Sprite2D
@onready var escuela: Node2D = get_parent()
func _ready() -> void:z_index=14
func _process(delta: float) -> void:
	queue_redraw()
	if not escuela.jugando:return
	if oscilacion>0:
		oscilacion=maxf(0,oscilacion-delta)
		for l in get_tree().get_nodes_in_group("luces_zona"):
			if l.enabled and l.get_meta("zona","")!="Exterior_Caseta":l.energy=float(l.get_meta("energia_base",.6))*(.15 if sin(escuela.tiempo*47)>0 else .85)
		restaurar=true
	elif restaurar:
		for l in get_tree().get_nodes_in_group("luces_zona"):l.energy=float(l.get_meta("energia_base",.6))
		restaurar=false
	if escuela.campana.gracia_activa() or escuela.peligro>.6:return
	espera-=delta
	if espera<=0:
		espera=randf_range(26,42)
		manifestacion()
func manifestacion() -> void:
	if is_instance_valid(eco):return
	var j: CharacterBody2D=escuela.jugador
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new();forma.radius=18
	consulta.shape=forma;consulta.collision_mask=1;consulta.exclude=[j.get_rid(),escuela.archivero.get_rid()]
	for i in range(8):
		var p: Vector2=j.global_position+Vector2.from_angle(randf()*TAU)*randf_range(210,300)
		consulta.transform=Transform2D(0,p)
		var rayo := PhysicsRayQueryParameters2D.create(j.global_position,p,1,[j.get_rid(),escuela.archivero.get_rid()])
		if not get_world_2d().direct_space_state.intersect_shape(consulta).is_empty() or not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():continue
		eco=Sprite2D.new();eco.texture=preload("res://assets/sprites/eco_computo.png");eco.position=p;eco.scale=Vector2.ONE*.23;eco.modulate=Color(.64,.68,.66,0)
		add_child(eco)
		var t := create_tween();t.tween_property(eco,"modulate:a",.48,.45);t.parallel().tween_property(eco,"position:y",p.y-14,1.4);t.tween_property(eco,"modulate:a",0.0,.7);t.tween_callback(eco.queue_free)
		escuela.sonidos.efecto("eco_%d" % randi_range(1,5),p,-18)
		if randf() < 0.5: escuela.sonidos.efecto("papeles",p+Vector2(65,20),-16)
		escuela.mente.presenciar(8.0)
		oscilacion=.65
		return
	escuela.sonidos.efecto("metal",j.position+Vector2(140,-60),-18)
func _draw() -> void:
	if escuela.campana==null:return
	var p: Vector2=escuela.jugador.position
	for i in range(7):
		var centro := p+Vector2(sin(escuela.tiempo*.035+i*1.7)*450,cos(i*2.7)*280)
		draw_circle(centro,190+i*13,Color(.38,.44,.49,.012))
