extends SceneTree

func _initialize() -> void:
	call_deferred("exportar")

func asignar_propietario(nodo: Node, propietario: Node) -> void:
	for hijo in nodo.get_children():
		hijo.owner = propietario
		asignar_propietario(hijo, propietario)

func exportar() -> void:
	var principal: Node2D = load("res://scenes/escuela.tscn").instantiate()
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/distribucion.json"))
	DirAccess.make_dir_recursive_absolute("res://scenes/secciones")
	for sala in datos.rooms:
		var nueva := Node2D.new()
		nueva.name = sala.name
		var origen := Vector2(sala.x, sala.y)
		var limites := Rect2(origen, Vector2(sala.w, sala.h))
		for categoria in ["Pisos", "Paredes", "Objetos", "Iluminacion", "Rotulos"]:
			var grupo := Node2D.new()
			grupo.name = categoria
			nueva.add_child(grupo)
			for hijo in principal.get_node(categoria).get_children():
				var dentro: bool = limites.has_point(hijo.position)
				if categoria == "Pisos" or categoria == "Rotulos":
					dentro = hijo.name == sala.name
				if dentro:
					var copia: Node2D
					if hijo is Label:
						continue
					copia = hijo.duplicate()
					copia.position -= origen
					grupo.add_child(copia)
		asignar_propietario(nueva, nueva)
		var packed := PackedScene.new()
		packed.pack(nueva)
		var error := ResourceSaver.save(packed, "res://scenes/secciones/" + str(sala.name) + ".tscn")
		assert(error == OK)
		nueva.free()
	principal.free()
	print("17 escenas de secciones exportadas")
	quit()
