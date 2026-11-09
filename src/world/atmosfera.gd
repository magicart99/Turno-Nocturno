extends Node2D
## Capa visual sin colisiones ni efecto en la partida:
## polvo en el haz de la linterna, sombras de contacto, aura y rastro del Archivero,
## polvo de pisadas y mensajes en el suelo que solo revela la luz.
const MENSAJES_PRINCIPAL := [
	[Vector2(430, 640), "FIRMA AQUÍ"],
	[Vector2(760, 700), "NO CORRAS"],
	[Vector2(1560, 640), "¿PRESENTE?"],
	[Vector2(2330, 700), "BAJA POR ABANDONO"],
	[Vector2(2960, 640), "ÉL ESCUCHA"],
]
const MENSAJES_CAMPUS := [
	[Vector2(1200, 2140), "NADIE CERRÓ SU TURNO"],
	[Vector2(1050, 1725), "CUENTA TUS PASOS"],
	[Vector2(1510, 1420), "SIGUE LA LISTA"],
	[Vector2(1300, 2355), "NO MIRES ATRÁS"],
]
var escuela: Node2D
var polvo: CPUParticles2D
var papeles: CPUParticles2D
var luz_archivero: PointLight2D
var sombra_jugador: Sprite2D
var material_espectro: CanvasItemMaterial
var reloj_rastro: float = 0.0
var haz: Polygon2D
const RAYOS_HAZ := 11
const LARGO_HAZ := 300.0
const APERTURA_HAZ := 0.38
var pisadas: Array[Dictionary] = []
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")

func _ready() -> void:
	escuela = get_parent()
	z_index = 1
	material_espectro = CanvasItemMaterial.new()
	material_espectro.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var jugador: CharacterBody2D = escuela.jugador
	var archivero: CharacterBody2D = escuela.archivero
	sombra_jugador = crear_sombra(Vector2(0.62, 0.2))
	jugador.add_child(sombra_jugador)
	jugador.move_child(sombra_jugador, 0)
	var sombra_archivero := crear_sombra(Vector2(0.85, 0.26))
	archivero.add_child(sombra_archivero)
	archivero.move_child(sombra_archivero, 0)
	# Polvo suspendido: solo se ve donde lo toca el haz, porque el resto está a oscuras.
	polvo = CPUParticles2D.new()
	polvo.amount = 48
	polvo.lifetime = 5.0
	polvo.preprocess = 5.0
	polvo.local_coords = false
	polvo.position = Vector2(150, 0)
	polvo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	polvo.emission_rect_extents = Vector2(150, 70)
	polvo.direction = Vector2(0, -1)
	polvo.spread = 180.0
	polvo.gravity = Vector2(0, -3)
	polvo.initial_velocity_min = 2.0
	polvo.initial_velocity_max = 9.0
	polvo.scale_amount_min = 1.0
	polvo.scale_amount_max = 2.4
	polvo.color_ramp = rampa(Color(1, 0.96, 0.86), 0.55)
	jugador.get_node("Linterna").add_child(polvo)
	# Hojas de expediente que se desprenden del Archivero.
	papeles = CPUParticles2D.new()
	papeles.amount = 14
	papeles.lifetime = 1.8
	papeles.local_coords = false
	papeles.position = Vector2(0, -58)
	papeles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	papeles.emission_sphere_radius = 20.0
	papeles.direction = Vector2(0, 1)
	papeles.spread = 160.0
	papeles.gravity = Vector2(0, 38)
	papeles.initial_velocity_min = 8.0
	papeles.initial_velocity_max = 30.0
	papeles.angular_velocity_min = -220.0
	papeles.angular_velocity_max = 220.0
	papeles.angle_min = -180.0
	papeles.angle_max = 180.0
	papeles.scale_amount_min = 2.5
	papeles.scale_amount_max = 4.5
	papeles.color_ramp = rampa(Color(0.86, 0.82, 0.7), 0.8)
	papeles.emitting = false
	archivero.add_child(papeles)
	# Resplandor rojo cuando investiga: avisa del peligro sin revelar su forma.
	luz_archivero = PointLight2D.new()
	luz_archivero.texture = textura_radial(Color(1, 1, 1, 1), 160)
	luz_archivero.color = Color(1.0, 0.16, 0.1)
	luz_archivero.energy = 0.0
	luz_archivero.texture_scale = 1.3
	luz_archivero.position = Vector2(0, -20)
	luz_archivero.shadow_enabled = true
	archivero.add_child(luz_archivero)
	# La linterna y la luz cercana leen también las sombras de los muebles (máscara 2).
	var linterna: PointLight2D = jugador.get_node("Linterna")
	linterna.shadow_item_cull_mask = 1 | 2
	if jugador.luz_personal: jugador.luz_personal.shadow_item_cull_mask = 1 | 2
	crear_haz()

