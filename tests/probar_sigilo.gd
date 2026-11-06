extends SceneTree
const Geo=preload("res://src/world/geometria_campus.gd")
var escena: Node2D
var fallos: int = 0
var registro: Array[String] = []

func _initialize() -> void: call_deferred("ejecutar")
func comprobar(ok: bool, texto: String) -> void:
	registro.append(("OK " if ok else "FALLO ")+texto)
	print(registro[-1])
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await process_frame
		await physics_frame
func evento(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await esperar()
func boton(b: int, presionado: bool, id: int = 3) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index=b; e.pressed=presionado; e.device=id
	await evento(e)
func eje(a: int, valor: float, id: int = 3) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis=a; e.axis_value=valor; e.device=id
	await evento(e)
func tecla(t: int, presionado: bool) -> void:
	var e := InputEventKey.new()
	e.keycode=t; e.physical_keycode=t; e.pressed=presionado
	await evento(e)
func pulsar_cable(i: int) -> void:
	var tablero: CanvasLayer=escena.campana.tablero
	var fuente: Button=tablero.fuentes[i]
	fuente.pressed.emit()
	for destino in tablero.destinos:
		if destino.text==fuente.text:destino.pressed.emit();break
	if tablero.calibrando:
		tablero.fase=0.0
		tablero.estabilizar()
	await esperar()
func capturar(nombre: String) -> void:
	if not "--capturas" in OS.get_cmdline_user_args(): return
	escena.interfaz.aviso.hide(); escena.interfaz.subtitulo.hide()
	if escena.interfaz.menu_actual == "dialogo": await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/"+nombre+".png")
func ejecutar() -> void:
	escena=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena); current_scene=escena
	await esperar()
	escena.Guardado.ruta="res://partidas/prueba_sigilo.json"
	var j: CharacterBody2D=escena.jugador
	var c: Node=escena.campana
	var a: CharacterBody2D=escena.archivero
	escena.partida_iniciada=true; escena.jugando=true; escena.interfaz.jugar()
	comprobar(root.audio_listener_enable_2d,"Escucha 2D activada: puertas y enemigo audibles")
	comprobar(escena.sonidos.ambiente.volume_db == -26,"Música aumentada 7 dB")
	for nombre in ["crouch_down","crouch_right","crouch_up","crawl","dig","torch_down","torch_right","torch_up","torch_left","crawl_down","crawl_up","dig_down","dig_up"]:
		comprobar(j.sprite.sprite_frames.has_animation(nombre),"Atlas importado: "+nombre)
	for id in [0,3]:
		j.position=Vector2(2112,1120)
		var antes: Vector2=j.position
		await eje(JOY_AXIS_LEFT_X,0.28,id)
		await eje(JOY_AXIS_LEFT_Y,0.18,id)
		comprobar(j.position.distance_to(antes)<0.1,"Zona muerta radial impide deriva · mando %d"%id)
		await eje(JOY_AXIS_LEFT_X,0,id); await eje(JOY_AXIS_LEFT_Y,0,id)
		await boton(JOY_BUTTON_B,true,id); await boton(JOY_BUTTON_B,false,id)
		comprobar(j.agachado,"B / Círculo agacha · mando %d"%id)
		await eje(JOY_AXIS_LEFT_X,1,id)
		comprobar(j.velocity.length() > 0 and j.velocity.length() <= 54.1 and j.ruido == 0,"Agachado avanza lento sin ruido · mando %d"%id)
		var cuadro_anterior: int=j.sprite.frame
		await esperar(15)
		comprobar(j.sprite.animation == "crouch_right" and j.sprite.frame != cuadro_anterior,"Animación agachado avanza · mando %d"%id)
		await eje(JOY_AXIS_LEFT_X,0,id)
		antes=j.position
		await esperar(12)
		comprobar(j.position.distance_to(antes)<.1 and not j.sprite.is_playing(),"Soltar stick detiene cuerpo y animación · mando %d"%id)
		await boton(JOY_BUTTON_B,true,id); await boton(JOY_BUTTON_B,false,id)
		comprobar(not j.agachado,"B / Círculo vuelve de pie · mando %d"%id)
	var mini: Control
	for n in escena.interfaz.panel.get_parent().get_children():
		if n.get_script() == load("res://src/ui/minimapa.gd"): mini=n
	await eje(JOY_AXIS_TRIGGER_LEFT,1)
	comprobar(escena.interfaz.menu_actual == "mapa" and not escena.jugando,"LT / L2 abre plano grande y pausa")
	await eje(JOY_AXIS_TRIGGER_LEFT,0)
	await tecla(KEY_V,true); await tecla(KEY_V,false)
	comprobar(escena.jugando and not is_instance_valid(escena.interfaz.plano_grande),"V cierra plano")
	await create_timer(.22).timeout # Bloqueo breve al volver de un menú.
	await tecla(KEY_C,true); await tecla(KEY_C,false)
	comprobar(j.agachado,"C agacha con teclado")
	await tecla(KEY_C,true); await tecla(KEY_C,false)
	j.linterna=true
	for direccion in ["right","down","left","up"]:
		var v: Vector2 = {"right":Vector2.RIGHT,"down":Vector2.DOWN,"left":Vector2.LEFT,"up":Vector2.UP}[direccion]
		await eje(JOY_AXIS_RIGHT_X,v.x); await eje(JOY_AXIS_RIGHT_Y,v.y)
		comprobar(j.sprite.animation == "torch_" + direccion,"Linterna sostenida orientada al apuntar: " + direccion)
		comprobar(j.get_node("Linterna").enabled and j.get_node("Linterna").position.y < -20,"Haz en la mano, no en los pies: " + direccion)
	await eje(JOY_AXIS_RIGHT_X,0); await eje(JOY_AXIS_RIGHT_Y,0)
	j.linterna=false
	await esperar()
	comprobar(not j.sprite.animation.begins_with("torch_") and not j.get_node("Linterna").enabled,"Apagar guarda la linterna y recupera la postura normal")
	j.linterna=true
	# Elegir un escritorio real. La animación no teletransporta el cuerpo al mueble.
	var escritorio: Node2D
	var casillero: Node2D
	var cantidad: int=0
	for obj in escena.get_node("Objetos").get_children():
		if obj.titulo == "Escritorio: ocultarse": escritorio=obj;cantidad+=1
		if obj.titulo == "Casillero: ocultarse":casillero=obj
	comprobar(cantidad >= 9,"Cada aula conserva al menos un escritorio para ocultarse")
	for objeto in [escritorio,casillero]:
		j.position=objeto.position+Vector2(0,65)
		j.get_node("Camera2D").reset_smoothing()
		var antes: Vector2=j.position
		j.mensaje = objeto.interactuar(j)
		await esperar(10)
		comprobar(j.accion == "entrar" and not j.oculto,"Entrada visible antes de estar protegido: "+objeto.titulo)
		await capturar("sigilo_entrada_"+("casillero" if objeto==casillero else "escritorio"))
		await create_timer(1.2).timeout
		comprobar(j.oculto and j.accion == "" and j.position==antes,"Ocultación terminada sin meter colisión en mueble")
		j.mensaje = objeto.interactuar(j)
		await create_timer(1.2).timeout
		comprobar(not j.oculto and j.accion == "" and j.position==antes,"Salida animada recupera control")
	c.reparar("Aula_02")
	await esperar()
	comprobar(not escena.zonas["Aula_02"],"Abrir tablero no repara automáticamente")
	await capturar("sigilo_reparacion")
	await boton(JOY_BUTTON_B,true); await boton(JOY_BUTTON_B,false)
	comprobar(escena.jugando and not escena.zonas["Aula_02"],"Cancelar con mando no repara")
	c.reparar("Aula_02")
	for i in range(4): await pulsar_cable(i)
	comprobar(escena.zonas["Aula_02"] and not escena.zonas["Aula_03"] and c.hechos.get("electricidad_Aula_02",false),"Resolver cables repara solo el aula seleccionada")
	c.etapa=2
	await c.cambiar_lugar("campus",Geo.ENTRADA,false)
	escena.jugando=true
	await esperar()
	comprobar(c.gracia_activa() and not a.activo,"Primera entrada al patio inicia margen de 60 s")
	a.escuchar(j.position,5); a.despertar()
	comprobar(not a.activo,"Ni ruido ni reloj principal adelantan al Archivero")
	var gracia: float=c.gracia_patio
	escena.pausar();await create_timer(.2).timeout
	comprobar(c.gracia_patio==gracia,"Pausa congela la cuenta regresiva")
	escena.continuar()
	c.reparar("Exterior_Andador")
	for i in range(4): await pulsar_cable(i)
	comprobar(c.hechos.get("revision_luz",false) and escena.zonas["Exterior_Andador"] and not escena.zonas["Exterior_Servicios"],"Andador reparado no enciende servicios")
	# Radar siempre visible en juego
	j.position=Geo.ENTRADA
	j.get_node("Camera2D").reset_smoothing()
	await esperar()
	await capturar("sigilo_patio_minimapa")
	c.hechos["pala"]=true
	j.position=c.exterior.get_node("archivo_enterrado").position+Vector2(0,50)
	j.get_node("Camera2D").reset_smoothing()
	c.interactuar("archivo_enterrado",c.exterior.get_node("archivo_enterrado"))
	await esperar(12)
	comprobar(j.accion=="excavar" and not c.hechos.get("archivo_enterrado",false),"Excavar tarda: no entrega el archivo al pulsar")
	comprobar(not escena.puede_guardar(),"No guarda una acción de excavación incompleta")
	await capturar("sigilo_excavando")
	escena.pausar()
	var avance: float=j.avance_accion
	await create_timer(.2).timeout
	comprobar(j.avance_accion==avance,"Excavación se pausa sin entregar el objeto")
	escena.continuar()
	await create_timer(3.1).timeout
	comprobar(c.hechos.get("archivo_enterrado",false) and j.accion=="","Excavación completa entrega el archivo una sola vez")
	var d: Dictionary=c.datos()
	await c.restaurar(d)
	comprobar(absf(c.gracia_patio-float(d.gracia_patio))<.5,"Cargar conserva segundos restantes, no regala otro minuto")
	c.gracia_patio=.08
	escena.jugando=true
	await create_timer(.2).timeout
	comprobar(a.activo and c.gracia_patio==0,"Fin de cuenta regresiva despierta al Archivero")
	a.position=j.position+Vector2(150,0);a.memoria=0;a.estado="PATRULLANDO"
	j.agachado=true
	await eje(JOY_AXIS_LEFT_X,1)
	comprobar(a.estado!="INVESTIGANDO" and j.ruido==0,"Archivero cercano no investiga pasos agachados")
	await eje(JOY_AXIS_LEFT_X,0)
	comprobar(escena.guardar_partida(),"Estado v3 puede guardarse sin modificar ranura personal")
	comprobar(not escena.Guardado.leer().is_empty(),"Guardado v3 pasa validación")
	registro.append("RESULTADO: %d fallos"%fallos)
	print(registro[-1])
	FileAccess.open("res://docs/pruebas_sigilo.txt",FileAccess.WRITE).store_string("\n".join(registro))
	for sufijo in ["",".bak",".tmp"]: DirAccess.remove_absolute(escena.Guardado.ruta+sufijo)
	quit(fallos)

