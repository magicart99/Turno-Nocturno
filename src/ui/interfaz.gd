extends CanvasLayer
## Menús construidos aquí para mantener los textos y botones en un solo archivo.
var escuela: Node2D
var panel: Control
var columna: VBoxContainer
var aviso: Label
var subtitulo: Label
var hud: Label
var ayuda: Label
var barras: Label
var velo: ColorRect
var tween_aviso: Tween
var menu_actual: String = ""
var volumen: HSlider
var sigilo_barra: ProgressBar
var guia: Control
var fondo: Control
var cinematica: VideoStreamPlayer
var capa_cinematica: Control
var plano_grande: Control
var hud_estado: Control
var consejo: PanelContainer
var texto_consejo: Label
var tween_consejo: Tween
var aviso_objetivo: PanelContainer
var texto_objetivo: Label
var tween_objetivo: Tween
var ultimo_objetivo: String = ""
var titulo_menu: Label
var lema: Label
var lema_indice: int = 0
var rec: Label
var lineas_menu: ColorRect
var reloj_menu: float = 0.0
const LEMAS := [
	"Tu expediente sigue abierto. Por ahora.",
	"Después de las doce, nadie sale sin cerrar su turno.",
	"El Archivero no ve. Escucha.",
	"Algunos alumnos nunca entregaron su último trámite.",
	"Apaga la linterna. Respira. Escucha.",
]

func _ready() -> void:
	layer = 20
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tema := Theme.new()
	tema.default_font = preload("res://assets/fuentes/Barlow-Regular.ttf")
	raiz.theme = tema
	add_child(raiz)
	hud = etiqueta(raiz, Vector2(34, 24), 19, Color("ced9d9"))
	barras = etiqueta(raiz, Vector2(34, 124), 16, Color("9aadae"))
	sigilo_barra=ProgressBar.new()
	sigilo_barra.position=Vector2(34,181);sigilo_barra.size=Vector2(250,9)
	sigilo_barra.show_percentage=false;sigilo_barra.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var fondo_sigilo := StyleBoxFlat.new();fondo_sigilo.bg_color=Color("182b32")
	var reserva_sigilo := StyleBoxFlat.new();reserva_sigilo.bg_color=Color("88c8b1")
	sigilo_barra.add_theme_stylebox_override("background",fondo_sigilo)
	sigilo_barra.add_theme_stylebox_override("fill",reserva_sigilo)
	raiz.add_child(sigilo_barra)
	# Panel de estado dibujado: sustituye la línea de texto y las barras sueltas.
	hud_estado = preload("res://src/ui/hud_estado.gd").new()
	hud_estado.escuela = escuela
	raiz.add_child(hud_estado)
	# Aviso de objetivo nuevo: entra desde la izquierda y se desvanece.
	aviso_objetivo = PanelContainer.new()
	aviso_objetivo.position = Vector2(-400, 256)
	aviso_objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_objetivo := StyleBoxFlat.new()
	estilo_objetivo.bg_color = Color(0.03, 0.05, 0.06, 0.9)
	estilo_objetivo.border_color = Color("f4cb72")
	estilo_objetivo.border_width_left = 3
	estilo_objetivo.content_margin_left = 14
	estilo_objetivo.content_margin_right = 14
	estilo_objetivo.content_margin_top = 8
	estilo_objetivo.content_margin_bottom = 8
	aviso_objetivo.add_theme_stylebox_override("panel", estilo_objetivo)
	texto_objetivo = Label.new()
	texto_objetivo.add_theme_font_size_override("font_size", 16)
	texto_objetivo.add_theme_color_override("font_color", Color("f2e6c8"))
	aviso_objetivo.add_child(texto_objetivo)
	aviso_objetivo.modulate.a = 0.0
	raiz.add_child(aviso_objetivo)
	# Consejos del tutorial: abajo al centro, sin tapar la acción.
	consejo = PanelContainer.new()
	consejo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_consejo := estilo_objetivo.duplicate() as StyleBoxFlat
	estilo_consejo.border_color = Color("88d8b0")
	consejo.add_theme_stylebox_override("panel", estilo_consejo)
	texto_consejo = Label.new()
	texto_consejo.add_theme_font_size_override("font_size", 16)
	texto_consejo.add_theme_color_override("font_color", Color("d9efe4"))
	consejo.add_child(texto_consejo)
	consejo.modulate.a = 0.0
	consejo.position = Vector2(340, 530)
	raiz.add_child(consejo)
	ayuda = etiqueta(raiz, Vector2(34, 600), 19, Color("eee9d9"))
	ayuda.size = Vector2(1200,110)
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso = etiqueta(raiz, Vector2(0, 170), 33, Color("d6b38a"))
	aviso.size.x = 1280
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.modulate.a = 0
	subtitulo = etiqueta(raiz, Vector2(0, 218), 18, Color("b8c5c8"))
	subtitulo.size.x = 1280
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.modulate.a = 0
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mini := preload("res://src/ui/minimapa.gd").new()
	mini.escuela = escuela
	mini.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mini.position = Vector2(-265, 36)
	mini.size = Vector2(240, 290)
	raiz.add_child(mini)
	guia=preload("res://src/ui/guia_objetivo.gd").new()
	guia.escuela=escuela
	raiz.add_child(guia)
	raiz.add_child(panel)
	fondo = preload("res://src/ui/fondo_menu.gd").new()
	panel.add_child(fondo)
	# Líneas de video y una barra que rueda: estética de cinta de vigilancia.
	lineas_menu = ColorRect.new()
	lineas_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lineas_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombreado_lineas := Shader.new()
	sombreado_lineas.code = "shader_type canvas_item; void fragment(){ float l = 0.5 + 0.5*sin(FRAGCOORD.y*1.6); float barra = smoothstep(0.0, 0.03, abs(fract(UV.y*0.6 - TIME*0.07) - 0.5)); COLOR = vec4(0.0, 0.0, 0.0, l*0.10 + (1.0 - barra)*0.08); }"
	var material_lineas := ShaderMaterial.new()
	material_lineas.shader = sombreado_lineas
	lineas_menu.material = material_lineas
	panel.add_child(lineas_menu)
	velo = ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombreado := Shader.new()
	sombreado.code = "shader_type canvas_item; void fragment(){ float sombra = mix(0.82, 0.06, smoothstep(0.05, 0.72, UV.x)); COLOR = vec4(0.015, 0.022, 0.04, sombra); }"
	var material_velo := ShaderMaterial.new()
	material_velo.shader = sombreado
	velo.material = material_velo
	panel.add_child(velo)
	var marca := etiqueta(panel, Vector2(72, 48), 14, Color("bd694e"))
	marca.text = "UNIVERSIDAD TECNOLÓGICA  /  ARCHIVO GENERAL"
	columna = VBoxContainer.new()
	columna.position = Vector2(72, 115)
	columna.size.x = 565
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	var pie := etiqueta(panel, Vector2(72, 670), 14, Color("738a92"))
	pie.text = "EL ÚLTIMO CUATRIMESTRE    •    ARCHIVO GENERAL    •    Audífonos recomendados"
	rec = etiqueta(panel, Vector2(1010, 48), 16, Color("d65a4a"))

