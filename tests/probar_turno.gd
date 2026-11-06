extends SceneTree
## Prueba integrada, sin tocar la ranura del jugador. Puede producir capturas con -- --capturas.
const Guardado = preload("res://src/core/guardado.gd")
var fallos: int = 0
var registro: Array[String] = []
var escena: Node2D

func _initialize() -> void:
	call_deferred("ejecutar")

func comprobar(valor: bool, texto: String) -> void:
	var linea := ("OK: " if valor else "FALLO: ") + texto
	print(linea)
	registro.append(linea)
	if not valor:
		fallos += 1

func esperar(cantidad: int = 3) -> void:
	for i in range(cantidad):
		await physics_frame

func capturar(nombre: String) -> void:
	if "--capturas" not in OS.get_cmdline_user_args():
		return
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/" + nombre + ".png")

func objeto(titulo: String) -> Node2D:
	for candidato in escena.get_node("Objetos").get_children():
		if candidato.titulo == titulo:
			return candidato
	return null

func interaccion_alcanzable(objetivo: Node2D) -> bool:
	var jugador: CharacterBody2D = escena.jugador
	var original: Vector2 = jugador.position
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 12.0
	consulta.shape = forma
	consulta.collision_mask = 1
	consulta.exclude = [jugador.get_rid()]
	for radio in [32, 48, 64, 78]:
		for paso in range(16):
			var posicion: Vector2 = objetivo.position + Vector2.from_angle(paso * TAU / 16) * radio
			consulta.transform = Transform2D(0, posicion)
			if not jugador.get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty():
				continue
			jugador.position = posicion
			if jugador.mas_cercano() == objetivo:
				var enemigo: CharacterBody2D = escena.archivero
				var camino: PackedVector2Array = enemigo.rejilla.get_point_path(enemigo.celda_libre(original), enemigo.celda_libre(posicion))
				if camino.size() > 0:
					jugador.position = original
					return true
	jugador.position = original
	return false

