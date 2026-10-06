extends CharacterBody2D

signal ruido_emitido(posicion: Vector2, intensidad: float)
signal recogido(id: String)
@export var tipo: String = "decoracion"
@export var titulo: String = "Objeto"
@export var zona: String = ""
var abierto: bool = false
var ocupado: bool = false
var textura_cerrada: Texture2D
var sombra: LightOccluder2D

func _ready() -> void:
	if tipo == "puerta":
		textura_cerrada = $Sprite.texture
		sombra = LightOccluder2D.new()
		var poligono := OccluderPolygon2D.new()
		poligono.polygon = PackedVector2Array([Vector2(-48,-9), Vector2(48,-9), Vector2(48,9), Vector2(-48,9)])
		sombra.occluder = poligono
		add_child(sombra)
	if tipo != "decoracion":
		add_to_group("interactivos")

func interactuar(jugador: CharacterBody2D) -> String:
	match tipo:
		"puerta":
			if abierto:
				var consulta := PhysicsShapeQueryParameters2D.new()
				var volumen := RectangleShape2D.new()
				volumen.size = Vector2(92, 16)
				consulta.shape = volumen
				consulta.transform = global_transform
				consulta.exclude = [get_rid()]
				consulta.collision_mask = 1
				if not get_world_2d().direct_space_state.intersect_shape(consulta).is_empty():
					return "Hay algo en el marco. Apartalo para cerrar."
			abierto = not abierto
			$Colision.set_deferred("disabled", abierto)
			$Sprite.texture = load("res://assets/puerta_abierta.png") if abierto else textura_cerrada
			sombra.visible = not abierto
			ruido_emitido.emit(global_position, 0.35)
			return "Puerta abierta" if abierto else "Puerta cerrada"
		"empujar":
			var direccion: Vector2 = (global_position - jugador.global_position).normalized()
			move_and_collide(direccion * 32.0)
			ruido_emitido.emit(global_position, 0.7)
			return "Moviste: " + titulo
		"recoger":
			jugador.inventario.append(titulo)
			recogido.emit(titulo)
			queue_free()
			return "Recogido: " + titulo
		"interruptor":
			get_tree().call_group("control", "alternar_zona", zona)
			return "Circuito: " + zona
		"breaker":
			get_tree().call_group("control", "alternar_general")
			return "Cambiaste la alimentacion general."
		"escondite":
			jugador.oculto = not jugador.oculto
			return "Oculto. E para salir." if jugador.oculto else "Saliste del escondite."
	return titulo
