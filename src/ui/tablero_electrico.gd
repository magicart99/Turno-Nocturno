extends CanvasLayer
## Tablero de emergencia: cuatro cables y una sola salida de alimentación.
## Un circuito ya reparado se conmuta sin repetir el cableado. Los chispazos
## se escuchan en el pasillo cuando Lalo vuelve al juego.
var escuela: Node2D
var circuito: String = "Computo"
var tiempo: float = 45.0
var pausado: bool = false
var terminado: bool = false
var elegido: int = -1
var calibrando := false
var fase := 0.0
var valor_medidor := 50.0
var velocidad_aguja := 1.6
var cambio_aguja := 0.0
var medidor: Control
var activar: Button
var conmutar: Button
var orden: Array[int] = [2,0,3,1]
var conectados: Array[int] = []
var fuentes: Array[Button] = []
var destinos: Array[Button] = []
var zonas: Array[String] = []
var selector: OptionButton
var estado: Label
var reloj: Label
var plano: Control
var raiz: Control
var velo: ColorRect
var chispazos := 0
var sacudida := 0.0
var glitch := 0.0
var parpadeo := 0.0
var susto_hecho := false
var momento_susto := 30.0
var chispas: Array[Dictionary] = []
const COLORES := [Color("65dc99"),Color("eac966"),Color("59aaff"),Color("f96d65")]
const NOMBRES := ["VERDE · 1","AMARILLO · 2","AZUL · 3","ROJO · 4"]
const FUENTE_TITULO = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")

func etiqueta(padre: Node, texto: String, p: Vector2, tam: int) -> Label:
	var l := Label.new()
	l.text=texto;l.position=p;l.add_theme_font_size_override("font_size",tam)
	padre.add_child(l);return l

func nombre_zona(z: String) -> String:
	return z.replace("Exterior_", "").replace("_", " ").replace("Computo", "Centro de Cómputo")

func _ready() -> void:
	layer=30
	orden.shuffle()
	momento_susto = randf_range(20.0, 34.0)
	raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tema := Theme.new()
	tema.default_font = preload("res://assets/fuentes/Barlow-Regular.ttf")
	raiz.theme = tema
	add_child(raiz)
	velo = ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color=Color(.005,.012,.018,.97);raiz.add_child(velo)
	plano=preload("res://src/ui/cables_tablero.gd").new()
	plano.tablero=self;plano.position=Vector2(34,35);plano.size=Vector2(625,648)
	raiz.add_child(plano)
	for i in range(4):
		var b := crear_terminal(i,true)
		fuentes.append(b)
		b.pressed.connect(func(): seleccionar(i))
		var d := crear_terminal(orden[i],false)
		destinos.append(d)
		d.pressed.connect(func(): conectar(i))
	reloj=etiqueta(plano,"00:45",Vector2(490,49),27)
	reloj.add_theme_color_override("font_color",Color("65f7ab"))
	var titulo := etiqueta(raiz,"ALIMENTACIÓN DE EMERGENCIA",Vector2(704,60),30)
	titulo.add_theme_font_override("font",FUENTE_TITULO)
	etiqueta(raiz,"Solo un circuito conectado a la vez",Vector2(704,104),19)
	selector=OptionButton.new()
	selector.position=Vector2(704,150);selector.size=Vector2(520,45)
	selector.add_theme_font_size_override("font_size",20)
	raiz.add_child(selector)
	for z in escuela.zonas:
		if z == "Exterior_Caseta":continue
		zonas.append(z)
	zonas.sort()
	for z in zonas:selector.add_item(nombre_zona(z))
	if circuito in zonas:selector.select(zonas.find(circuito))
	else:
		circuito=zonas[0]
	selector.item_selected.connect(func(i: int): circuito=zonas[i]; escuela.campana.circuito=circuito; actualizar_conmutar())
	conmutar=Button.new()
	conmutar.position=Vector2(704,205);conmutar.size=Vector2(520,40)
	conmutar.add_theme_color_override("font_color",Color("9fe7c2"))
	conmutar.pressed.connect(completar_reparacion)
	raiz.add_child(conmutar)
	var instrucciones := etiqueta(raiz,"1. Elige la zona que quieres alimentar.\n2. Toma un cable de la izquierda y llévalo a su terminal.\n3. Con los cuatro conectados, fija la aguja en la franja verde.\nCada error resta 5 s y el chispazo se oye en el pasillo.\nRatón · Flechas / cruceta + Enter / A · Esc / B cancela · P / Start pausa",Vector2(704,258),16)
	instrucciones.size.x=520;instrucciones.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	instrucciones.add_theme_color_override("font_color",Color("a9bcbc"))
	medidor = Control.new()
	medidor.position=Vector2(704,440);medidor.size=Vector2(300,135)
	medidor.mouse_filter=Control.MOUSE_FILTER_IGNORE
	medidor.visible=false
	medidor.draw.connect(dibujar_medidor)
	raiz.add_child(medidor)
	activar=Button.new()
	activar.text="Fijar aguja";activar.position=Vector2(1020,490);activar.size=Vector2(204,48)
	activar.visible=false;activar.pressed.connect(estabilizar)
	raiz.add_child(activar)
	estado=etiqueta(raiz,"0 / 4 CABLES CONECTADOS",Vector2(704,592),20)
	var cancelar := Button.new()
	cancelar.text="Cancelar reparación";cancelar.position=Vector2(704,640);cancelar.size=Vector2(520,42)
	cancelar.pressed.connect(cancelar_reparacion);raiz.add_child(cancelar)
	actualizar_conmutar()
	escuela.jugando=false;escuela.interfaz.menu_actual="electricidad"
	selector.call_deferred("grab_focus")

