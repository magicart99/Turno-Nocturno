extends SceneTree
var escena: Node2D
var fallos: int = 0
var lineas: Array[String] = []
func _initialize() -> void: call_deferred("ejecutar")
func comprobar(ok: bool, texto: String) -> void:
	lineas.append(("OK " if ok else "FALLO ")+texto)
	print(lineas[-1])
	if not ok: fallos += 1
func esperar(n: int = 5) -> void:
	for i in range(n):
		await process_frame
		await physics_frame
func tecla(codigo: int, pulsado: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode=codigo
	e.keycode=codigo
	e.pressed=pulsado
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await esperar()
func boton(codigo: int, pulsado: bool, dispositivo: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index=codigo
	e.device=dispositivo
	e.pressed=pulsado
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await esperar()
func eje(codigo: int, valor: float, dispositivo: int) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis=codigo
	e.axis_value=valor
	e.device=dispositivo
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await esperar()
func ejecutar() -> void:
	escena=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	current_scene=escena
	await esperar()
	escena.Guardado.ruta="res://partidas/prueba_controles.json"
	# A/Cruz debe iniciar desde el menú real, sin llamar escuela.iniciar.
	await boton(JOY_BUTTON_A,true,3)
	await boton(JOY_BUTTON_A,false,3)
	await create_timer(3.3).timeout
	comprobar(escena.jugando,"A/Cruz inicia desde menú sin usar ratón")
	var j: CharacterBody2D=escena.jugador
	var p: Vector2=j.position
	await tecla(KEY_D,true)
	await tecla(KEY_D,false)
	comprobar(j.position.x>p.x+2,"Teclado mueve a Lalo")
	var luz: bool=j.linterna
	await tecla(KEY_F,true); await tecla(KEY_F,false)
	comprobar(j.linterna != luz,"F alterna la linterna")
	await tecla(KEY_ESCAPE,true);await tecla(KEY_ESCAPE,false)
	comprobar(not escena.jugando and escena.interfaz.menu_actual=="pausa","Esc pausa")
	await tecla(KEY_ESCAPE,true);await tecla(KEY_ESCAPE,false)
	comprobar(escena.jugando,"Esc reanuda")
	for dispositivo in [0,3]:
		j.position=Vector2(2112,1120)
		p=j.position
		await eje(JOY_AXIS_LEFT_X,.8,dispositivo)
		await eje(JOY_AXIS_LEFT_X,0,dispositivo)
		comprobar(j.position.x>p.x+2,"Stick izquierdo mueve · ID %d"%dispositivo)
		await eje(JOY_AXIS_RIGHT_Y,-1,dispositivo)
		comprobar(j.apuntado.y < -.8,"Stick derecho apunta arriba · ID %d"%dispositivo)
		await eje(JOY_AXIS_RIGHT_Y,0,dispositivo)
		luz=j.linterna
		await boton(JOY_BUTTON_X,true,dispositivo);await boton(JOY_BUTTON_X,false,dispositivo)
		comprobar(j.linterna!=luz,"X/Cuadrado alterna luz · ID %d"%dispositivo)
		j.inventario.append("Grapadora")
		await boton(JOY_BUTTON_RIGHT_SHOULDER,true,dispositivo);await boton(JOY_BUTTON_RIGHT_SHOULDER,false,dispositivo)
		comprobar(not j.inventario.has("Grapadora"),"RB/R1 lanza objeto · ID %d"%dispositivo)
		await boton(JOY_BUTTON_LEFT_SHOULDER,true,dispositivo)
		await eje(JOY_AXIS_LEFT_X,.8,dispositivo)
		comprobar(j.velocity.length()>150,"LB/L1 activa carrera · ID %d"%dispositivo)
		await eje(JOY_AXIS_LEFT_X,0,dispositivo)
		await boton(JOY_BUTTON_LEFT_SHOULDER,false,dispositivo)
		await boton(JOY_BUTTON_START,true,dispositivo);await boton(JOY_BUTTON_START,false,dispositivo)
		comprobar(escena.interfaz.menu_actual=="pausa","Start/Options abre pausa · ID %d"%dispositivo)
		await boton(JOY_BUTTON_A,true,dispositivo);await boton(JOY_BUTTON_A,false,dispositivo)
		comprobar(escena.jugando,"A/Cruz reanuda desde botón · ID %d"%dispositivo)
		await boton(JOY_BUTTON_BACK,true,dispositivo);await boton(JOY_BUTTON_BACK,false,dispositivo)
		comprobar(escena.interfaz.menu_actual=="mapa","Back/Share abre mapa · ID %d"%dispositivo)
		await boton(JOY_BUTTON_B,true,dispositivo);await boton(JOY_BUTTON_B,false,dispositivo)
		comprobar(escena.jugando,"B/Círculo cierra mapa · ID %d"%dispositivo)
		j.position=Vector2(2160,1210)
		await esperar()
		await boton(JOY_BUTTON_A,true,dispositivo);await boton(JOY_BUTTON_A,false,dispositivo)
		comprobar(escena.campana.hechos.get("radio",false),"A/Cruz interactúa con radio · ID %d"%dispositivo)
	var controles:=root.get_node("Controles")
	controles._conexion(3,false)
	comprobar(controles.mando!=3,"Desconexión libera dispositivo activo")
	# Final alternativo a través del mismo diálogo que el jugador.
	var c: Node=escena.campana
	c.etapa=4
	c.hechos={"reporte":true,"archivo_enterrado":true}
	j.cordura=80
	for objeto in escena.get_node("Objetos").get_children():
		if objeto.titulo == "Sello roto": objeto.interactuar(j)
	comprobar(j.inventario.has("Sello roto"),"Sello del mapa original sirve para final alternativo")
	c.interactuar("guardia")
	await esperar()
	var botones: Array[Button]=[]
	for b in escena.interfaz.columna.get_children():
		if b is Button: botones.append(b)
	comprobar(botones.size()==4,"Sello y cordura habilitan final alternativo")
	botones[1].pressed.emit()
	await esperar()
	comprobar(c.final_liberado and c.hechos.get("reporte_entregado",false),"Don Chuy acepta liberar a los Ecos")
	lineas.append("RESULTADO: %d fallos"%fallos)
	FileAccess.open("res://docs/pruebas_controles.txt",FileAccess.WRITE).store_string("\n".join(lineas))
	for sufijo in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("res://partidas/prueba_controles.json"+sufijo)
	print(lineas[-1])
	quit(fallos)
