extends Area2D
## Se rearma al alejarse, para que cerrar la mochila no la abra cada fotograma.
var esperando := false
var dentro := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(130,60)
	col.shape = rect
	add_child(col)
	body_entered.connect(func(body: Node2D):
		if body == get_tree().get_first_node_in_group("control").jugador:
			dentro = true)
	body_exited.connect(func(body: Node2D):
		if body == get_tree().get_first_node_in_group("control").jugador:
			dentro = false
			esperando = false)

func _process(_delta: float) -> void:
	var e := get_tree().get_first_node_in_group("control")
	if dentro and not esperando and e.jugando and not e.transicion:
		esperando = true
		e.abrir_tienda()
