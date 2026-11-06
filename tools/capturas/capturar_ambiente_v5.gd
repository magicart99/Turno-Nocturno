extends SceneTree
func _initialize() -> void:call_deferred("ejecutar")
func ejecutar() -> void:
	seed(511)
	var escena: Node2D=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena);current_scene=escena
	for i in range(4):await physics_frame
	escena.Guardado.ruta="res://partidas/prueba_ambiente_v5.json"
	escena.campana.etapa=2;escena.campana.gracia_patio=0
	await escena.campana.cambiar_lugar("campus",Vector2(1840,2450),false)
	escena.alimentar_zona("Exterior_Andador")
	escena.campana.hechos["revision_luz"]=true
	escena.archivero.position=preload("res://src/world/geometria_campus.gd").ARCHIVERO
	escena.jugador.agachado=true;escena.jugador.sigilo=30;escena.jugador.direccion_animacion="right"
	escena.jugador.get_node("Camera2D").zoom=Vector2.ONE
	escena.jugador.get_node("Camera2D").reset_smoothing()
	var e := InputEventJoypadMotion.new();e.device=3;e.axis=JOY_AXIS_RIGHT_X;e.axis_value=1
	Input.parse_input_event(e);Input.flush_buffered_events()
	escena.tiempo=90;escena.partida_iniciada=true;escena.jugando=true;escena.interfaz.jugar()
	for i in range(4):await physics_frame
	for n in escena.get_children():
		if n.get_script()==load("res://src/world/director_terror.gd"):n.manifestacion()
	await create_timer(.35).timeout
	escena.interfaz.aviso.hide();escena.interfaz.subtitulo.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/campus_v5_terror.png")
	quit()
