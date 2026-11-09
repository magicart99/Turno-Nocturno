extends CanvasLayer
## Mochila sobre la partida: imágenes originales, foco accesible y objetos persistentes.
var escuela: Node2D
const Mochila = preload("res://src/player/mochila.gd")
var descartar: Button
const Productos = preload("res://src/world/productos_cafeteria.gd")
var tienda := false
var saldo: Label
var raiz: Control
var rejilla: GridContainer
var detalle: Label
var nombre: Label
var imagen: TextureRect
var usar: Button
var pagina_texto: Label
var animacion_detalle: Tween
var diario_indice := -1
var pagina := 0
var seleccion := ""
var objetos: Array[String]=[]
var cantidades: Dictionary={}
var panel_misiones: PanelContainer
const CATALOGO = {
 "Memoria USB del patio":["usb.png","EVIDENCIA","Desenterrada en el patio. Muéstrala a la Prefecta y después entrégala al de Talleres, en oficinas."],
 "Nota de la banca":["papeles.png","EVIDENCIA","Prueba que había alumnos dentro cuando cerraron. Entrégala a la Prefecta."],
 "Grabación recuperada":["usb.png","EVIDENCIA","El de Talleres recuperó las voces. Busca el reporte de cafetería para llevar las pruebas a Don Chuy."],
 "Linterna":["ui/linterna.svg","EQUIPO","Ilumina el camino. F / X para encenderla. El haz revela obstáculos, pero el Archivero puede verlo."],
 "Llave maestra":["llave.png","LLAVE","Acceso al expediente de Rectoría. Se utiliza automáticamente al interactuar."],
 "Llave de servicio":["llave.png","LLAVE","Abre el archivo detrás del mostrador. Se conserva para la misión."],
 "Extintor":["extintor.png","EMERGENCIA","Una descarga frena al Archivero cercano durante 3 segundos. No atraviesa paredes. Un solo uso; el ruido puede atraerlo después."],
 "Grapadora":["grapadora.png","DISTRACCIÓN","Lánzala hacia donde apuntas. El golpe atrae al Archivero. Q / RB fuera del inventario."],
 "Termo de cafe":["termo.png","RECUPERACIÓN","Bebe para recuperar 15 puntos de cordura. Se consume; no hace falta usarlo inmediatamente."],
 "Expediente de Lalo":["expediente.png","EVIDENCIA","Tu firma aparece en una baja que no solicitaste. Recuperar tu nombre es el comienzo, no el final."],
 "Sello roto":["sello_roto.png","EVIDENCIA","Puede revertir las bajas. Conserva el archivo enterrado y al menos 50 de cordura para ofrecer otra salida a los Ecos."],
 "Gafete de prefectura":["gafete.png","UN SOLO USO","Un cargo sigue impreso aunque su dueña ya no recuerde su nombre. Muéstralo y el Archivero te tratará como personal durante 12 segundos: no te escuchará ni te archivará."],
 "Memoria USB":["usb.png","EVIDENCIA","Registros rescatados de las computadoras. Una copia es más difícil de borrar que una persona."],
 "Acta sellada":["expediente.png","EVIDENCIA","Nadie dejó una hora de salida. Guarda este documento."],
 "Radio":["campus/radio.svg","EQUIPO","La voz de Don Chuy es tu vínculo con la caseta. Los mensajes importantes aparecen como testimonios."],
 "Pala":["campus/pala_usuario.png","HERRAMIENTA","Úsala en la tierra removida del patio. Excavar tarda tres segundos y hace ruido."],
 "Archivo 001":["expediente.png","EVIDENCIA","Desenterrado junto a la USB. La primera baja no tiene firma: el archivo aprendió a archivar solo y se volvió el Archivero. Al reverso, a lápiz: «El sello que lo rompe sigue en Rectoría, junto a tu expediente»."],
 "Reporte de cierre":["expediente.png","MISIÓN","Llévalo a Don Chuy en vigilancia. Todavía puedes decidir qué ocurrirá con los demás."],
 "Memoria de la banca":["papeles.png","EVIDENCIA","La Prefecta firmaba las bajas. Este fragmento le permite recordar a quiénes pertenecían."],
 "Memoria: maqueta":["maqueta.png","EVIDENCIA","Un campus vacío en miniatura. Las aulas siguen ahí; faltan sus nombres."]
}
func datos(item: String) -> Array:
	if Productos.PRODUCTOS.has(item):
		var p: Array = Productos.PRODUCTOS[item]
		return [p[0], "CONSUMIBLE · $1" if tienda else "CONSUMIBLE", p[4]]
	return CATALOGO.get(item,["expediente.png","OBJETO","Objeto recuperado durante el turno. Se conserva en la mochila."])
