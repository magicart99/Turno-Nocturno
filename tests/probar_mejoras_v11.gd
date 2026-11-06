extends SceneTree
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func foto(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v11/" + nombre + ".png")
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://docs/mejoras_v11/guardado_prueba.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.set_physics_process(false); e.archivero.activo = false
	e.mente.set_process(false)
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	e.campana.monedas = 8
	e.campana.interactuar("tienda")
	await esperar()
	check(not e.jugando and e.interfaz.menu_actual == "tienda", "Tienda pausa el mundo")
	var ui: CanvasLayer = e.inventario_ui
	for bus in ["Música", "Ambiente", "SFX", "Voces"]:
		check(AudioServer.get_bus_index(bus) > 0, "Bus " + bus)
	check(e.sonidos.capas.size() == 4, "Cuatro ambientes")
	e.jugador.position = Vector2(3000,200)
	check(root.get_node("AudioManager").zona(e) == "banos", "Detección de baños")
	check(e.jugador.sonido_paso() == "paso_baldosa", "Pasos de baldosa")
	e.jugador.position = Vector2(1000,640)
	check(ui.objetos.size() == 8, "Ocho productos con imágenes")
	ui.seleccionar("Coca-Cola")
	await esperar(20); await foto("cafeteria_productos")
	check(e.puede_guardar(), "Puede guardar compras al cerrar desde tienda segura")
	for item in ui.objetos:
		check(load("res://assets/sprites/" + ui.datos(item)[0]) is Texture2D, "Imagen de " + item)
		ui.seleccionar(item); ui.utilizar()
		check(j.inventario.count(item) == 1, "Compra una unidad: " + item)
	check(e.campana.monedas == 0, "Todos cuestan exactamente un peso")
	ui.utilizar()
	check(e.campana.monedas == 0 and j.inventario.size() == 8, "Sin saldo no compra ni duplica")
	await foto("cafeteria")
	e.continuar(); await esperar()
	check(e.jugando and not is_instance_valid(e.inventario_ui), "Cerrar tienda devuelve el control")
	j.cordura = 80; j.energia = 90; j.sigilo = 90
	var productos = load("res://src/world/productos_cafeteria.gd")
	check(productos.consumir(e, "Marías Gamesa"), "Consumir galletas")
	check(j.cordura == 100 and j.energia == 100, "Recuperación limitada a 100")
	check(not productos.consumir(e, "Sabritas Original"), "No desperdicia comida con medidor lleno")
	j.energia = 10; j.sigilo = 20; j.sigilo_agotado = true
	check(productos.consumir(e, "Coca-Cola"), "Consumir refresco")
	check(j.energia == 60 and j.sigilo == 40 and not j.sigilo_agotado and e.campana.refresco == 45, "Refresco recupera resistencia, sigilo y activa efecto")
	check(e.guardar_partida(), "Guardado de compras")
	var guardado: Dictionary = e.Guardado.leer()
	check(guardado.jugador.inventario.has("Sabritas Original") and guardado.campana.monedas == 0, "Compras y saldo persisten")
	e.campana.etapa = 3
	await e.campana.cambiar_lugar("campus", Vector2(1510, 1440), false)
	await esperar(5)
	j.position = Vector2(990,650)
	j.get_node("Camera2D").reset_smoothing()
	await esperar(8); await foto("mobiliario")
	for par in [["prefecta", "eco_prefecta.png"], ["talleres", "eco_taller.png"]]:
		var punto: Node2D = e.campana.exterior.get_node(par[0])
		for hijo in punto.get_children():
			if hijo is Sprite2D:
				check(hijo.texture.resource_path.ends_with(par[1]), "Retrato correcto: " + par[0])
		j.position = punto.position + Vector2(0, 55)
		j.get_node("Camera2D").reset_smoothing()
		await esperar(5); await foto(par[0])
	# Pared aislada: roces oblicuos, choque frontal y retirada.
	var pared := StaticBody2D.new()
	pared.position = Vector2(5100, 5000)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new(); rect.size = Vector2(20, 500)
	col.shape = rect; pared.add_child(col); e.add_child(pared)
	j.position = Vector2(5080, 4900); j.bloqueo_entrada = 0
	j.set_physics_process(true)
	await esperar()
	Input.action_press("derecha"); Input.action_press("abajo")
	await esperar(35)
	check(j.position.y > 4930 and j.position.x < 5082, "Desliza contra pared sin atravesarla")
	Input.action_release("abajo")
	await esperar(10)
	var cuadro: int = j.sprite.frame
	await esperar(10)
	check(j.get_real_velocity().length() < 1 and j.sprite.frame == cuadro, "Contra pared no camina en el sitio")
	Input.action_release("derecha"); Input.action_press("izquierda")
	var antes: float = j.position.x
	await esperar(15)
	check(j.position.x < antes - 15, "Se despega inmediatamente de la pared")
	Input.action_release("izquierda")
	j.position = Vector2(5000, 5300)
	Input.action_press("derecha")
	var vistos := {}
	for i in range(60):
		await esperar(1); vistos[j.sprite.frame] = true
	check(vistos.size() >= 4, "Caminata recorre todos los cuadros")
	Input.action_release("derecha")
	j.set_physics_process(false)
	j.position = Vector2(1510, 1460)
	j.get_node("Camera2D").reset_smoothing()
	for direccion in [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]:
		for cuadro_indice in range(4):
			j.distancia_animada = cuadro_indice * 18.0
			j.animar_movimiento(direccion * 112, false)
			await foto("marcha_%s_%d" % [j.direccion_animacion, cuadro_indice])
	print("RESULTADO: %d fallos" % fallos)
	e.queue_free(); await esperar(); quit(fallos)