func _process(delta: float) -> void:
	# La barra de sigilo y la línea de texto siguen actualizándose (las pruebas las leen),
	# pero el panel de estado las sustituye en pantalla.
	if is_instance_valid(sigilo_barra):
		sigilo_barra.visible=false
		sigilo_barra.value=escuela.jugador.sigilo
	barras.visible = false
	reloj_menu += delta
	if escuela.jugando and escuela.campana != null:
		revisar_objetivo()
	if panel.visible:
		animar_menu()

func revisar_objetivo() -> void:
	var actual: String = escuela.campana.objetivo()
	if actual == ultimo_objetivo:
		return
	var anterior := ultimo_objetivo
	ultimo_objetivo = actual
	if anterior != "":
		mostrar_objetivo(actual)

func mostrar_consejo(texto: String) -> void:
	texto_consejo.text = "CONSEJO · " + texto
	consejo.reset_size()
	consejo.position = Vector2((1280.0 - consejo.size.x) * 0.5, 530)
	if tween_consejo:
		tween_consejo.kill()
	consejo.modulate.a = 0.0
	tween_consejo = create_tween()
	tween_consejo.tween_property(consejo, "modulate:a", 1.0, 0.3)
	tween_consejo.tween_interval(5.5)
	tween_consejo.tween_property(consejo, "modulate:a", 0.0, 0.8)

