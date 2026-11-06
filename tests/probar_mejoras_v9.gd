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
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mejoras_v9/"+nombre+".png")
func boton(id: int) -> void:
	for presionado in [true,false]:
		var ev:=InputEventJoypadButton.new();ev.device=3;ev.button_index=id;ev.pressed=presionado
		Input.parse_input_event(ev);Input.flush_buffered_events();await esperar()
func ejecutar() -> void:
	e=load("res://scenes/escuela.tscn").instantiate();root.add_child(e);current_scene=e
	await esperar(12)
	e.Guardado.ruta="res://docs/mejoras_v9/guardado_prueba.json"
	e.partida_iniciada=true;e.jugando=true;e.interfaz.jugar();e.tiempo=10
	var j: CharacterBody2D=e.jugador
	var a: CharacterBody2D=e.archivero
	a.set_physics_process(false);a.activo=false
	var mente: Node=e.mente;mente.set_process(false)
	j.inventario.assign(["Llave maestra","Extintor","Grapadora","Termo de cafe","Expediente de Lalo","Sello roto","Gafete de prefectura","Memoria USB","Acta sellada","Memoria: maqueta"])
	e.campana.hechos["radio"]=true;e.campana.hechos["pala"]=true
	await boton(JOY_BUTTON_Y)
	check(e.interfaz.menu_actual=="inventario" and not e.jugando,"Y abre mochila y pausa mundo")
	check(j.inventario.has("Grapadora"),"Y no consume la distracción")
	var inv: CanvasLayer=e.inventario_ui
	check(inv.objetos.size()==13,"Mochila combina objetos y herramientas adquiridas")
	for item in inv.objetos:check(load("res://assets/sprites/"+inv.datos(item)[0]) is Texture2D,"Icono disponible: "+item)
	check(inv.rejilla.get_child(1).get_child(0).size==Vector2(88,80),"Iconos contenidos en cada casilla")
	inv.rejilla.get_child(1).grab_focus();await foto("inventario")
	inv.cambiar(1);check(inv.rejilla.get_child_count()==1,"Paginación muestra objetos más allá de doce")
	inv.cambiar(-1)
	j.cordura=80;inv.seleccionar("Termo de cafe");inv.utilizar()
	check(j.cordura==95 and not j.inventario.has("Termo de cafe"),"Beber consume un termo y recupera quince")
	await boton(JOY_BUTTON_Y)
	check(e.jugando and not is_instance_valid(e.inventario_ui),"Y cierra sin reabrirse")
	j.set_physics_process(false);j.cordura=100;mente.vision=0
	mente.avanzar(20,true);check(is_equal_approx(j.cordura,99),"Oscuridad: exactamente 1% cada 20 segundos")
	j.cordura=100;mente.vision=20;mente.avanzar(20,true)
	check(is_equal_approx(j.cordura,99),"Oscuridad y visión extraña no duplican la pérdida")
	e.jugando=false;mente.avanzar(200,true);check(is_equal_approx(j.cordura,99),"Menús no consumen cordura")
	e.jugando=true;mente.vision=0;mente.avanzar(20,false);check(is_equal_approx(j.cordura,99.5),"Luz segura recupera medio punto por 20 s")
	j.cordura=25;mente.espera=0;e.peligro=0;mente.avanzar(.01,true)
	check(mente.inversion>=1.5 and mente.inversion<=2.5,"Cordura crítica produce desorientación breve")
	mente.avanzar(3,true);check(mente.inversion==0,"Inversión termina sin dejar controles bloqueados")
	j.cordura=60;mente.espera=0;mente.avanzar(.01,true);check(mente.inversion==0,"Sin inversión a cordura media")
	j.position=Vector2(1350,670);j.linterna=true;j.set_physics_process(true)
	await esperar(15);Input.action_press("derecha");await esperar(12)
	check(j.sprite.self_modulate.a==1,"Marcha conserva sprite completo sin recortes")
	var distancia: float=j.distancia_animada
	await foto("marcha")
	Input.action_release("derecha");await esperar(8)
	check(j.distancia_animada>=distancia and not j.sprite.is_playing(),"Reposo detiene los cuadros")
	j.set_physics_process(false)
	var eco: Node2D=e.get_node("Testimonio1")
	j.position=eco.position;j.linterna=false;eco.origen=j.position;eco.esperando=true;eco.progreso=4.95
	await esperar(10)
	check(e.campana.hechos.get("testimonio_1",false),"Escuchar quieto en oscuridad recupera testimonio")
	check(e.campana.datos().hechos.get("testimonio_1",false),"Testimonio persiste en guardado")
	# Reproducción: oculto bajo escritorio, enemigo investiga el último ruido.
	var escritorio: Node2D
	for n in get_nodes_in_group("interactivos"):
		if n.get("tipo")=="escondite" and "Escritorio" in str(n.get("titulo")):escritorio=n;break
	j.position=a.rejilla.get_point_position(a.celda_libre(escritorio.position+Vector2(0,50)))
	j.oculto=true;j.ultimo_escondite=escritorio
	a.position=a.rejilla.get_point_position(a.celda_libre(j.position+Vector2(100,0)))
	a.activo=true;a.estado="INVESTIGANDO";a.destino=j.position;a.memoria=1;a.reaccion=0;a.recalcular=0
	a.set_physics_process(true)
	await create_timer(10).timeout
	check(a.estado=="PATRULLANDO","Archivero abandona investigación de escritorio")
	check(a.position.distance_to(j.position)>120,"Archivero se aleja físicamente del escondite")
	a.set_physics_process(false);a.activo=false;j.oculto=false;j.cordura=20
	mente._process(.01);await foto("cordura")

	mente.pantalla.hide();mente.inversion=2;j.position=Vector2(1350,670);j.bloqueo_entrada=0;j.set_physics_process(true)
	Input.action_press("derecha");await esperar(8);Input.action_release("derecha")
	check(j.position.x<1350,"Desorientación invierte movimiento real")
	mente.inversion=0;await esperar();j.set_physics_process(false)
	a.position=j.position+Vector2(140,0);a.activo=true
	await boton(JOY_BUTTON_Y)
	e.inventario_ui.seleccionar("Extintor");e.inventario_ui.utilizar();await esperar()
	check(not j.inventario.has("Extintor") and a.repelido>0,"Extintor consumido frena enemigo próximo")
	a.activo=false;j.cordura=100
	e.campana.etapa=4
	await e.campana.cambiar_lugar("campus",preload("res://src/world/geometria_campus.gd").ENTRADA,false)
	await esperar(8)
	for i in range(2,5):
		var recuerdo: Node2D=e.get_node("Testimonio%d"%i)
		var accesible:=false
		for radio in [24,40,60]:
			for angulo in range(16):
				var p: Vector2=recuerdo.position+Vector2.from_angle(angulo*TAU/16)*radio
				var q:=PhysicsShapeQueryParameters2D.new();var forma:=CircleShape2D.new();forma.radius=12
				q.shape=forma;q.collision_mask=1;q.exclude=[j.get_rid(),a.get_rid()];q.transform=Transform2D(0,p)
				if not e.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty():continue
				j.position=p
				var ruta: PackedVector2Array=a.rejilla.get_point_path(a.celda_libre(preload("res://src/world/geometria_campus.gd").ENTRADA),a.celda_libre(p))
				if j.mas_cercano()==recuerdo and ruta.size()>0:accesible=true;break
			if accesible:break
		check(accesible,"Recuerdo accesible en nivel %d"%i)
		j.get_node("Camera2D").reset_smoothing();await esperar(8)
		await foto("nivel_%d"%i)
	check(e.get_node_or_null("Testimonio5")==null,"Solo cuatro recuerdos, sin duplicarlos al cambiar mapa")
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free();await esperar();quit(fallos)
