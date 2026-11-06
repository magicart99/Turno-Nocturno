extends SceneTree
var e: Node2D
var fallos := 0
func _initialize() -> void:call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ")+texto)
	if not ok:fallos+=1
func esperar(n: int=4) -> void:
	for i in range(n):await physics_frame;await process_frame
func foto(nombre: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v8/"+nombre+".png")
func ejecutar() -> void:
	e=load("res://scenes/escuela.tscn").instantiate();root.add_child(e);current_scene=e
	await esperar(10)
	e.Guardado.ruta="res://docs/mejoras_v8/guardado_prueba.json"
	e.partida_iniciada=true;e.jugando=true;e.interfaz.jugar()
	e.archivero.set_physics_process(false)
	var j: CharacterBody2D=e.jugador
	j.position=Vector2(650,670)
	Input.action_press("derecha")
	await esperar(15)
	check(j.distancia_animada>0 and j.sprite.self_modulate.a==1,"Marcha completa sigue movimiento real")
	await foto("marcha")
	Input.action_release("derecha");await esperar()
	check(j.sprite.self_modulate.a==1,"Reposo restaura sprite original")
	check(e.archivero.velocidad_busqueda==98 and e.archivero.velocidad_patrulla==48,"Archivero más lento que Lalo andando")
	var escondite: Node2D
	for n in get_nodes_in_group("interactivos"):
		if "Casillero" in str(n.get("titulo")):escondite=n;break
	j.set_physics_process(false)
	e.archivero.activo=true;e.archivero.position=j.position+Vector2(40,0)
	j.esconder(escondite)
	check(j.protegido_en_refugio(),"Entrada aceptada protege antes de terminar animación")
	j.cancelar_accion()
	e.archivero.position=j.position+Vector2(20,0)
	j.esconder(escondite)
	check(not j.protegido_en_refugio(),"No hay inmunidad al esconderse dentro del radio de captura")
	j.cancelar_accion();e.archivero.activo=false
	var fantasma: Sprite2D=e.get_node("DetallesPrincipal/computo/Sprite3")
	var antes: float=fantasma.position.y
	await esperar(15)
	check(fantasma.position.y!=antes and fantasma.position.y<0,"la de Cómputo flota sin desplazar su interacción")
	j.position=Vector2(610,1160);await esperar(20);await foto("estefania")
	for i in range(1,6):check(e.sonidos.recursos["eco_%d"%i].get_length()>0,"Voz CC0 importada %d"%i)
	e.campana.abrir_tablero("Computo");await esperar()
	var t: CanvasLayer=e.campana.tablero
	for i in range(4):t.seleccionar(i);t.conectar(t.orden.find(i))
	check(t.calibrando and not t.terminado and e.campana.alimentado=="Entrada","Conectar cables requiere estabilizar antes de cambiar circuito")
	t.fase=PI/2;t.estabilizar()
	check(t.conectados.size()==4 and not t.terminado,"Error de estabilización conserva cables y circuito")
	t.pausado=true
	var fase: float=t.fase;await esperar()
	check(t.fase==fase,"Pausa detiene calibración")
	await foto("electricidad")
	t.pausado=false;t.fase=0;t.activar.pressed.emit();await esperar()
	check(e.campana.alimentado=="Computo" and e.jugando,"Estabilizar activa circuito y devuelve control")
	var altavoz: Node2D=e.get_node("DetallesPrincipal/AltavozEscolar")
	j.position=Vector2(900,670)
	await esperar()
	check(j.mas_cercano()==altavoz,"Altavoz accesible desde el pasillo principal")
	altavoz.pendiente=.01
	e.tiempo=30
	e.archivero.activo=true;e.archivero.position=altavoz.position+Vector2(150,0)
	await esperar()
	check(altavoz.descanso>0 and e.archivero.destino.distance_to(altavoz.position)<1,"Aviso diferido atrae al Archivero hacia el altavoz")
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free();await esperar();quit(fallos)
