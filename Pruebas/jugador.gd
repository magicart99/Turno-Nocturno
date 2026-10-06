extends CharacterBody2D

var inventario: Array[String] = []
var oculto: bool = false
var linterna: bool = true
var ruido: float = 0.0
var ultimo_escondite: Node2D
var mensaje: String = "Explora la escuela. Los interruptores estan junto a las puertas."
var direccion: String = "sur"

func _physics_process(_delta: float) -> void:
	var entrada := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	var correr := Input.is_action_pressed("correr")
	velocity = entrada * (210.0 if correr else 125.0) if not oculto else Vector2.ZERO
	move_and_slide()
	ruido = (1.0 if correr else 0.25) if velocity.length() > 0 else 0.0
	$Sprite.modulate.a = 0.25 if oculto else 1.0
	$Linterna.enabled = linterna and not oculto
	if entrada.length() > 0:
		var nueva := "este" if entrada.x > 0 else "oeste"
		if abs(entrada.y) >= abs(entrada.x):
			nueva = "sur" if entrada.y > 0 else "norte"
		if nueva != direccion:
			direccion = nueva
			$Sprite.texture = load("res://assets/lalo_" + direccion + ".png")
	$Linterna.rotation = (get_global_mouse_position() - global_position).angle()
	if Input.is_action_just_pressed("linterna"):
		linterna = not linterna
	if Input.is_action_just_pressed("interactuar"):
		var objetivo: Node2D = ultimo_escondite if oculto else mas_cercano()
		if is_instance_valid(objetivo):
			mensaje = objetivo.interactuar(self)
			if oculto:
				ultimo_escondite = objetivo

func mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var distancia: float = 98.0
	for candidato in get_tree().get_nodes_in_group("interactivos"):
		var d: float = global_position.distance_to(candidato.global_position)
		if d >= distancia:
			continue
		var consulta := PhysicsRayQueryParameters2D.create(global_position, candidato.global_position, 1, [get_rid()])
		var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
		if not impacto.is_empty() and impacto.collider != candidato:
			continue
		distancia = d
		mejor = candidato
	return mejor