func mostrar_objetivo(texto: String) -> void:
	texto_objetivo.text = "OBJETIVO ACTUALIZADO\n" + texto
	escuela.sonidos.efecto("papel", Vector2.INF, -18)
	if tween_objetivo:
		tween_objetivo.kill()
	aviso_objetivo.position.x = -400
	aviso_objetivo.modulate.a = 1.0
	tween_objetivo = create_tween()
	tween_objetivo.tween_property(aviso_objetivo, "position:x", 34.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_objetivo.tween_interval(3.8)
	tween_objetivo.tween_property(aviso_objetivo, "modulate:a", 0.0, 0.8)

func animar_menu() -> void:
	var con_fondo: bool = menu_actual not in ["dialogo", "electricidad"]
	lineas_menu.visible = con_fondo
	rec.visible = con_fondo
	# Título con falla de neón: casi siempre estable, a veces parpadea en rojo.
	if is_instance_valid(titulo_menu):
		var falla: bool = sin(reloj_menu * 23.0) * sin(reloj_menu * 3.7) > 0.93
		titulo_menu.modulate = Color(1.0, 0.6, 0.58, 0.72) if falla else Color(1, 1, 1, 0.93 + 0.07 * sin(reloj_menu * 2.0))
	if is_instance_valid(lema) and menu_actual == "inicio":
		var indice: int = int(reloj_menu / 5.0) % LEMAS.size()
		if indice != lema_indice:
			lema_indice = indice
			lema.text = LEMAS[indice]
			lema.modulate.a = 0.0
			create_tween().tween_property(lema, "modulate:a", 1.0, 0.6)
	var segundos: int = int(reloj_menu)
	rec.text = ("●" if fmod(reloj_menu, 1.0) < 0.5 else "  ") + "  REC   00:%02d:%02d" % [int(segundos / 60.0) % 60, segundos % 60]

func etiqueta(padre: Node, posicion: Vector2, tamano: int, color: Color) -> Label:
	var texto := Label.new()
	texto.position = posicion
	texto.add_theme_font_override("font", preload("res://assets/fuentes/Rajdhani-SemiBold.ttf") if tamano >= 26 else preload("res://assets/fuentes/Barlow-Regular.ttf"))
	texto.add_theme_color_override("font_outline_color", Color(0.01,0.02,0.025,.95))
	texto.add_theme_constant_override("outline_size", 4)
	texto.add_theme_font_size_override("font_size", tamano)
	texto.add_theme_color_override("font_color", color)
	padre.add_child(texto)
	return texto

func texto_menu(texto: String, tamano: int, color: Color = Color("d6e0dd")) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 3)
	columna.add_child(label)
	return label