func crear_haz() -> void:
	# Haz volumétrico: polígono aditivo recortado por rayos, con polvo animado en el shader.
	haz = Polygon2D.new()
	haz.z_as_relative = false
	haz.z_index = 4
	var sombreado := Shader.new()
	sombreado.code = """shader_type canvas_item;
render_mode blend_add, unshaded;
uniform vec2 origen;
uniform float largo = 300.0;
uniform float intensidad = 0.11;
varying vec2 mundo;
void vertex(){ mundo = VERTEX; }
float azar(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment(){
	float d = clamp(length(mundo - origen) / largo, 0.0, 1.0);
	float n = ruido(mundo * 0.025 + vec2(TIME * 0.15, TIME * 0.05));
	float a = pow(1.0 - d, 1.6) * intensidad * (0.6 + 0.8 * n) * COLOR.a;
	COLOR = vec4(vec3(1.0, 0.93, 0.75) * a, 1.0);
}"""
	var material_haz := ShaderMaterial.new()
	material_haz.shader = sombreado
	haz.material = material_haz
	add_child(haz)

func actualizar_haz() -> void:
	var jugador: CharacterBody2D = escuela.jugador
	var linterna: PointLight2D = jugador.get_node("Linterna")
	haz.visible = linterna.enabled and linterna.is_visible_in_tree()
	if not haz.visible:
		return
	var origen: Vector2 = linterna.global_position
	var espacio := get_world_2d().direct_space_state
	var puntos := PackedVector2Array([origen])
	var colores := PackedColorArray([Color(1, 1, 1, 1)])
	var mitad: float = (RAYOS_HAZ - 1) / 2.0
	for k in range(RAYOS_HAZ):
		var giro: float = (k - mitad) / mitad
		var destino: Vector2 = origen + Vector2.from_angle(jugador.apuntado.angle() + giro * APERTURA_HAZ) * LARGO_HAZ
		var consulta := PhysicsRayQueryParameters2D.create(origen, destino, 1, [jugador.get_rid()])
		var choque := espacio.intersect_ray(consulta)
		var fin: Vector2 = choque.position if not choque.is_empty() else destino
		# Distancia mínima: pegado a una pared el polígono no se degenera (evita errores de triangulación).
		if origen.distance_to(fin) < 10.0:
			fin = origen + origen.direction_to(destino) * 10.0
		puntos.append(fin)
		colores.append(Color(1, 1, 1, 1.0 - giro * giro))
	haz.polygon = puntos
	haz.vertex_colors = colores
	haz.material.set_shader_parameter("origen", origen)
	haz.material.set_shader_parameter("intensidad", 0.11 * clampf(linterna.energy / 1.12, 0.0, 1.2))

func rampa(color: Color, alfa: float) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(color, 0.0), Color(color, alfa), Color(color, alfa), Color(color, 0.0)])
	return g

