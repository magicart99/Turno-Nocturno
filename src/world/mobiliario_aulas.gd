extends Node
## Renovación del interior al cargar el edificio, sin editar escuela.tscn:
## pupitres negros de paleta, escritorio del maestro, pizarrón blanco, minisplit,
## puertas de vidrio y vitropiso crema en todos los pisos interiores.
const PUPITRE = preload("res://assets/sprites/aula/pupitre.png")
const ESCRITORIO = preload("res://assets/sprites/aula/escritorio_maestro.png")
const PIZARRON = preload("res://assets/sprites/aula/pizarron_blanco.png")
const MINISPLIT = preload("res://assets/sprites/aula/minisplit.png")
const PUERTA_CERRADA = preload("res://assets/sprites/aula/puerta_vidrio_cerrada.png")
const PUERTA_ABIERTA = preload("res://assets/sprites/aula/puerta_vidrio_abierta.png")
const PISO = preload("res://assets/tilesets/piso_vitropiso.png")
const PISO_BANO = preload("res://assets/tilesets/piso_vitropiso_bano.png")
## Salas que reciben minisplit; los baños conservan puertas sólidas.
const SALAS_CLIMA := ["Aula_", "Auditorio", "Computo", "Direccion"]
var escuela: Node2D
var climas: Array[Dictionary] = []
var tiempo: float = 0.0

func _ready() -> void:
	escuela = get_parent()
	renovar_pisos()
	renovar_objetos()
	instalar_climas()

func renovar_pisos() -> void:
	for piso in escuela.get_node("Pisos").get_children():
		if piso is Sprite2D and piso.region_enabled:
			piso.texture = PISO_BANO if str(piso.name).begins_with("Bano") else PISO
			piso.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func colocar(sprite: Sprite2D, textura: Texture2D, desplazamiento: Vector2) -> void:
	sprite.texture = textura
	sprite.scale = Vector2.ONE
	sprite.offset = desplazamiento
	sprite.region_enabled = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func renovar_objetos() -> void:
	for objeto in escuela.get_node("Objetos").get_children():
		var titulo := str(objeto.get("titulo"))
		var sprite := objeto.get_node_or_null("Sprite") as Sprite2D
		if sprite == null:
			continue
		if titulo == "Mesa escolar":
			# El pupitre ya incluye la paleta: la mesa separada desaparece y deja de estorbar.
			sprite.hide()
			var colision := objeto.get_node_or_null("Colision") as CollisionShape2D
			if colision: colision.disabled = true
		elif titulo == "Silla":
			colocar(sprite, PUPITRE, Vector2(0, -14))
			var colision := objeto.get_node_or_null("Colision") as CollisionShape2D
			if colision:
				var forma := RectangleShape2D.new()
				forma.size = Vector2(30, 14)
				colision.shape = forma
		elif titulo == "Escritorio: ocultarse" and sala_de(objeto.global_position).begins_with("Aula_"):
			colocar(sprite, ESCRITORIO, Vector2(0, -9))
		elif titulo == "Pizarron":
			colocar(sprite, PIZARRON, Vector2.ZERO)
		elif titulo.begins_with("Puerta: ") and not titulo.contains("Bano"):
			convertir_puerta(objeto, sprite)

func convertir_puerta(puerta: Node, sprite: Sprite2D) -> void:
	# Vidrio: la luz atraviesa la puerta, aunque siga bloqueando el paso cerrada.
	puerta.set("textura_cerrada", PUERTA_CERRADA)
	puerta.set("textura_abierta", PUERTA_ABIERTA)
	puerta.set("vidrio", true)
	puerta.set("escala_puerta", Vector2.ONE)
	colocar(sprite, PUERTA_ABIERTA if puerta.get("abierto") else PUERTA_CERRADA, Vector2.ZERO)
	var sombra: Variant = puerta.get("sombra")
	if sombra is LightOccluder2D:
		sombra.visible = false

func sala_de(posicion: Vector2) -> String:
	for piso in escuela.get_node("Pisos").get_children():
		if piso is Sprite2D and piso.region_enabled and not str(piso.name).begins_with("Pasillo"):
			if Rect2(piso.global_position, piso.region_rect.size * piso.scale).has_point(posicion):
				return str(piso.name)
	return ""

func instalar_climas() -> void:
	# Fuera de "Objetos": el guardado recorre ese nodo y espera objetos con tipo y título.
	# DetallesPrincipal también se oculta al salir al campus.
	var destino := escuela.get_node("DetallesPrincipal")
	for piso in escuela.get_node("Pisos").get_children():
		if not (piso is Sprite2D and piso.region_enabled):
			continue
		var nombre := str(piso.name)
		var aplica := false
		for prefijo in SALAS_CLIMA:
			if nombre.begins_with(prefijo): aplica = true
		if not aplica:
			continue
		var sala := Rect2(piso.global_position, piso.region_rect.size * piso.scale)
		var clima := Sprite2D.new()
		clima.name = "Minisplit_" + nombre
		clima.texture = MINISPLIT
		clima.position = Vector2(sala.position.x + sala.size.x * 0.78, sala.position.y + 22)
		destino.add_child(clima)
		# LED de estado: verde con corriente en la sala, rojo tenue sin ella.
		var led := ColorRect.new()
		led.size = Vector2(2, 2)
		led.position = Vector2(19, 1)
		var sin_luz := CanvasItemMaterial.new()
		sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		led.material = sin_luz
		led.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clima.add_child(led)
		# Aire frío: neblina muy tenue hacia abajo cuando la sala tiene corriente.
		var aire := CPUParticles2D.new()
		aire.amount = 6
		aire.lifetime = 2.2
		aire.position = Vector2(0, 9)
		aire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		aire.emission_rect_extents = Vector2(18, 1)
		aire.direction = Vector2(0, 1)
		aire.spread = 18.0
		aire.gravity = Vector2(0, 6)
		aire.initial_velocity_min = 6.0
		aire.initial_velocity_max = 12.0
		aire.scale_amount_min = 2.0
		aire.scale_amount_max = 4.0
		var gradiente := Gradient.new()
		gradiente.colors = PackedColorArray([Color(0.85, 0.95, 1.0, 0.16), Color(0.85, 0.95, 1.0, 0.0)])
		aire.color_ramp = gradiente
		aire.emitting = false
		clima.add_child(aire)
		climas.append({"zona": nombre, "led": led, "aire": aire})

func _process(delta: float) -> void:
	tiempo += delta
	for dato in climas:
		var encendido: bool = escuela.zonas.get(dato["zona"], false)
		var led: ColorRect = dato["led"]
		var aire: CPUParticles2D = dato["aire"]
		var parpadeo: bool = fmod(tiempo, 2.0) < 1.7
		led.color = Color(0.3, 1.0, 0.5) if encendido and parpadeo else (Color(0.5, 0.08, 0.06) if not encendido else Color(0.1, 0.35, 0.18))
		aire.emitting = encendido and escuela.campana.lugar == "principal"