func boton(texto: String, accion: Callable, habilitado: bool = true) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(510, 44)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	for estado in ["normal", "hover", "focus", "pressed", "disabled"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("182931") if estado in ["hover", "focus", "pressed"] else Color("0e1b23")
		estilo.border_color = Color("bb765a") if estado == "focus" else Color("2b4048")
		estilo.bg_color.a = 0.88 if estado in ["hover", "focus", "pressed"] else 0.72
		estilo.set_corner_radius_all(5)
		estilo.set_border_width_all(1)
		estilo.content_margin_left = 18
		b.add_theme_stylebox_override(estado, estilo)
	b.disabled = not habilitado
	b.pressed.connect(accion)
	# Al enfocar o pasar el ratón, el texto se desliza y suena un clic suave.
	var activos: Array[StyleBoxFlat] = []
	for estado in ["hover", "focus"]:
		activos.append(b.get_theme_stylebox(estado) as StyleBoxFlat)
	var entrar := func():
		for e in activos:
			b.create_tween().tween_property(e, "content_margin_left", 34.0, 0.14).set_trans(Tween.TRANS_QUAD)
		escuela.sonidos.efecto("interruptor", Vector2.INF, -30)
	var salir := func():
		for e in activos:
			b.create_tween().tween_property(e, "content_margin_left", 18.0, 0.14).set_trans(Tween.TRANS_QUAD)
	b.focus_entered.connect(entrar)
	b.mouse_entered.connect(entrar)
	b.focus_exited.connect(salir)
	b.mouse_exited.connect(salir)
	columna.add_child(b)
	return b

func mostrar(tipo: String) -> void:
	if menu_actual == "opciones":
		if not Controles.guardar_opciones():
			escuela.jugador.mensaje = "No se pudieron guardar las opciones de audio y mando."
	menu_actual = tipo
	aviso.hide()
	subtitulo.hide()
	panel.show()
	fondo.activar(tipo not in ["dialogo", "electricidad"])
	escuela.sonidos.silenciar_ambiente(tipo not in ["dialogo", "electricidad"])
	hud.hide()
	ayuda.hide()
	barras.hide()
	for hijo in columna.get_children():
		columna.remove_child(hijo)
		hijo.queue_free()
	var primero: Button
	match tipo:
		"inicio":
			titulo_menu = texto_menu("TURNO\nNOCTURNO", 61)
			lema = texto_menu(LEMAS[lema_indice], 19, Color("9bb0b6"))
			primero = boton("Iniciar juego", escuela.iniciar)
			boton("Cargar partida", escuela.cargar, not escuela.Guardado.leer().is_empty())
			boton("Controles y opciones", func(): mostrar("opciones"))
			boton("Salir", escuela.salir)
		"pausa":
			titulo_menu = texto_menu("TURNO EN PAUSA", 42)
			texto_menu("El pasillo espera. Respira.", 19)
			primero = boton("Continuar", escuela.continuar)
			boton("Guardar partida", func(): escuela.guardar_manual())
			boton("Volver al último punto seguro", escuela.cargar, not escuela.Guardado.leer().is_empty())
			boton("Controles y opciones", func(): mostrar("opciones"))
			boton("Menú principal", func(): escuela.solicitar_salida("menu"))
			boton("Salir", escuela.salir)
		"muerte":
			if escuela.motivo_fin == "eco":
				texto_menu("TE CONVERTISTE\nEN ECO", 53, Color("8fb7c4"))
				texto_menu("ESTADO: BAJA POR ABANDONO\nLa presión no te mató: te fue apagando.\nCuida tu cordura con café, frituras y descanso en refugios.", 19)
			else:
				texto_menu("EXPEDIENTE\nCERRADO", 53, Color("d5826c"))
				texto_menu("ESTADO: ARCHIVADO\nEl silencio era tu única defensa.", 19)
			primero = boton("Reintentar desde el guardado", escuela.cargar, not escuela.Guardado.leer().is_empty())
			boton("Nuevo intento", func(): escuela.reiniciar("nuevo"))
			boton("Menú principal", func(): escuela.reiniciar("inicio"))
		"victoria":
			texto_menu("LOS ECOS\nSON LIBRES" if escuela.campana.final_liberado else "TURNO\nCERRADO", 48, Color("a9c6b5"))
			texto_menu("Don Chuy levanta la pluma. Amanece.\nLos nombres vuelven a la lista; los Ecos salen contigo.\nEsta vez nadie se queda atrás." if escuela.campana.final_liberado else "Don Chuy registra tu salida. Amanece.\nLalo cruza la pluma, agotado pero libre.\nEl próximo cuatrimestre… ¿será diferente?", 19)
			primero = boton("Jugar de nuevo", func(): escuela.reiniciar("nuevo"))
			boton("Menú principal", func(): escuela.reiniciar("inicio"))
		"confirmar_salida":
			texto_menu("TURNO SIN GUARDAR", 38)
			texto_menu("No se pudo guardar el estado actual.\nTu guardado anterior sigue disponible.\n\nPuedes volver, alejarte del Archivero y guardar.\nSi sales ahora, perderás el avance posterior\nal último guardado.", 19)
			primero = boton("Volver a la pausa", func(): mostrar("pausa"))
			boton("Salir sin guardar este avance", escuela.confirmar_salida)
		"opciones":
			texto_menu("CONTROLES", 35)
			texto_menu("WASD / flechas · Caminar     Shift · Correr\nRatón · Apuntar     E · Interactuar\nF · Linterna   Q · Distracción   I · Mochila   Tab/M · Mapa\nEsc · Pausa     F5 · Guardar en lugar seguro\n\nMando: stick izquierdo · Caminar / Menús\nStick derecho · Apuntar     Cruceta · Menús\nA / Cruz · Aceptar     B / Círculo · Agacharse / Volver\nX / Cuadrado · Linterna     LB / L1 · Correr\nY / Triángulo · Mochila     RB / R1 · Distracción\nStart · Pausa   LT / RT / V · Plano grande   C / Ctrl · Sigilo", 16)
			var vibrar := CheckButton.new()
			vibrar.text = "Vibración de latidos"
			vibrar.button_pressed = Controles.vibracion
			vibrar.toggled.connect(func(valor: bool): Controles.vibracion = valor; Controles.detener())
			columna.add_child(vibrar)
			texto_menu("Volumen general", 16)
			volumen = HSlider.new()
			volumen.max_value = 1.0
			volumen.step = 0.05
			volumen.value = escuela.sonidos.volumen
			volumen.value_changed.connect(escuela.sonidos.ajustar)
			columna.add_child(volumen)
			# Recompensas: sudaderas que se desbloquean al terminar el juego.
			texto_menu("Sudadera de Lalo", 16)
			var sudaderas := OptionButton.new()
			var Atuendo = preload("res://src/player/atuendo.gd")
			for i in range(Atuendo.ATUENDOS.size()):
				var dato: Array = Atuendo.ATUENDOS[i]
				var libre: bool = Controles.desbloqueados.has(i)
				sudaderas.add_item(dato[0] if libre else "Bloqueado · " + dato[3], i)
				sudaderas.set_item_disabled(i, not libre)
			sudaderas.select(Controles.atuendo)
			sudaderas.item_selected.connect(func(i: int): Controles.atuendo = i; escuela.jugador.vestir(i))
			columna.add_child(sudaderas)
			primero = boton("Volver", func(): mostrar("pausa" if escuela.partida_iniciada else "inicio"))
	if primero != null and primero.disabled:
		for candidato in columna.get_children():
			if candidato is Button and not candidato.disabled:
				primero = candidato
				break
	if primero != null:
		call_deferred("enfocar", primero.get_instance_id())
	columna.modulate.a = 0
	create_tween().tween_property(columna, "modulate:a", 1.0, 0.35)
	# Entrada escalonada: cada opción aparece un instante después de la anterior.
	var orden := 0
	for hijo in columna.get_children():
		if hijo is Control:
			hijo.modulate.a = 0.0
			var t := hijo.create_tween()
			t.tween_interval(0.06 * orden)
			t.tween_property(hijo, "modulate:a", 1.0, 0.3)
			orden += 1

func jugar() -> void:
	if is_instance_valid(plano_grande):
		plano_grande.queue_free()
		plano_grande = null
	var foco := get_viewport().gui_get_focus_owner()
	if foco: foco.release_focus()
	panel.hide()
	fondo.activar(false)
	escuela.sonidos.silenciar_ambiente(false)
	menu_actual = ""
	hud.show()
	ayuda.show()
	barras.show()
	aviso.show()
	subtitulo.show()

func anunciar(titulo: String, detalle: String) -> void:
	aviso.show()
	subtitulo.show()
	if tween_aviso:
		tween_aviso.kill()
	aviso.text = titulo
	subtitulo.text = detalle
	aviso.modulate.a = 0
	subtitulo.modulate.a = 0
	tween_aviso = create_tween()
	tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.5)
	tween_aviso.parallel().tween_property(subtitulo, "modulate:a", 1.0, 0.5)
	tween_aviso.tween_interval(3.0)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 1.0)
	tween_aviso.parallel().tween_property(subtitulo, "modulate:a", 0.0, 1.0)

