extends Node2D
## Documento ambiental: se lee con Interactuar y queda guardado en el diario de la mochila.
## Solo brilla con luz: hay que encontrarlo con la linterna.
var tipo := "documento"
var titulo := "Leer documento"
var numero := 0
var encabezado := ""
var texto := ""
var escuela: Node2D
var tiempo := 0.0

func _ready() -> void:
	escuela = get_tree().get_first_node_in_group("control")
	add_to_group("interactivos")
	var hoja := Sprite2D.new()
	hoja.texture = preload("res://assets/sprites/papeles.png")
	hoja.scale = Vector2.ONE * 0.11
	hoja.rotation = randf_range(-0.5, 0.5)
	hoja.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(hoja)

func marca() -> String:
	return "documento_%d" % numero

func interactuar(_jugador: CharacterBody2D) -> String:
	var nuevo: bool = not escuela.campana.hechos.get(marca(), false)
	escuela.campana.hechos[marca()] = true
	escuela.sonidos.efecto("papel", global_position, -14)
	# Con los diez documentos se revela el recuerdo completo (flashback) y una recompensa.
	var leidos := 0
	for i in range(10):
		if escuela.campana.hechos.get("documento_%d" % (i + 1), false): leidos += 1
	var revelar: bool = leidos >= 10 and not escuela.campana.hechos.get("flashback_documentos", false)
	if revelar: escuela.campana.hechos["flashback_documentos"] = true
	escuela.interfaz.elegir(encabezado, texto + "\n\nDocumentos encontrados: %d / 10" % leidos, ["Guardar en el diario"], func(_i: int):
		if revelar:
			escuela.recuerdo_pausado(preload("res://src/story/documentos.gd").FLASHBACK)
			if Controles.desbloquear(3):
				escuela.anunciar("RECOMPENSA DESBLOQUEADA", "Sudadera Gris ceniza · elígela en Controles y opciones.")
	)
	if nuevo and is_instance_valid(escuela.mente):
		escuela.mente.presenciar(3.0)
	return "Documento guardado en el diario (I / Y → Testimonios)." if nuevo else "Ya habías leído este documento."

func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()

func _draw() -> void:
	if escuela == null or escuela.campana.hechos.get(marca(), false):
		return
	# Destello tenue: solo se nota cuando la linterna lo ilumina.
	var alfa: float = 0.06 + 0.05 * sin(tiempo * 3.0)
	draw_circle(Vector2.ZERO, 16.0, Color(0.95, 0.85, 0.6, alfa))
