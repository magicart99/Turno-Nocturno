extends StaticBody2D
## Interacción de campaña; cada punto tiene un identificador estable para el guardado.
@export var clave: String = ""
@export var titulo: String = ""
@export var tipo: String = "campana"
@export var consumible: bool = false
var abierto: bool = false
var retrato: Sprite2D
var base_retrato := Vector2.ZERO

func _ready() -> void:
	# Cada Eco conserva su arte propio, incluso si se regenera el campus.
	var retratos := {"prefecta": "eco_prefecta.png", "talleres": "eco_taller.png"}
	if retratos.has(clave):
		for hijo in get_children():
			if hijo is Sprite2D:
				hijo.texture = load("res://assets/sprites/" + retratos[clave])
				hijo.scale = Vector2.ONE * (75.0 / hijo.texture.get_height())
				hijo.offset = Vector2(0, -hijo.texture.get_height() * 0.5)
				var material_eco := CanvasItemMaterial.new()
				material_eco.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
				hijo.material = material_eco
				hijo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				retrato = hijo
				base_retrato = hijo.position
		if has_node("Indicador"): get_node("Indicador").position.y = -105
	if clave == "computo" and has_node("Sprite3"):
		add_child(preload("res://src/story/la_de_computo.gd").new())
	if clave == "tienda":
		for hijo in get_children():
			if hijo is Sprite2D:
				hijo.texture = preload("res://assets/sprites/cafeteria/pixel/estante.png")
				hijo.scale = Vector2.ONE
		var contacto := preload("res://src/world/contacto_productos.gd").new()
		contacto.position.y = 25
		add_child(contacto)
	if clave == "archivo_enterrado":
		for hijo in get_children():
			if hijo is CanvasItem: hijo.hide()
		add_child(preload("res://src/story/memoria_enterrada.gd").new())
	add_to_group("interactivos")
	add_to_group("puntos_campana")

func interactuar(_jugador: CharacterBody2D) -> String:
	var escuela := get_tree().get_first_node_in_group("control")
	return escuela.campana.interactuar(clave, self)

func _process(_delta: float) -> void:
	var escuela := get_tree().get_first_node_in_group("control")
	if escuela == null or escuela.campana == null:
		return
	if consumible and escuela.campana.hechos.get(clave, false):
		hide()
		collision_layer = 0
		return

	var brillo := get_node_or_null("Indicador") as CanvasItem
	if brillo:
		brillo.modulate.a = 0.65 + 0.3 * sin(escuela.tiempo * 2.5)
	# Los Ecos flotan y, de vez en cuando, su imagen se corta como una señal débil.
	if is_instance_valid(retrato):
		var t: float = escuela.tiempo + position.x * 0.01
		retrato.position = base_retrato + Vector2(sin(t * 0.7) * 1.5, sin(t * 1.4) * 4.0)
		retrato.modulate.a = 0.84 + 0.1 * sin(t * 3.1) - (0.45 if sin(t * 13.0) * sin(t * 2.3) > 0.9 else 0.0)