func fundido_entrada(duracion: float = 0.8) -> void:
	# Corte a negro y apertura gradual: oculta el salto de lugar sin retrasar la lógica.
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.get_parent().add_child(negro)
	var t := negro.create_tween()
	t.tween_interval(0.25)
	t.tween_property(negro, "modulate:a", 0.0, duracion).set_trans(Tween.TRANS_SINE)
	t.tween_callback(negro.queue_free)

func elegir(titulo: String, detalle: String, opciones: Array, respuesta: Callable) -> void:
	escuela.jugando = false
	mostrar("dialogo")
	texto_menu(titulo, 30)
	var explicacion := texto_menu(detalle, 20)
	explicacion.custom_minimum_size.x = 540
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var primero: Button
	for i in range(opciones.size()):
		var indice: int = i
		var b := boton(opciones[i], func():
			escuela.continuar()
			respuesta.call(indice)
		)
		if i == 0: primero = b
	boton("Cancelar · Esc / B / Círculo", escuela.continuar)
	call_deferred("enfocar", primero.get_instance_id())

func mostrar_mapa() -> void:
	if is_instance_valid(plano_grande): return
	escuela.jugando = false
	escuela.jugador.sprite.pause()
	Controles.detener()
	menu_actual = "mapa"
	hud.hide()
	ayuda.hide()
	barras.hide()
	aviso.hide()
	subtitulo.hide()
	panel.hide()
	fondo.activar(false)
	guia.actualizar_ruta()
	plano_grande = ColorRect.new()
	plano_grande.color = Color(0.015,0.03,0.05,0.96)
	plano_grande.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.get_parent().add_child(plano_grande)
	plano_grande.modulate.a = 0.0
	create_tween().tween_property(plano_grande, "modulate:a", 1.0, 0.2)
	var titulo := etiqueta(plano_grande,Vector2(42,25),28,Color("def3ed"))
	titulo.text = "PLANO / " + ("EDIFICIO PRINCIPAL" if escuela.campana.lugar == "principal" else "CAMPUS EXTERIOR")
	var objetivo := etiqueta(plano_grande,Vector2(42,69),17,Color("f4cb72"))
	objetivo.text = escuela.campana.objetivo()
	var plano := preload("res://src/ui/mapa_campus.gd").new()
	plano.escuela = escuela
	plano.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plano.offset_left = 36
	plano.offset_top = 112
	plano.offset_right = -36
	plano.offset_bottom = -105
	plano_grande.add_child(plano)
	if escuela.campana.lugar == "campus":
		var estado := etiqueta(plano_grande,Vector2(65,165),22,Color("d6e7df"))
		estado.text = "CIERRA TU TURNO"
		var pasos := etiqueta(plano_grande,Vector2(65,215),18,Color("a9c4c8"))
		pasos.text = "01 / PRINCIPAL\nRegistrar la salida\n\n02 / PATIO\nRecuperar nota y USB\n\n03 / SERVICIOS\nHablar con Talleres\n\n04 / VIGILANCIA\nEntregar el reporte"
		var destino := etiqueta(plano_grande,Vector2(900,175),20,Color("f4cb72"))
		destino.text = "DESTINO ACTUAL"
		var pista := etiqueta(plano_grande,Vector2(900,220),18,Color("d6e7df"))
		pista.size.x = 290
		pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pista.text = guia.texto + "\n\nEl mapa está completo desde el inicio. La línea dorada te lleva al siguiente objetivo.\n\n" + ("Servicios: pendiente de autorización" if escuela.campana.etapa < 3 else "Servicios: acceso autorizado") + "\n\n" + ("Estacionamiento: cerrado" if escuela.campana.etapa < 4 else "Estacionamiento: abierto")
	var leyenda := etiqueta(plano_grande,Vector2(42,635),16,Color("b8d2d7"))
	leyenda.text = "▲ Lalo   ! Destino   ━ Ruta   □ Refugio   ◎ Recuerdo   • Interacción   |   El plano pausa el turno."
	var cerrar := Button.new()
	cerrar.text = "Cerrar · V / Tab / LT / RT / Esc"
	cerrar.position = Vector2(875,660)
	cerrar.size = Vector2(365,40)
	cerrar.pressed.connect(escuela.continuar)
	plano_grande.add_child(cerrar)
	cerrar.grab_focus()

