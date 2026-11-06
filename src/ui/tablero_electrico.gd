extends CanvasLayer
## Cuatro conexiones, una sola salida de alimentación. Imagen aportada por el usuario.
var escuela: Node2D
var circuito: String = "Computo"
var tiempo: float = 45.0
var pausado: bool = false
var terminado: bool = false
var elegido: int = -1
var calibrando := false
var fase := 0.0
var medidor: ProgressBar
var activar: Button
var orden: Array[int] = [2,0,3,1]
var conectados: Array[int] = []
var fuentes: Array[Button] = []
var destinos: Array[Button] = []
var zonas: Array[String] = []
var selector: OptionButton
var estado: Label
var reloj: Label
var plano: Control
const COLORES := [Color("65dc99"),Color("eac966"),Color("59aaff"),Color("f96d65")]
const NOMBRES := ["VERDE · 1","AMARILLO · 2","AZUL · 3","ROJO · 4"]

func etiqueta(padre: Node, texto: String, p: Vector2, tam: int) -> Label:
	var l := Label.new()
	l.text=texto;l.position=p;l.add_theme_font_size_override("font_size",tam)
	padre.add_child(l);return l
func _ready() -> void:
	layer=30
	orden.shuffle()
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tema := Theme.new()
	tema.default_font = preload("res://assets/fuentes/Barlow-Regular.ttf")
	raiz.theme = tema
	add_child(raiz)
	var velo := ColorRect.new()
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
	etiqueta(raiz,"ALIMENTACIÓN DE EMERGENCIA",Vector2(704,65),28)
	etiqueta(raiz,"Solo un circuito conectado a la vez",Vector2(704,113),21)
	selector=OptionButton.new()
	selector.position=Vector2(704,172);selector.size=Vector2(520,45)
	selector.add_theme_font_size_override("font_size",20)
	raiz.add_child(selector)
	for z in escuela.zonas:
		if z == "Exterior_Caseta":continue
		zonas.append(z)
	zonas.sort()
	for z in zonas:selector.add_item(z.replace("Exterior_", "").replace("_", " ").replace("Computo", "Centro de Cómputo"))
	if circuito in zonas:selector.select(zonas.find(circuito))
	else:
		circuito=zonas[0]
	selector.item_selected.connect(func(i: int): circuito=zonas[i]; escuela.campana.circuito=circuito)
	var instrucciones := etiqueta(raiz,"1. Elige la zona que quieres alimentar.\n2. Selecciona un cable de la izquierda.\n3. Conecta su color y número a la derecha.\n\nCuatro cables · 45 segundos · error: −5 s\nAl terminar, estabiliza entre 40 y 60%.\nFlechas / cruceta · elegir terminal\nEnter / A / Cruz · conectar / Ratón\nB / Círculo / Esc · cancelar\nStart / Options / P · pausar",Vector2(704,242),16)
	instrucciones.size.x=520;instrucciones.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	medidor = ProgressBar.new()
	medidor.position=Vector2(704,520);medidor.size=Vector2(300,24)
	medidor.show_percentage=false;medidor.visible=false
	raiz.add_child(medidor)
	activar=Button.new()
	activar.text="Estabilizar";activar.position=Vector2(1020,510);activar.size=Vector2(204,42)
	activar.visible=false;activar.pressed.connect(estabilizar)
	raiz.add_child(activar)
	estado=etiqueta(raiz,"0 / 4 CABLES CONECTADOS",Vector2(704,580),20)
	var cancelar := Button.new()
	cancelar.text="Cancelar reparación";cancelar.position=Vector2(704,635);cancelar.size=Vector2(520,42)
	cancelar.pressed.connect(cancelar_reparacion);raiz.add_child(cancelar)
	escuela.jugando=false;escuela.interfaz.menu_actual="electricidad"
	selector.call_deferred("grab_focus")

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

func seleccionar(id: int) -> void:
	if terminado or pausado or id in conectados:return
	elegido=id;selector.disabled=true
	estado.text="SELECCIONADO: " + NOMBRES[id]
	plano.queue_redraw()
	for b in destinos:
		if not b.disabled:b.grab_focus();break

func conectar(fila: int) -> void:
	if terminado or pausado or elegido < 0:return
	if orden[fila] != elegido:
		tiempo=maxf(0,tiempo-5)
		escuela.sonidos.efecto("chispa",Vector2.INF,-12)
		estado.text="CORTOCIRCUITO · −5 s · vuelve a elegir"
		elegido=-1
		fuentes[0].grab_focus()
	else:
		conectados.append(elegido)
		fuentes[elegido].disabled=true;destinos[fila].disabled=true
		elegido=-1
		escuela.sonidos.efecto("rele",Vector2.INF,-17)
		estado.text="%d / 4 CABLES CONECTADOS"%conectados.size()
		for b in fuentes:
			if not b.disabled:b.grab_focus();break
		if conectados.size()==4:
			calibrando=true
			tiempo=maxf(tiempo,15.0)
			medidor.show();activar.show();activar.grab_focus()
			estado.text="ESTABILIZA EN VERDE · 40–60%"
	plano.queue_redraw()

func cancelar_reparacion() -> void:
	if terminado:return
	terminado=true;escuela.continuar();queue_free()
	escuela.jugador.mensaje="Reparación cancelada. La alimentación anterior permanece."

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
	if terminado or pausado:return
	if calibrando:
		fase += delta * 1.6
		medidor.value=(sin(fase)+1.0)*50.0
		medidor.modulate=Color("65dc99") if medidor.value >= 40 and medidor.value <= 60 else Color("eac966")
		activar.text="Estabilizar %d%%" % int(medidor.value)
	tiempo=maxf(0,tiempo-delta)
	reloj.text="00:%02d"%ceili(tiempo)
	reloj.modulate=Color("ff9a86") if tiempo<=10 else Color.WHITE
	plano.queue_redraw()
	if tiempo<=0:
		terminado=true
		escuela.continuar()
		escuela.jugador.mensaje="La reparación falló. El cortocircuito hizo ruido; puedes volver a intentarlo."
		escuela.sonidos.efecto("chispa",Vector2.INF,-8)
		escuela.emitir_ruido(escuela.jugador.position,.9)
		queue_free()

func estabilizar() -> void:
	if terminado or pausado or not calibrando:return
	var valor := (sin(fase)+1.0)*50.0
	if valor < 40 or valor > 60:
		tiempo=maxf(0,tiempo-3)
		estado.text="FUERA DE RANGO · −3 s · cables conservados"
		escuela.sonidos.efecto("chispa",Vector2.INF,-18)
		return
	terminado=true
	escuela.sonidos.efecto("rele",Vector2.INF,-12)
	escuela.continuar()
	escuela.campana.conectar_circuito(circuito)
	queue_free()
