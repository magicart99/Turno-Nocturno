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

func _process(_delta: float) -> void:
	if is_instance_valid(sigilo_barra):
		sigilo_barra.visible=escuela.jugando
		sigilo_barra.value=escuela.jugador.sigilo
		sigilo_barra.modulate=Color("ff997f") if escuela.jugador.sigilo<=20 else Color.WHITE

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
			texto_menu("TURNO\nNOCTURNO", 61)
			texto_menu("Tu expediente sigue abierto. Por ahora.", 19, Color("9bb0b6"))
			primero = boton("Iniciar juego", escuela.iniciar)
			boton("Cargar partida", escuela.cargar, not escuela.Guardado.leer().is_empty())
			boton("Controles y opciones", func(): mostrar("opciones"))
			boton("Salir", escuela.salir)
		"pausa":
			texto_menu("TURNO EN PAUSA", 42)
			texto_menu("El pasillo espera. Respira.", 19)
			primero = boton("Continuar", escuela.continuar)
			boton("Guardar partida", func(): escuela.guardar_manual())
			boton("Controles y opciones", func(): mostrar("opciones"))
			boton("Menú principal", func(): escuela.solicitar_salida("menu"))
			boton("Salir", escuela.salir)
		"muerte":
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

func ajustar_cinematica() -> void:
	var escala := minf(capa_cinematica.size.x / 1280.0, capa_cinematica.size.y / 720.0)
	cinematica.size = Vector2(1280, 720) * escala
	cinematica.position = (capa_cinematica.size - cinematica.size) * 0.5