func ya_reparado(zona: String) -> bool:
	return zona == "Entrada" or escuela.campana.hechos.get("electricidad_" + zona, false)

func actualizar_conmutar() -> void:
	conmutar.visible = ya_reparado(circuito) and conectados.is_empty() and elegido < 0 and not calibrando
	conmutar.text = "Conmutar a %s · ya reparado, sin cables" % nombre_zona(circuito)

func crear_terminal(id: int, izquierda: bool) -> Button:
	var b := Button.new()
	b.text=NOMBRES[id]
	var fila: int = id if izquierda else orden.find(id)
	b.position=Vector2(40 if izquierda else 466,139+108*fila)
	b.size=Vector2(123,84)
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",COLORES[id])
	for e in ["normal","hover","focus","pressed","disabled"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color=Color("101f25") if e != "focus" else Color("28434a")
		estilo.border_color=COLORES[id] if e == "focus" else Color("3b5257")
		estilo.set_border_width_all(2);estilo.set_corner_radius_all(4)
		b.add_theme_stylebox_override(e,estilo)
	plano.add_child(b);return b

func enfocar_libre(botones: Array[Button]) -> void:
	for b in botones:
		if not b.disabled:b.grab_focus();return

func seleccionar(id: int) -> void:
	if terminado or pausado or id in conectados:return
	elegido=id;selector.disabled=true;conmutar.hide()
	estado.text="SELECCIONADO: " + NOMBRES[id]
	escuela.sonidos.efecto("interruptor",Vector2.INF,-20)
	plano.queue_redraw()
	enfocar_libre(destinos)

func conectar(fila: int) -> void:
	if terminado or pausado or elegido < 0:return
	var punto := Vector2(450,181+fila*108)
	if orden[fila] != elegido:
		tiempo=maxf(0,tiempo-5)
		chispazos += 1
		escuela.sonidos.efecto("chispa",Vector2.INF,-12)
		estado.text="CORTOCIRCUITO · −5 s · el chispazo se oyó en el pasillo"
		lanzar_chispas(punto, Color("ffd27a"), 24)
		sacudida = 0.35; parpadeo = 0.3
		Controles.vibrar(0.45,0.18)
		elegido=-1
		enfocar_libre(fuentes)
	else:
		lanzar_chispas(punto, COLORES[elegido].lightened(.4), 10)
		conectados.append(elegido)
		fuentes[elegido].disabled=true;destinos[fila].disabled=true
		elegido=-1
		escuela.sonidos.efecto("rele",Vector2.INF,-17)
		estado.text="%d / 4 CABLES CONECTADOS"%conectados.size()
		enfocar_libre(fuentes)
		if conectados.size()==4:
			calibrando=true
			tiempo=maxf(tiempo,15.0)
			medidor.show();activar.show();activar.grab_focus()
			estado.text="FIJA LA AGUJA EN VERDE · 40–60%"
	plano.queue_redraw()

func lanzar_chispas(p: Vector2, color: Color, cantidad: int) -> void:
	for i in range(cantidad):
		var v := Vector2.from_angle(randf() * TAU) * randf_range(60.0, 260.0) + Vector2(0, -60)
		chispas.append({"p": p, "v": v, "t": randf_range(0.25, 0.6), "c": color})

func actualizar_chispas(delta: float) -> void:
	var vivas: Array[Dictionary] = []
	for c in chispas:
		var v: Vector2 = c["v"]
		v.y += 520.0 * delta
		c["v"] = v
		c["p"] = Vector2(c["p"]) + v * delta
		c["t"] = float(c["t"]) - delta
		if float(c["t"]) > 0.0:
			vivas.append(c)
	chispas = vivas

func punto_vivo() -> Vector2:
	# El cable suelto sigue al ratón; con mando o teclado, al terminal enfocado.
	var raton := plano.get_local_mouse_position()
	if not Controles.usando_mando and Rect2(Vector2.ZERO, plano.size).has_point(raton):
		return raton
	var foco := get_viewport().gui_get_focus_owner()
	if foco is Button and destinos.has(foco):
		return Vector2(450, foco.position.y + foco.size.y * 0.5)
	return Vector2(300, 181 + elegido * 108)

func emitir_chispazos() -> void:
	# Mientras el tablero está abierto el turno se pausa; el ruido llega al volver.
	if chispazos <= 0: return
	escuela.emitir_ruido(escuela.jugador.position, minf(0.35 + chispazos * 0.1, 0.65))

func completar_reparacion() -> void:
	if terminado or pausado:return
	terminado=true
	escuela.sonidos.efecto("rele",Vector2.INF,-12)
	escuela.continuar()
	escuela.campana.conectar_circuito(circuito)
	emitir_chispazos()
	queue_free()

func cancelar_reparacion() -> void:
	if terminado:return
	terminado=true;escuela.continuar();emitir_chispazos();queue_free()
	escuela.jugador.mensaje="Reparación cancelada. La alimentación anterior permanece."

func asustar() -> void:
	susto_hecho = true
	glitch = 1.5; sacudida = 0.5; parpadeo = 0.9
	escuela.sonidos.efecto("susurro", Vector2.INF, -9)
	escuela.sonidos.efecto("metal", Vector2.INF, -16)
	Controles.vibrar(0.5, 0.3)
	estado.text = "…algo golpea la caja desde adentro. No te detengas."

func _input(e: InputEvent) -> void:
	if terminado:return
	if e.is_action_pressed("ui_cancel"):
		cancelar_reparacion();get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pausa") or (e is InputEventKey and e.pressed and not e.echo and e.physical_keycode==KEY_P):
		pausado=not pausado
		estado.text="TABLERO EN PAUSA · Start / P para continuar" if pausado else "%d / 4 CABLES CONECTADOS"%conectados.size()
		get_viewport().set_input_as_handled()

func _notification(que: int) -> void:
	if que==NOTIFICATION_APPLICATION_FOCUS_OUT:
		pausado=true
		if is_instance_valid(estado):estado.text="TABLERO EN PAUSA · Start / P para continuar"

func _process(delta: float) -> void:
	actualizar_chispas(delta)
	sacudida = maxf(0.0, sacudida - delta)
	glitch = maxf(0.0, glitch - delta)
	parpadeo = maxf(0.0, parpadeo - delta)
	raiz.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * sacudida * 22.0
	velo.color.a = 0.97 if parpadeo <= 0.0 or sin(Time.get_ticks_msec() * 0.08) > 0.0 else 0.82
	plano.queue_redraw()
	if terminado or pausado:return
	if not susto_hecho and tiempo <= momento_susto:
		asustar()
	if calibrando:
		# La aguja cambia de ritmo: hay que observarla, no contar.
		cambio_aguja -= delta
		if cambio_aguja <= 0.0:
			cambio_aguja = randf_range(0.45, 1.1)
			velocidad_aguja = randf_range(1.1, 2.7)
		fase += delta * velocidad_aguja
		valor_medidor = (sin(fase)+1.0)*50.0
		activar.text = "Fijar aguja · %d%%" % int(valor_medidor)
		medidor.queue_redraw()
	tiempo=maxf(0,tiempo-delta)
	reloj.text="00:%02d"%ceili(tiempo)
	reloj.modulate=Color("ff9a86") if tiempo<=10 else Color.WHITE
	if tiempo<=0:
		terminado=true
		escuela.continuar()
		escuela.jugador.mensaje="La reparación falló. El cortocircuito hizo ruido; puedes volver a intentarlo."
		escuela.sonidos.efecto("chispa",Vector2.INF,-8)
		escuela.emitir_ruido(escuela.jugador.position,.9)
		queue_free()

func dibujar_medidor() -> void:
	var centro := Vector2(150, 120)
	var radio := 100.0
	medidor.draw_rect(Rect2(Vector2.ZERO, medidor.size), Color("0b171c"))
	medidor.draw_arc(centro, radio, PI, PI * 1.4, 24, Color("7a302b"), 12.0)
	medidor.draw_arc(centro, radio, PI * 1.4, PI * 1.6, 12, Color("65dc99"), 12.0)
	medidor.draw_arc(centro, radio, PI * 1.6, TAU, 24, Color("7a302b"), 12.0)
	for i in range(11):
		var angulo_marca := PI + PI * i / 10.0
		medidor.draw_line(centro + Vector2.from_angle(angulo_marca) * (radio - 18.0), centro + Vector2.from_angle(angulo_marca) * (radio - 8.0), Color("9aadae"), 2.0)
	var angulo := PI + PI * valor_medidor / 100.0
	var dentro := valor_medidor >= 40.0 and valor_medidor <= 60.0
	medidor.draw_line(centro, centro + Vector2.from_angle(angulo) * (radio - 12.0), Color("eafff3") if dentro else Color("ffb38a"), 3.0)
	medidor.draw_circle(centro, 7.0, Color("d6e7df"))
	medidor.draw_string(FUENTE_TITULO, Vector2(0, 132), "%d%%" % int(valor_medidor), HORIZONTAL_ALIGNMENT_CENTER, 300, 18, Color("65dc99") if dentro else Color("eac966"))

func estabilizar() -> void:
	if terminado or pausado or not calibrando:return
	var valor := (sin(fase)+1.0)*50.0
	if valor < 40 or valor > 60:
		tiempo=maxf(0,tiempo-3)
		chispazos += 1
		sacudida = 0.2
		estado.text="FUERA DE RANGO · −3 s · cables conservados"
		escuela.sonidos.efecto("chispa",Vector2.INF,-18)
		return
	completar_reparacion()
