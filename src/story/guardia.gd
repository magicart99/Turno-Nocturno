extends Node2D
var animacion: AnimatedSprite2D
var reloj: float = 0.0
func _ready() -> void:
	animacion = preload("res://src/player/animacion_personaje.gd").crear("guardia")
	animacion.scale = Vector2.ONE * 0.25
	animacion.offset = Vector2(0, -152)
	add_child(animacion)

func _process(delta: float) -> void:
	var escuela := get_tree().get_first_node_in_group("control")
	if not escuela.jugando: return
	reloj += delta
	var direccion: Vector2 = escuela.jugador.global_position - global_position
	if direccion.length() < 230:
		preload("res://src/player/animacion_personaje.gd").mover(animacion, direccion.normalized() * 4)
		animacion.speed_scale = 0.35
	else:
		animacion.play("left" if sin(reloj * 0.2) > 0 else "down")
		animacion.speed_scale = 0.22