static func textura_radial(color: Color, tamano: int) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([color, Color(color, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = tamano
	t.height = tamano
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func crear_sombra(escala: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura_radial(Color(0, 0, 0, 0.6), 64)
	s.scale = escala
	s.position = Vector2(0, 1)
	return s

func pisada(posicion: Vector2, fuerte: bool) -> void:
	if pisadas.size() > 24:
		pisadas.remove_at(0)
	pisadas.append({"p": posicion + Vector2(randf_range(-4, 4), 2), "t": 0.0, "f": 1.6 if fuerte else 1.0})

func _process(delta: float) -> void:
	var jugador: CharacterBody2D = escuela.jugador
	var archivero: CharacterBody2D = escuela.archivero
	sombra_jugador.visible = not jugador.oculto
	polvo.emitting = jugador.linterna and not jugador.oculto
	var activo: bool = archivero.activo and archivero.visible
	papeles.emitting = activo and escuela.jugando
	var objetivo_luz: float = 0.0
	if activo:
		# Solo brilla al investigar: en patrulla se le encuentra por el oído.
		objetivo_luz = 0.85 if archivero.estado == "INVESTIGANDO" else 0.0
		objetivo_luz *= 0.75 + 0.25 * sin(escuela.tiempo * 11.0)
	luz_archivero.energy = move_toward(luz_archivero.energy, objetivo_luz, delta * 2.5)
	actualizar_haz()
	if escuela.jugando:
		var vivas: Array[Dictionary] = []
		for p in pisadas:
			p["t"] = float(p["t"]) + delta
			if float(p["t"]) < 0.7:
				vivas.append(p)
		pisadas = vivas
		reloj_rastro -= delta
		if activo and archivero.estado == "INVESTIGANDO" and archivero.velocity.length() > 20.0 and reloj_rastro <= 0.0:
			reloj_rastro = 0.09
			dejar_rastro(archivero)
	queue_redraw()

func dejar_rastro(archivero: CharacterBody2D) -> void:
	# Copias que se desvanecen: el Archivero deja una estela al perseguir un ruido.
	var origen: AnimatedSprite2D = archivero.sprite
	if origen.sprite_frames == null or not origen.sprite_frames.has_animation(origen.animation):
		return
	var textura := origen.sprite_frames.get_frame_texture(origen.animation, origen.frame)
	if textura == null:
		return
	var copia := Sprite2D.new()
	copia.texture = textura
	copia.centered = origen.centered
	copia.offset = origen.offset
	copia.flip_h = origen.flip_h
	copia.z_as_relative = false
	copia.z_index = 4
	copia.modulate = Color(0.6, 0.05, 0.08, 0.24)
	copia.material = material_espectro
	copia.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(copia)
	copia.global_position = origen.global_position
	copia.global_scale = origen.global_scale
	var t := copia.create_tween()
	t.tween_property(copia, "modulate:a", 0.0, 0.45)
	t.tween_callback(copia.queue_free)

func _draw() -> void:
	if escuela.campana == null:
		return
	# Nubes de polvo de cada pisada; solo se ven con luz.
	for p in pisadas:
		var t: float = float(p["t"]) / 0.7
		var fuerza: float = float(p["f"])
		draw_set_transform(p["p"], 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, (5.0 + t * 12.0) * fuerza, Color(0.62, 0.6, 0.55, (1.0 - t) * 0.22))
	draw_set_transform(Vector2.ZERO)
	# Mensajes escritos en el piso. Aparecen con más fuerza al perder la cordura.
	var cordura: float = escuela.jugador.cordura
	var alfa: float = clampf(0.3 + (100.0 - cordura) / 90.0, 0.3, 0.85)
	var mensajes: Array = MENSAJES_CAMPUS if escuela.campana.lugar == "campus" else MENSAJES_PRINCIPAL
	var cerca: Vector2 = escuela.jugador.position
	for m in mensajes:
		var posicion: Vector2 = m[0]
		if posicion.distance_to(cerca) > 900.0:
			continue
		var temblor := Vector2(sin(escuela.tiempo * 17.0 + posicion.x), 0) * (1.0 if cordura < 40.0 else 0.0)
		draw_string(fuente, posicion + temblor - Vector2(90, 0), m[1], HORIZONTAL_ALIGNMENT_CENTER, 180, 24, Color(0.5, 0.07, 0.05, alfa))
