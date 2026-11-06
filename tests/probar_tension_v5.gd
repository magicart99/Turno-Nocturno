extends SceneTree
var escuela: Node2D
var fallos: int = 0
var informe: Array[String] = []
func _initialize() -> void:call_deferred("ejecutar")
func comprobar(ok: bool, msg: String) -> void:
	informe.append(("OK " if ok else "FALLO ")+msg);print(informe[-1])
	if not ok:fallos+=1
func esperar(n: int=4) -> void:
	for i in range(n):await process_frame;await physics_frame
func cantidad_encendidas() -> int:
	var total: int=0
	for z in escuela.zonas:
		if z!="Exterior_Caseta" and escuela.zonas[z]:total+=1
	return total
func capturar(nombre: String) -> void:
	if not "--capturas" in OS.get_cmdline_user_args():return
	await create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/"+nombre+".png")
func resolver() -> void:
	var tablero: CanvasLayer=escuela.campana.tablero
	for fuente in tablero.fuentes:
		if fuente.disabled:continue
		fuente.pressed.emit()
		for destino in tablero.destinos:
			if destino.text==fuente.text:destino.pressed.emit();break
		await esperar()
	tablero.fase=0.0
	tablero.estabilizar()
	await esperar()
func ejecutar() -> void:
	escuela=load("res://scenes/escuela.tscn").instantiate();root.add_child(escuela);current_scene=escuela
	await esperar()
	escuela.Guardado.ruta="res://partidas/prueba_tension_v5.json"
	escuela.partida_iniciada=true;escuela.jugando=true;escuela.interfaz.jugar()
	var j: CharacterBody2D=escuela.jugador
	var c: Node=escuela.campana
	comprobar(escuela.get_node("DetallesPrincipal").has_node("tablero_principal"),"Caja principal instalada en Entrada")
	comprobar(cantidad_encendidas()==1 and c.alimentado=="Entrada","Inicio: una sola zona alimentada")
	for sonido in ["jadeo","chispa","rele","susurro","metal"]:
		comprobar(escuela.sonidos.recursos[sonido].get_length()>0,"Efecto original importado: "+sonido)
	c.reparar("Computo");await esperar()
	var t: CanvasLayer=c.tablero
	comprobar(escuela.interfaz.menu_actual=="electricidad" and not escuela.jugando,"Tablero pausa el movimiento y abre la interfaz de cables")
	await capturar("tablero_v5_cables")
	var antes: float=t.tiempo
	t.fuentes[0].pressed.emit()
	for destino in t.destinos:
		if destino.text!=t.fuentes[0].text:destino.pressed.emit();break
	comprobar(t.tiempo<=antes-5 and t.conectados.is_empty(),"Conexión errónea resta tiempo sin conectar")
	comprobar(c.alimentado=="Entrada","Error conserva alimentación anterior")
	t.pausado=true;antes=t.tiempo;await create_timer(.15).timeout
	comprobar(t.tiempo==antes,"Pausa congela reloj de reparación")
	t.pausado=false
	# Interacción por el sistema GUI real, con mando y teclado.
	t.fuentes[0].grab_focus()
	var a := InputEventJoypadButton.new();a.device=3;a.button_index=JOY_BUTTON_A;a.pressed=true
	Input.parse_input_event(a);Input.flush_buffered_events();await esperar()
	a.pressed=false;Input.parse_input_event(a);Input.flush_buffered_events();await esperar()
	comprobar(t.elegido==0,"A / Cruz selecciona un terminal desde el foco GUI")
	for b in t.destinos:
		if b.text==t.fuentes[0].text:b.grab_focus();break
	var k := InputEventKey.new();k.keycode=KEY_ENTER;k.physical_keycode=KEY_ENTER;k.pressed=true
	Input.parse_input_event(k);Input.flush_buffered_events();await esperar()
	k.pressed=false;Input.parse_input_event(k);Input.flush_buffered_events();await esperar()
	comprobar(0 in t.conectados,"Enter conecta el cable correcto desde el foco GUI")
	t.fuentes[2].pressed.emit()
	for b in t.destinos:
		if b.text==t.fuentes[2].text:b.pressed.emit();break
	await capturar("tablero_v5_conectando")
	await resolver()
	comprobar(c.alimentado=="Computo" and escuela.zonas["Computo"] and not escuela.zonas["Entrada"] and cantidad_encendidas()==1,"Resolver cuatro cables alimenta Cómputo y apaga Entrada")
	c.reparar("Rectoria_Archivo");await esperar();await resolver()
	comprobar(c.alimentado=="Rectoria_Archivo" and not escuela.zonas["Computo"] and cantidad_encendidas()==1,"Cambiar a Rectoría apaga Cómputo")
	c.reparar("Taller");await esperar();c.tablero.cancelar_reparacion();await esperar()
	comprobar(c.alimentado=="Rectoria_Archivo" and cantidad_encendidas()==1,"Cancelar no altera el circuito activo")
	c.reparar("Taller");await esperar();c.tablero.tiempo=.02;await esperar(8)
	comprobar(escuela.jugando and c.alimentado=="Rectoria_Archivo","Agotar el reloj aborta la reparación y permite reintentar")
	j.set_physics_process(false)
	escuela.archivero.set_physics_process(false)
	escuela.archivero.activo=true;escuela.archivero.position=j.position+Vector2(100,0);escuela.tiempo=20
	j.agachado=true;j.sigilo=100;j.actualizar_sigilo(20.1)
	comprobar(not j.agachado and j.sigilo==0 and j.sigilo_agotado,"20 segundos agachado agotan reserva y obligan a levantarse")
	comprobar(escuela.archivero.estado=="INVESTIGANDO","El jadeo por agotamiento atrae al Archivero")
	j.actualizar_sigilo(2.5)
	comprobar(j.sigilo==0 and j.sigilo_agotado,"Agotamiento exige descanso antes de recuperar")
	j.actualizar_sigilo(5)
	comprobar(j.sigilo>=35 and not j.sigilo_agotado,"Recuperar 35% permite volver a agacharse")
	j.sigilo=42;j.descanso_sigilo=1.5
	comprobar(escuela.guardar_partida(),"Guarda reserva de sigilo y salida eléctrica")
	var datos: Dictionary=escuela.Guardado.leer()
	comprobar(datos.jugador.sigilo==42 and datos.jugador.descanso_sigilo==1.5 and datos.campana.alimentado=="Rectoria_Archivo","Guardado conserva reserva y circuito")
	j.sigilo=100;escuela.alimentar_zona("Computo")
	await escuela.aplicar_guardado()
	comprobar(j.sigilo==42 and c.alimentado=="Rectoria_Archivo" and cantidad_encendidas()==1,"Cargar no recarga sigilo ni enciende múltiples circuitos")
	# Un guardado de v4 puede traer varias zonas encendidas. Se normaliza al cargar.
	var viejo: Dictionary=datos.duplicate(true)
	viejo.campana.erase("alimentado");viejo.zonas["Computo"]=true;viejo.zonas["Taller"]=true
	escuela.Guardado.guardar(viejo)
	await escuela.aplicar_guardado()
	comprobar(cantidad_encendidas()==1,"Partida antigua con varios circuitos migra a una sola salida")
	informe.append("RESULTADO: %d fallos"%fallos);print(informe[-1])
	FileAccess.open("res://docs/pruebas_tension_v5.txt",FileAccess.WRITE).store_string("\n".join(informe))
	for sufijo in ["",".bak",".tmp"]:DirAccess.remove_absolute(escuela.Guardado.ruta+sufijo)
	quit(fallos)