func enfocar(id: int) -> void:
	var control := instance_from_id(id) as Control
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()

func reproducir_muerte() -> void:
	menu_actual = "cinematica"
	panel.hide()
	fondo.activar(false)
	escuela.sonidos.silenciar_ambiente(true)
	hud.hide()
	ayuda.hide()
	barras.hide()
	aviso.hide()
	subtitulo.hide()
	var foco := get_viewport().gui_get_focus_owner()
	if foco: foco.release_focus()
	capa_cinematica = ColorRect.new()
	capa_cinematica.color = Color.BLACK
	capa_cinematica.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.get_parent().add_child(capa_cinematica)
	cinematica = VideoStreamPlayer.new()
	cinematica.stream = preload("res://assets/cinematicas/muerte_archivero.ogv")
	cinematica.expand = true
	cinematica.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	capa_cinematica.add_child(cinematica)
	capa_cinematica.resized.connect(ajustar_cinematica)
	ajustar_cinematica()
	cinematica.play()
	await cinematica.finished
	capa_cinematica.queue_free()

func _exit_tree() -> void:
	# Si el juego se cierra durante la cinemática, liberar el video evita avisos de recursos en uso.
	if is_instance_valid(cinematica):
		cinematica.stop()
		cinematica.stream = null

func ajustar_cinematica() -> void:
	var escala := minf(capa_cinematica.size.x / 1280.0, capa_cinematica.size.y / 720.0)
	cinematica.size = Vector2(1280, 720) * escala
	cinematica.position = (capa_cinematica.size - cinematica.size) * 0.5