func estilo(color: Color, borde: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=borde
	s.set_border_width_all(1);s.set_corner_radius_all(7);s.content_margin_left=14;s.content_margin_right=14
	return s
func label(texto: String, p: Vector2, tam: int, ancho: float=0) -> Label:
	var l:=Label.new();l.text=texto;l.position=p;l.size.x=ancho
	l.add_theme_font_size_override("font_size",tam)
	if tam>=24:l.add_theme_font_override("font",preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"))
	raiz.add_child(l);return l
func boton(texto: String, p: Vector2, tam: Vector2, accion: Callable) -> Button:
	var b:=Button.new();b.text=texto;b.position=p;b.size=tam
	b.pressed.connect(accion);raiz.add_child(b);return b
func _ready() -> void:
	layer=25
	raiz=Control.new();raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tema:=Theme.new();tema.default_font=preload("res://assets/fuentes/Barlow-Regular.ttf");tema.default_font_size=18
	tema.set_stylebox("normal","Button",estilo(Color("18262f"),Color("3b5358")))
	tema.set_stylebox("hover","Button",estilo(Color("273c42"),Color("b2cbc0")))
	tema.set_stylebox("focus","Button",estilo(Color(0,0,0,0),Color("d5b478")))
	tema.set_stylebox("pressed","Button",estilo(Color("314a4e"),Color("d5b478")))
	raiz.theme=tema;add_child(raiz)
	var velo:=ColorRect.new();velo.color=Color(.025,.04,.055,.94);velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);raiz.add_child(velo)
	label("EL DE TALLERES / MOSTRADOR" if tienda else "ARCHIVO PERSONAL / LALO",Vector2(60,34),16).modulate=Color("d5b478")
	label("CAFETERÍA" if tienda else "MOCHILA",Vector2(60,58),42)
	saldo = label("",Vector2(60,108),18)
	saldo.modulate=Color("9bb2b5")
	var panel:=Panel.new();panel.position=Vector2(850,155);panel.size=Vector2(370,465)
	panel.add_theme_stylebox_override("panel",estilo(Color("101a24"),Color("3b5358")));raiz.add_child(panel)
	rejilla=GridContainer.new();rejilla.columns=4;rejilla.position=Vector2(60,165)
	rejilla.add_theme_constant_override("h_separation",12);rejilla.add_theme_constant_override("v_separation",12);raiz.add_child(rejilla)
	imagen=TextureRect.new();imagen.position=Vector2(945,176);imagen.size=Vector2(180,140)
	imagen.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;imagen.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;raiz.add_child(imagen)
	nombre=label("",Vector2(875,334),27,320);nombre.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detalle=label("",Vector2(875,398),17,320);detalle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	usar=boton("Inspeccionar",Vector2(875,552),Vector2(320,45),utilizar)
	boton("‹ Anterior",Vector2(60,635),Vector2(145,42),func(): cambiar(-1))
	pagina_texto=label("",Vector2(235,644),18)
	boton("Siguiente ›",Vector2(385,635),Vector2(145,42),func(): cambiar(1))
	if not tienda:
		boton("Testimonios",Vector2(548,635),Vector2(148,42),diario)
		boton("Misiones",Vector2(704,635),Vector2(140,42),misiones)
		descartar = boton("Descartar unidad",Vector2(875,602),Vector2(320,30),descartar_unidad)
	boton("Cerrar · Y / I / B",Vector2(875,635),Vector2(320,42),escuela.continuar)
	label("Cruceta / stick: elegir · A / Enter: seleccionar · Confirma con el botón de compra" if tienda else "Cruceta / stick: elegir · A / Enter: examinar · Los objetos de misión se conservan",Vector2(60,690),15).modulate=Color("9bb2b5")
	actualizar()
	raiz.modulate.a=0;create_tween().tween_property(raiz,"modulate:a",1,.18)
	# Entrada: la rejilla se desliza y la imagen del objeto flota suavemente.
	rejilla.position.x=30;create_tween().tween_property(rejilla,"position:x",60.0,.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var flotar:=create_tween().set_loops()
	flotar.tween_property(imagen,"position:y",170.0,1.4).set_trans(Tween.TRANS_SINE)
	flotar.tween_property(imagen,"position:y",182.0,1.4).set_trans(Tween.TRANS_SINE)
func actualizar() -> void:
	seleccion = ""
	saldo.text = "Saldo: $%d  ·  Todo a $1  ·  Mochila: máximo 6 suministros" % escuela.campana.monedas if tienda else "Suministros %d/6 · Cada unidad ocupa un espacio · Evidencias en carpeta separada" % Mochila.usados(escuela.jugador.inventario)
	cantidades.clear();objetos.clear()
	var lista: Array[String]=escuela.jugador.inventario.duplicate()
	lista.append("Linterna")
	for par in [["radio","Radio"],["pala","Pala"],["llave_servicio","Llave de servicio"],["reporte","Reporte de cierre"]]:
		if escuela.campana.hechos.get(par[0],false):lista.append(par[1])
	if tienda: lista.assign(Productos.PRODUCTOS.keys())
	for item in lista:
		if not cantidades.has(item):objetos.append(item);cantidades[item]=0
		cantidades[item]+=1
	pagina=clampi(pagina,0,maxi(0,ceili(objetos.size()/12.0)-1))
	for n in rejilla.get_children():rejilla.remove_child(n);n.queue_free()
	pagina_texto.text="%d / %d  ·  %d objetos"%[pagina+1,maxi(1,ceili(objetos.size()/12.0)),lista.size()]
	for indice in range(pagina*12,mini(objetos.size(),pagina*12+12)):
		var item: String=objetos[indice]
		var b:=Button.new();b.custom_minimum_size=Vector2(180,140);b.clip_contents=true
		rejilla.add_child(b)
		var icono:=TextureRect.new();icono.position=Vector2(46,10)
		icono.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icono.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icono.texture=load("res://assets/sprites/"+datos(item)[0]);icono.size=Vector2(88,80);icono.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(icono);icono.set_deferred("size",Vector2(88,80))
		var titulo:=Label.new();titulo.text=item+(" · $1" if tienda else (" ×%d"%cantidades[item] if cantidades[item]>1 else ""))
		titulo.position=Vector2(8,94);titulo.size=Vector2(164,40);titulo.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;titulo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;titulo.add_theme_font_size_override("font_size",16);b.add_child(titulo)
		b.focus_entered.connect(func(): seleccionar(item));b.mouse_entered.connect(func(): seleccionar(item));b.pressed.connect(func(): seleccionar(item);usar.grab_focus())
		# Franja de categoría y realce animado del icono (se añaden después: el icono sigue siendo el hijo 0).
		var franja:=ColorRect.new();franja.color=color_categoria(datos(item)[1]);franja.size=Vector2(180,4);franja.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(franja)
		icono.pivot_offset=Vector2(44,40)
		b.focus_entered.connect(func(): resaltar(icono,true));b.focus_exited.connect(func(): resaltar(icono,false))
		b.mouse_entered.connect(func(): resaltar(icono,true));b.mouse_exited.connect(func(): resaltar(icono,false))
	if rejilla.get_child_count()>0:call_deferred("enfocar_seguro",rejilla.get_child(0));seleccionar(objetos[pagina*12])
func color_categoria(categoria: String) -> Color:
	if categoria.begins_with("EVIDENCIA") or categoria.begins_with("MISIÓN"): return Color("d5b478")
	if categoria.begins_with("CONSUMIBLE") or categoria.begins_with("RECUPERACIÓN"): return Color("7fd6a8")
	if categoria.begins_with("LLAVE"): return Color("e8e2a0")
	if categoria.begins_with("EQUIPO") or categoria.begins_with("HERRAMIENTA"): return Color("6fb3e0")
	return Color("e37c6a")
func resaltar(icono: TextureRect, activo: bool) -> void:
	if not is_instance_valid(icono) or not icono.is_inside_tree(): return
	var t:=icono.create_tween()
	t.tween_property(icono,"scale",Vector2.ONE*(1.14 if activo else 1.0),.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func cerrar_misiones() -> void:
	if is_instance_valid(panel_misiones): panel_misiones.queue_free()
	panel_misiones=null
func misiones() -> void:
	if is_instance_valid(panel_misiones):
		cerrar_misiones()
		if rejilla.get_child_count()>0: rejilla.get_child(0).grab_focus()
		return
	panel_misiones=PanelContainer.new();panel_misiones.position=Vector2(60,150);panel_misiones.size=Vector2(770,470)
	panel_misiones.add_theme_stylebox_override("panel",estilo(Color("0d1820"),Color("d5b478")))
	var texto:=RichTextLabel.new();texto.bbcode_enabled=true;texto.scroll_active=true
	texto.custom_minimum_size=Vector2(740,440);texto.add_theme_font_size_override("normal_font_size",16)
	var bb:=""
	for nivel in escuela.campana.lista_misiones():
		var tareas: Array=nivel[1]
		var hechas:=0
		for tarea in tareas:
			if tarea[1]: hechas+=1
		bb+="[color=#d5b478]%s   %d / %d[/color]\n"%[nivel[0],hechas,tareas.size()]
		for tarea in tareas:
			bb+=("[color=#7fd6a8]   [lb]X[rb]  %s[/color]\n" if tarea[1] else "[color=#c9d6d4]   [lb]  [rb]  %s[/color]\n")%tarea[0]
		bb+="\n"
	texto.text=bb
	panel_misiones.add_child(texto);raiz.add_child(panel_misiones)
	panel_misiones.modulate.a=0;create_tween().tween_property(panel_misiones,"modulate:a",1.0,.2)
	nombre.text="MISIONES";imagen.texture=preload("res://assets/sprites/expediente.png")
	detalle.text="Objetivo actual:\n"+escuela.campana.objetivo();seleccion=""
	usar.text="Volver a objetos";usar.grab_focus()
func seleccionar(item: String) -> void:
	cerrar_misiones()
	if is_instance_valid(descartar): descartar.disabled = not Mochila.ocupa(item)
	if seleccion==item:return
	if animacion_detalle:animacion_detalle.kill()
	imagen.modulate.a=.5
	animacion_detalle=create_tween()
	animacion_detalle.tween_property(imagen,"modulate:a",1,.15)
	seleccion=item;nombre.text=item;imagen.texture=load("res://assets/sprites/"+datos(item)[0]);detalle.text=datos(item)[1]+"\n\n"+datos(item)[2]
	usar.text="Beber · +15 cordura" if item=="Termo de cafe" else ("Descargar extintor" if item=="Extintor" else ("Mostrar gafete · 12 s sin ser archivado" if item=="Gafete de prefectura" else ("Lanzar distracción" if item=="Grapadora" else "Conservar · volver a objetos")))
	if Productos.PRODUCTOS.has(item):
		usar.text = ("Comprar · $1" if escuela.campana.monedas > 0 else "Sin monedas · necesitas $1") if tienda else "Consumir una unidad"
func cambiar(direccion: int) -> void:
	pagina=clampi(pagina+direccion,0,maxi(0,ceili(objetos.size()/12.0)-1));actualizar()
func utilizar() -> void:
	var j: CharacterBody2D=escuela.jugador
	if tienda:
		if not Productos.PRODUCTOS.has(seleccion): return
		if escuela.campana.monedas < 1:
			detalle.text = "No tienes monedas. Busca en bancos, escritorios y patio."
			return
		if not Mochila.cabe(j.inventario,seleccion):
			detalle.text = "Mochila llena (6/6). Cierra la tienda y consume o descarta un suministro con I / Y."
			return
		escuela.campana.monedas -= 1
		j.inventario.append(seleccion)
		escuela.sonidos.efecto("recoger", Vector2.INF, -20)
		saldo.text = "Saldo: $%d  ·  Todo a $1  ·  Mochila: máximo 6 suministros" % escuela.campana.monedas
		detalle.text = "Compraste %s por $1.\n\nEn tu mochila: %d\n\nÁbrela con I / Y para consumirlo." % [seleccion, j.inventario.count(seleccion)]
		usar.text = "Comprar otro · $1" if escuela.campana.monedas > 0 else "Sin monedas · necesitas $1"
		return
	if Productos.PRODUCTOS.has(seleccion):
		if Productos.consumir(escuela, seleccion):
			seleccion = ""
			actualizar()
		else: detalle.text = "Tus medidores ya están llenos. Conserva el producto para más tarde."
		return
	if seleccion=="Termo de cafe" and j.inventario.has(seleccion):
		if j.cordura>=100:detalle.text="No necesitas beber ahora. Conserva el termo para más tarde.";return
		j.inventario.erase(seleccion);j.cordura=minf(100,j.cordura+15);escuela.sonidos.efecto("recoger",Vector2.INF,-20);actualizar()
	elif seleccion=="Grapadora" and j.inventario.has(seleccion):
		escuela.continuar();j.distraer()
	elif seleccion=="Gafete de prefectura" and j.inventario.has(seleccion):
		# Plan de trabajo: gafete de un solo uso.
		j.inventario.erase(seleccion);escuela.continuar()
		escuela.archivero.ignorar=12.0
		escuela.sonidos.efecto("sello",j.position,-12)
		j.mensaje="Gafete visible: durante 12 s el Archivero te trata como personal. Aprovecha."
	elif seleccion=="Extintor" and j.inventario.has(seleccion):
		j.inventario.erase(seleccion);escuela.continuar()
		var a: CharacterBody2D=escuela.archivero
		var rayo:=PhysicsRayQueryParameters2D.create(j.position,a.position,1,[j.get_rid(),a.get_rid()])
		if a.activo and j.position.distance_to(a.position)<210 and escuela.get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():a.repelido=3
		escuela.sonidos.efecto("radio_estatica",j.position,-10);escuela.emitir_ruido(j.position,.8)
		j.mensaje="Extintor descargado. Aprovecha para alejarte."
	else:
		if rejilla.get_child_count()>0:rejilla.get_child(0).grab_focus()
func diario() -> void:
	cerrar_misiones()
	nombre.text="TESTIMONIOS";imagen.texture=preload("res://assets/sprites/expediente.png")
	var texto: String="Tu expediente fue cerrado sin tu firma. Busca a quienes todavía recuerdan su nombre."
	if escuela.campana.hechos.get("computo",false):texto="La de Cómputo quedó encerrada. Su memoria USB está enterrada en el patio."
	if escuela.campana.hechos.get("archivo_enterrado",false):texto+="\n\nLa memoria USB contiene una grabación de la noche en que desaparecieron."
	if escuela.campana.hechos.get("reporte",false):texto="El reporte prueba que el campus no está vacío. Don Chuy puede abrir la salida; el Sello Roto puede liberar a los demás."
	var recuerdos: Array[String]=[]
	for i in range(4):
		if escuela.campana.hechos.get("testimonio_%d"%(i+1),false):recuerdos.append(preload("res://src/story/ecos_memoria.gd").RELATOS[i])
	# Los documentos leídos se guardan en el mismo diario.
	for doc in preload("res://src/story/documentos.gd").DOCUMENTOS:
		if escuela.campana.hechos.get("documento_%d"%doc[0],false):recuerdos.append(str(doc[2])+" · "+str(doc[3]).replace("\n"," "))
	if not recuerdos.is_empty():
		diario_indice=(diario_indice+1)%recuerdos.size()
		texto=recuerdos[diario_indice]+"\n\n%d / %d · pulsa Testimonios para el siguiente"%[diario_indice+1,recuerdos.size()]
	detalle.text=texto;seleccion="";usar.text="Volver a objetos";usar.grab_focus()

func enfocar_seguro(b: Control) -> void:
	if is_instance_valid(b) and b.is_inside_tree() and not b.is_queued_for_deletion():b.grab_focus()

func descartar_unidad() -> void:
	if tienda or not Mochila.ocupa(seleccion): return
	escuela.jugador.inventario.erase(seleccion)
	actualizar()
