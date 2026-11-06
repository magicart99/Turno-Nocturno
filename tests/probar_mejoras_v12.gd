extends SceneTree
const Mochila = preload("res://src/player/mochila.gd")
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
func foto(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v12/"+nombre+".png")
func paredes(raiz: Node) -> int:
	var total := 0
	for n in raiz.get_children():
		if n.has_node("AcabadoV12"):
			var col: CollisionShape2D = n.get_node("Colision")
			var acabado: Node2D = n.get_node("AcabadoV12")
			check(acabado.rect.size.is_equal_approx(col.shape.size),"Pared alineada "+str(n.name))
			total += 1
		else: total += paredes(n)
	return total
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://docs/mejoras_v12/guardado_prueba.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.set_process(false); e.campana.set_process(false)
	e.archivero.set_physics_process(false); e.archivero.activo = false
	e.mente.set_process(false)
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	j.cordura = 100
	for i in range(100): e.mente.avanzar(0.1,false)
	check(is_equal_approx(j.cordura,99),"1% exacto por diez segundos con luz")
	e.mente.avanzar(10,true)
	check(is_equal_approx(j.cordura,98),"Misma tasa en oscuridad")
	e.jugando = false; e.mente.avanzar(20,true)
	check(is_equal_approx(j.cordura,98),"Pausa detiene la pérdida")
	e.jugando = true
	j.inventario.clear(); e.campana.monedas = 10; e.abrir_tienda()
	var ui: CanvasLayer = e.inventario_ui
	for i in range(6): ui.seleccionar("Papas limón"); ui.utilizar()
	check(Mochila.usados(j.inventario)==6 and e.campana.monedas==4,"Seis unidades ocupan seis espacios")
	ui.seleccionar("Coca-Cola"); ui.utilizar()
	check(j.inventario.size()==6 and e.campana.monedas==4,"Compra bloqueada no cobra")
	check(Mochila.cabe(j.inventario,"Llave maestra"),"Evidencia no bloquea la campaña")
	check(not Mochila.cabe(j.inventario,"Grapadora"),"Herramienta comparte límite")
	e.continuar(); await esperar()
	j.cordura=50
	check(preload("res://src/world/productos_cafeteria.gd").consumir(e,"Papas limón"),"Consumir libera espacio")
	check(Mochila.usados(j.inventario)==5,"Cinco espacios tras consumo")
	j.position=Vector2(2100,1100); e.resonancia.zona="principal"; e.resonancia.explorar()
	check(not e.campana.explorados.is_empty(),"Plano registra exploración")
	check(e.guardar_partida(),"Guarda límite y exploración")
	var guardado: Dictionary=e.Guardado.leer()
	check(guardado.campana.explorados.size()>0,"Exploración persistida")
	check(paredes(e.get_node("Paredes"))>20,"Paredes de todas las aulas renovadas")
	j.position=Vector2(2000,650); e.archivero.position=Vector2(2200,650)
	j.apuntado=Vector2.RIGHT; j.linterna=true; e.archivero.activo=true
	e.archivero.estado="PATRULLANDO"; e.archivero.ver_linterna()
	check(e.archivero.estado=="INVESTIGANDO","Haz visible provoca investigación")
	e.archivero.estado="PATRULLANDO"; j.linterna=false; e.archivero.ver_linterna()
	check(e.archivero.estado=="PATRULLANDO","Apagar haz evita detección visual")
	j.linterna=true; e.archivero.position=Vector2(2000,300); j.apuntado=Vector2.UP
	e.archivero.ver_linterna()
	check(e.archivero.estado=="PATRULLANDO","Enemigo no ve a través de pared")
	e.resonancia.set_process(false); e.resonancia.ecos.clear(); e.resonancia.enfriamiento=0
	e.resonancia.registrar(Vector2(2100,650),1)
	check(e.resonancia.ecos.size()==1,"Carrera deja eco diferido")
	e.resonancia._process(13)
	check(e.resonancia.ecos.is_empty() and e.archivero.destino==Vector2(2100,650),"Eco investiga posición pasada")
	e.archivero.activo=false; j.linterna=true
	e.campana.etapa=3
	await e.campana.cambiar_lugar("campus",Vector2(990,700),false)
	await esperar(10)
	check(paredes(e.campana.exterior)>20,"Paredes de edificios del campus renovadas")
	j.position=Vector2(990,595)
	await esperar(12)
	check(e.interfaz.menu_actual=="tienda" and not e.jugando,"Tocar productos abre su inventario")
	await foto("inventario_productos")
	e.continuar(); await esperar(10)
	check(e.jugando,"Cerrar junto al estante no reabre en bucle")
	j.position=Vector2(990,700); await esperar(8)
	j.position=Vector2(990,595); await esperar(8)
	check(not e.jugando,"Alejarse rearma contacto")
	e.continuar(); j.position=Vector2(990,700)
	e.campana.gracia_patio=25
	e.resonancia.zona="campus"; e.resonancia.explorar()
	e._process(0.016)
	j.animar_movimiento(Vector2.ZERO,false)
	j.cordura=35; e.mente._process(0.016)
	j.get_node("Camera2D").reset_smoothing()
	await esperar(8); await foto("cafeteria_distorsion")
	j.cordura=100; e.mente._process(0.016)
	await esperar(8); await foto("cafeteria_paredes")
	e.campana.iniciar_revision("revision_cafe")
	e.campana.avanzar_revision(3)
	check(not e.campana.hechos.get("revision_cafe",false),"Inspección no se completa instantáneamente")
	j.position.x += 50
	e.campana.avanzar_revision(1)
	check(e.campana.revision=="" and not e.campana.hechos.get("revision_cafe",false),"Alejarse cancela inspección")
	e.campana.iniciar_revision("revision_cafe")
	e.campana.avanzar_revision(6)
	check(e.campana.hechos.get("revision_cafe",false),"Completa inspección tras seis segundos")
	e.interfaz.mostrar_mapa()
	await esperar(8); await foto("plano_explorado")
	e.continuar()
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
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free(); await esperar(); quit(fallos)
