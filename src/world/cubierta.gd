extends Sprite2D
## Los techos y copas nunca ocultan a Lalo ni bloquean el paso por su imagen.
var arbol: bool = false
func _ready() -> void:
	arbol = texture != null and texture.resource_path.ends_with("arbol.svg")
func _process(delta: float) -> void:
	var escuela := get_tree().get_first_node_in_group("control")
	if escuela == null: return
	var cerca: bool = global_position.distance_to(escuela.jugador.global_position) < 175
	modulate.a = move_toward(modulate.a, 0.20 if cerca else 0.88, delta * 3.0)
	if arbol: rotation = sin(escuela.tiempo * 1.2 + global_position.y * .003) * .014