func ejecutar() -> void:
	escena = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	await esperar(5)
	Guardado.ruta = "res://partidas/prueba_temporal.json"
	var jugador: CharacterBody2D = escena.jugador
	var enemigo: CharacterBody2D = escena.archivero
	for titulo in ["Llave maestra", "Expediente de Lalo", "Salida", "Luz: Rectoria_Archivo", "Grapadora"]:
		comprobar(interaccion_alcanzable(objeto(titulo)), "Objetivo seleccionable desde un punto accesible: " + titulo)
	comprobar(not escena.jugando and escena.interfaz.menu_actual == "inicio", "Menú inicial detiene la partida")
	await capturar("turno_menu")
	escena.interfaz.mostrar("opciones")
	await capturar("turno_controles")
	jugador.set_physics_process(false) # Prueba unitaria del atlas, independiente de la pausa.
	for sprite in [jugador.sprite, enemigo.sprite]:
		for direccion in ["down", "left", "right", "up"]:
			comprobar(sprite.sprite_frames.get_frame_count(direccion) == 4, "Cuatro cuadros originales: " + str(sprite.get_parent().name) + " / " + direccion)
		var vectores := {"down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP}
		for direccion in vectores:
			preload("res://src/player/animacion_personaje.gd").mover(sprite, vectores[direccion] * 100)
			await create_timer(0.2).timeout
			comprobar(sprite.animation == direccion and sprite.is_playing(), "Animación activa en dirección: " + str(sprite.get_parent().name) + " / " + direccion)
		preload("res://src/player/animacion_personaje.gd").mover(sprite, Vector2.ZERO)
		preload("res://src/player/animacion_personaje.gd").mover(sprite, Vector2.DOWN * 10)
		preload("res://src/player/animacion_personaje.gd").mover(sprite, Vector2.ZERO)
	jugador.set_physics_process(true)
	for accion in ["izquierda", "derecha", "arriba", "abajo", "interactuar", "linterna", "correr", "pausa", "distraer"]:
		var tiene_mando := false
		for evento in InputMap.action_get_events(accion):
			tiene_mando = tiene_mando or evento is InputEventJoypadButton or evento is InputEventJoypadMotion
		comprobar(tiene_mando, "Acción extensible con mando: " + accion)
	escena.interfaz.mostrar("inicio")
	escena.iniciar()
	await create_timer(3.2).timeout
	comprobar(escena.jugando and not Guardado.leer().is_empty(), "Introducción termina y crea guardado inicial")
	await capturar("turno_juego")
	escena.pausar()
	var tiempo: float = escena.tiempo
	await esperar(5)
	comprobar(escena.tiempo == tiempo, "Pausa congela el tiempo de juego")
	escena.continuar()
	var puerta := objeto("Puerta: Entrada")
	comprobar(puerta != null, "Puerta de Entrada existe")
	if puerta != null:
		puerta.interactuar(jugador)
		await esperar()
		comprobar(puerta.abierto and puerta.get_node("Colision").disabled, "Puerta abre y libera colisión")
		puerta.interactuar(jugador)
		await esperar()
		comprobar(not puerta.abierto and not puerta.get_node("Colision").disabled, "Puerta cierra y restaura colisión")
	var expediente := objeto("Expediente de Lalo")
	expediente.interactuar(jugador)
	comprobar(not jugador.inventario.has("Expediente de Lalo"), "Expediente requiere llave")
	objeto("Llave maestra").interactuar(jugador)
	await esperar()
	expediente.interactuar(jugador)
	comprobar(not jugador.inventario.has("Expediente de Lalo"), "Expediente requiere luz de Rectoría")
	escena.alternar_zona("Rectoria_Archivo")
	expediente.interactuar(jugador)
	await esperar()
	comprobar(jugador.inventario.has("Expediente de Lalo"), "Objetivo se recoge con llave y luz")
	var ruta: PackedVector2Array = enemigo.rejilla.get_point_path(enemigo.celda_libre(Vector2(3264,670)), enemigo.celda_libre(Vector2(2112,1120)))
	comprobar(ruta.size() > 5, "Ruta desde el pasillo hasta la Entrada")
	for destino in [Vector2(2880, 1120), Vector2(3264, 1120), Vector2(192, 224), Vector2(3648, 1120)]:
		ruta = enemigo.rejilla.get_point_path(enemigo.celda_libre(Vector2(2112,670)), enemigo.celda_libre(destino))
		comprobar(ruta.size() > 5, "Navegación entre habitaciones: " + str(destino))
	escena.tiempo = 15
	enemigo.escuchar(Vector2(2496,670), 1.0)
	comprobar(enemigo.activo and enemigo.estado == "INVESTIGANDO", "Ruido fuerte despierta al Archivero e inicia investigación")
	var antes: Vector2 = enemigo.position
	await esperar(60)
	comprobar(enemigo.position.distance_to(antes) > 60, "Archivero avanza realmente siguiendo una ruta")
	# Comprueba una puerta en el trayecto, no solamente la existencia de un camino.
	jugador.position = Vector2(1800,670)
	enemigo.position = Vector2(2112, 845)
	enemigo.destino = Vector2(2112, 1080)
	enemigo.memoria = 7
	enemigo.recalcular = 0
	for i in range(180):
		await physics_frame
		if enemigo.position.y > 1020:
			break
	comprobar(enemigo.position.y > 1020 and puerta.abierto, "Archivero abre y cruza una puerta sin atravesar paredes")
	enemigo.estado = "PATRULLANDO"
	enemigo.memoria = 0
	enemigo.escuchar(Vector2(100,100), 0.18)
	comprobar(enemigo.estado == "PATRULLANDO", "Ignora sonidos fuera de su alcance")
	enemigo.estado = "INVESTIGANDO"
	enemigo.memoria = 0.02
	await esperar(4)
	comprobar(enemigo.estado == "BUSCANDO", "Pierde el rastro cuando deja de recibir sonido")
	var escondite := objeto("Archivo: ocultarse")
	escondite.interactuar(jugador)
	await create_timer(1.3).timeout
	comprobar(jugador.oculto and jugador.ultimo_escondite == escondite, "Escondite mantiene referencia para salir/cargar")
	escondite.interactuar(jugador)
	await create_timer(1.3).timeout
	comprobar(not jugador.oculto, "Salir del escondite")
	jugador.inventario.append("Grapadora")
	jugador.distraer()
	comprobar(not jugador.inventario.has("Grapadora"), "Distracción consume el objeto una sola vez")
	# Estado persistente diferente al inicial.
	escena.jugando = false
	puerta.establecer_puerta(true)
	jugador.position = Vector2(2112, 1110)
	jugador.cordura = 67
	jugador.linterna = false
	var mueble: Node2D
	for candidato in get_nodes_in_group("interactivos"):
		if candidato.tipo == "empujar":
			mueble = candidato
			break
	mueble.position += Vector2(5, 0)
	var posicion_mueble: Vector2 = mueble.position
	var nombre_mueble: String = mueble.name
	comprobar(escena.guardar_partida(), "Escritura comprobada de partida")
	comprobar(escena.guardar_partida(), "Reemplazo de ranura y creación de respaldo")
	var cantidad: int = jugador.inventario.size()
	var corrupto := FileAccess.open(Guardado.ruta, FileAccess.WRITE)
	corrupto.store_string("{incompleto")
	corrupto.close()
	comprobar(not Guardado.leer().is_empty(), "Recuperación desde respaldo si JSON está corrupto")
	var guardado := Guardado.leer()
	var invalido: Dictionary = guardado.duplicate(true)
	invalido.jugador.posicion = ["incorrecto", 0]
	comprobar(not Guardado.guardar(invalido), "Datos inválidos no reemplazan el respaldo")
	escena.free()
	escena = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	await esperar(5)
	Guardado.ruta = "res://partidas/prueba_temporal.json"
	await escena.aplicar_guardado()
	escena.jugando = false
	jugador = escena.jugador
	enemigo = escena.archivero
	comprobar(jugador.inventario.size() == cantidad and jugador.inventario.has("Expediente de Lalo"), "Carga conserva inventario sin duplicados")
	comprobar(objeto("Expediente de Lalo") == null and objeto("Llave maestra") == null, "Objetos recogidos no reaparecen")
	comprobar(jugador.position.distance_to(Vector2(2112,1110)) < 1 and jugador.cordura == 67 and not jugador.linterna, "Carga conserva posición, cordura y linterna")
	comprobar(objeto("Puerta: Entrada").abierto and escena.get_node("Objetos/" + nombre_mueble).position == posicion_mueble, "Carga conserva puerta y mueble desplazado")
	comprobar(escena.zonas.Rectoria_Archivo and enemigo.activo, "Carga conserva iluminación y amenaza")
	escena.partida_iniciada = true
	escena.jugando = true
	enemigo.position = jugador.position + Vector2(50,0)
	escena.solicitar_salida("menu")
	comprobar(escena.interfaz.menu_actual == "confirmar_salida", "Salida insegura avisa antes de perder avance")
	escena.continuar()
	escena.jugando = false
	# Captura cinematográfica y reintento.
	jugador.position = Vector2(2112, 670)
	enemigo.position = Vector2(2300, 670)
	jugador.linterna = true
	jugador.apuntado = Vector2.RIGHT
	jugador.get_node("Linterna").rotation = 0
	jugador.get_node("Camera2D").reset_smoothing()
	enemigo.sprite.play("left")
	escena.anunciar("HA APARECIDO EL ARCHIVERO", "No busca tu rostro. Escucha tus pasos.")
	await capturar("turno_archivero")
	jugador.oculto = true
	enemigo.position = jugador.position
	escena.jugando = true
	await esperar(3)
	comprobar(escena.jugando, "Ocultación impide captura por proximidad")
	jugador.oculto = false
	enemigo.estado = "INVESTIGANDO"
	enemigo.memoria = 4
	await esperar(3)
	comprobar(not escena.jugando and escena.transicion, "Contacto con Archivero activa captura")
	await create_timer(2.6).timeout
	comprobar(escena.interfaz.menu_actual == "muerte", "Captura termina en menú Reintentar")
	await capturar("turno_archivado")
	escena.jugando = true
	objeto("Salida").interactuar(jugador)
	comprobar(escena.interfaz.menu_actual != "victoria" and escena.campana.etapa == 1, "Expediente solo no salta la campaña; falta la bitácora")
	await capturar("turno_final")
	# Solo se borran archivos temporales de esta prueba, nunca partidas reales.
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("res://partidas/prueba_temporal.json" + sufijo):
			DirAccess.remove_absolute("res://partidas/prueba_temporal.json" + sufijo)
	registro.append("RESULTADO: %d fallos" % fallos)
	var archivo := FileAccess.open("res://docs/pruebas_turno.txt", FileAccess.WRITE)
	archivo.store_string("\n".join(registro))
	archivo.close()
	print(registro[-1])
	quit(fallos)
