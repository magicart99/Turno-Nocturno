extends SceneTree

var fallos: int = 0
func comprobar(condicion: bool, descripcion: String) -> void:
	if not condicion:
		fallos += 1
		push_error(descripcion)
	else:
		print("OK: " + descripcion)

func _initialize() -> void:
	call_deferred("ejecutar")

func ejecutar() -> void:
	var escena: Node2D = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	await physics_frame
	await physics_frame
	var jugador: CharacterBody2D = escena.get_node("Jugador")
	var puerta: CharacterBody2D
	var mueble: CharacterBody2D
	var item: CharacterBody2D
	var escondite: CharacterBody2D
	for objeto in get_nodes_in_group("interactivos"):
		match objeto.tipo:
			"puerta": puerta = objeto
			"empujar": mueble = objeto
			"recoger": item = objeto
			"escondite": escondite = objeto
	comprobar(is_instance_valid(puerta), "Puertas instanciadas")
	puerta.interactuar(jugador)
	await physics_frame
	comprobar(puerta.abierto and puerta.get_node("Colision").disabled, "Abrir puerta desactiva colision")
	puerta.interactuar(jugador)
	await physics_frame
	comprobar(not puerta.abierto and not puerta.get_node("Colision").disabled, "Cerrar puerta restaura colision")
	for objeto in get_nodes_in_group("interactivos"):
		if objeto.tipo == "puerta":
			objeto.interactuar(jugador)
			await physics_frame
			objeto.interactuar(jugador)
			await physics_frame
			comprobar(not objeto.abierto, "Cierre sin bloqueo falso: " + objeto.titulo)
	jugador.global_position = Vector2(1900, 730)
	mueble.global_position = Vector2(1950, 730)
	await physics_frame
	var antes: Vector2 = mueble.global_position
	mueble.interactuar(jugador)
	comprobar(mueble.global_position.distance_to(antes) > 10, "Mueble se mueve mediante colision fisica")
	var cantidad: int = jugador.inventario.size()
	item.interactuar(jugador)
	comprobar(jugador.inventario.size() == cantidad + 1, "Objeto se agrega al inventario")
	escondite.interactuar(jugador)
	comprobar(jugador.oculto, "Entrar en escondite")
	escondite.interactuar(jugador)
	comprobar(not jugador.oculto, "Salir de escondite")
	escena.modo_luz(1)
	var apagadas: bool = true
	for luz in get_nodes_in_group("luces_zona"):
		apagadas = apagadas and not luz.enabled
	comprobar(apagadas, "Apagon apaga los 27 circuitos de luz ambiental")
	escena.alternar_zona("Entrada")
	comprobar(escena.zonas["Entrada"], "Interruptor restaura zona individual")
	escena.modo_luz(2)
	comprobar(escena.zonas["Entrada"] and not escena.zonas["Computo"], "Modo mixto conserva zonas distintas")
	var dir := DirAccess.open("res://scenes")
	for archivo in dir.get_files():
		if archivo.begins_with("obj_") and archivo.ends_with(".tscn"):
			var recurso: PackedScene = load("res://scenes/" + archivo)
			comprobar(recurso != null, "Escena reutilizable: " + archivo)
	if "--capturas" in OS.get_cmdline_user_args():
		escena.free()
		escena = load("res://scenes/escuela.tscn").instantiate()
		root.add_child(escena)
		await process_frame
		escena.get_node("Interfaz").hide()
		escena.get_node("Jugador/Camera2D").enabled = false
		escena.get_node("VistaGeneral").enabled = true
		for modo in range(3):
			escena.modo_luz(modo)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://vistas/godot_modo_" + str(modo) + ".png")
	print("RESULTADO: " + str(fallos) + " fallos")
	var registro := FileAccess.open("res://docs/verificacion_godot.txt", FileAccess.WRITE)
	registro.store_string("Motor: " + str(Engine.get_version_info().string) + "\nFallos: " + str(fallos) + "\nPruebas: puertas, cierre con deteccion de cuerpos, empuje, inventario, ocultacion, apagon, circuito individual, modo mixto, escenas reutilizables.\n")
	quit(fallos)
