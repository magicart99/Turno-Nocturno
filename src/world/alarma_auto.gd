extends StaticBody2D
var enfriamiento: float = 0.0
func _physics_process(delta: float) -> void:
	var escuela := get_tree().get_first_node_in_group("control")
	if escuela == null or not escuela.jugando: return
	enfriamiento = maxf(0, enfriamiento - delta)
	var p: Vector2 = to_local(escuela.jugador.global_position)
	if absf(p.x) < 57 and absf(p.y) < 95 and escuela.jugador.velocity.length() > 5 and enfriamiento <= 0:
		enfriamiento = 8
		escuela.sonidos.efecto("alarma", global_position, -12)
		escuela.emitir_ruido(global_position, 6.0)
		escuela.jugador.mensaje = "¡Alarma! El Archivero oyó el coche."
		for hijo in get_children():
			if hijo is Sprite2D:
				var t := create_tween().set_loops(6)
				t.tween_property(hijo, "modulate", Color(1.6,0.65,0.4),0.18)
				t.tween_property(hijo, "modulate", Color.WHITE,0.18)
