extends SceneTree
## v17: salones renovados, HUD, puntos seguros, tutorial, Cómputo, gafete, bucle y atuendos.
## godot --headless --path . --script res://tests/probar_mejoras_v17.gd
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ")+texto)
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func buscar(titulo: String) -> Node:
	for n in e.get_node("Objetos").get_children():
		if n.get("titulo") == titulo: return n
	return null
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://partidas/prueba_v17.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	await esperar(4)
	var j: CharacterBody2D = e.jugador
	var a: CharacterBody2D = e.archivero
	var c: Node = e.campana
	# Salones
	var piso: Sprite2D = e.get_node("Pisos").get_child(0)
	check("vitropiso" in piso.texture.resource_path, "Vitropiso crema en el interior")
	var silla: Node = buscar("Silla")
	check(silla.get_node("Sprite").texture.resource_path.ends_with("pupitre.png"), "Las sillas son pupitres negros")
	var mesa: Node = buscar("Mesa escolar")
	check(not mesa.get_node("Sprite").visible and mesa.get_node("Colision").disabled, "La mesa separada desaparece")
	var climas := 0
	for n in e.get_node("DetallesPrincipal").get_children():
		if str(n.name).begins_with("Minisplit_"): climas += 1
	check(climas >= 10, "Minisplit en cada salón (%d)" % climas)
	var puerta: Node = buscar("Puerta: Aula_01")
	check(puerta.vidrio and not puerta.sombra.visible, "Puertas de aula de vidrio")
	puerta.establecer_puerta(true)
	check(puerta.get_node("Sprite").texture == puerta.textura_abierta, "Puerta de vidrio abierta usa su textura")
	puerta.establecer_puerta(false)
	check(e.guardar_partida(), "Guardar funciona con el mobiliario nuevo")
	# HUD
	e.interfaz._process(0.016)
	check(e.interfaz.hud_estado.visible and not e.interfaz.barras.visible, "Panel de estado sustituye la línea de texto")
	# Puntos seguros y gafete
	var seguro: Node2D = null
	for n in e.get_tree().get_nodes_in_group("puntos_seguros"):
		if n.lugar == "principal": seguro = n
	check(seguro != null and e.en_punto_seguro(seguro.global_position), "Punto seguro en la sala de espera")
	a.activo = true; a.estado = "PATRULLANDO"; a.position = seguro.global_position + Vector2(200, 0)
	a.escuchar(seguro.global_position, 1.0)
	check(a.estado == "PATRULLANDO", "El Archivero no oye lo que pasa en un punto seguro")
	a.ignorar = 12.0
	a.escuchar(a.global_position + Vector2(40, 0), 1.0)
	check(a.estado == "PATRULLANDO", "Con el gafete el Archivero ignora a Lalo")
	a.ignorar = 0.0; a.activo = false; a.estado = "DORMIDO"
	# Tutorial
	var tutorial: Node = e.get_children().filter(func(n): return n.get_script() == load("res://src/ui/tutorial.gd"))[0]
	tutorial.espera = 0.0
	tutorial._process(0.016)
	check(c.hechos.get("tut_mover", false), "El tutorial muestra su primer consejo")
	# Cómputo: asustarla delata a Lalo
	j.inventario.assign(["Llave maestra", "Expediente de Lalo"])
	e.alimentar_zona("Computo")
	j.cordura = 80.0
	c.interactuar("computo"); await esperar()
	var botones: Array = e.interfaz.columna.get_children().filter(func(n): return n is Button)
	botones[2].pressed.emit(); await esperar()
	check(not c.hechos.get("computo", false) and j.cordura < 80.0, "Asustar a la de Cómputo no resuelve el bucle y cuesta cordura")
	c.interactuar("computo"); await esperar()
	botones = e.interfaz.columna.get_children().filter(func(n): return n is Button)
	botones[0].pressed.emit(); await esperar()
	check(c.hechos.get("computo", false), "Enviar su examen rompe el bucle")
	# Bucle del pasillo
	j.inventario.clear(); c.etapa = 1
	var director: Node = e.get_children().filter(func(n): return n.get_script() == load("res://src/world/director_terror.gd"))[0]
	j.global_position = Vector2(3100, 670); j.velocity = Vector2(100, 0)
	director.revisar_bucle()
	check(j.global_position.x < 2400.0, "Sin la llave el pasillo vuelve a empezar")
	j.inventario.append("Llave maestra"); j.global_position = Vector2(3100, 670)
	director.revisar_bucle()
	check(j.global_position.x > 3000.0, "Con la llave el bucle se rompe")
	# Atuendos
	j.vestir(1)
	check(j.sprite.material is ShaderMaterial and j.mezcla.material == j.sprite.material, "El atuendo se aplica al sprite y a su fundido")
	j.vestir(0)
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free(); await esperar(); quit(fallos)
