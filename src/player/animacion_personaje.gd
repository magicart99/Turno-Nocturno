extends RefCounted
## Usa los PNG originales; cada dirección tiene sus propios cuatro cuadros.
static func crear(personaje: String) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.set_meta("personaje", personaje)
	# Ventanas del atlas: quitan restos de cuadros vecinos sin alterar los PNG UT.
	var regiones := {
		"down": [Rect2(106,38,139,262), Rect2(97,40,143,260), Rect2(90,41,138,259), Rect2(86,41,140,259)],
		"left": [Rect2(112,24,139,259), Rect2(102,25,135,259), Rect2(95,24,134,259), Rect2(95,25,139,258)],
		"right": [Rect2(96,13,146,255), Rect2(90,13,143,255), Rect2(86,14,143,254), Rect2(86,13,147,255)],
		"up": [Rect2(103,0,135,260), Rect2(98,0,134,260), Rect2(88,0,137,260), Rect2(87,0,136,260)]}
	var cuadros := SpriteFrames.new()
	cuadros.remove_animation("default")
	for direccion in ["down", "left", "right", "up"]:
		cuadros.add_animation(direccion)
		cuadros.set_animation_speed(direccion, 7.0)
		for i in range(1, 5):
			var archivo: String = ("walk_%s_%02d.png" % [direccion, i]) if personaje == "archivero" else ("%s_%d.png" % [direccion, i])
			var textura: Texture2D = load("res://assets/sprites/%s/%s" % [personaje, archivo])
			if personaje == "lalo":
				var atlas := AtlasTexture.new()
				atlas.atlas = textura
				atlas.region = regiones[direccion][i - 1]
				var margen := Vector2(160, 270) - atlas.region.size
				atlas.margin = Rect2(Vector2(margen.x / 2.0, margen.y), margen)
				textura = atlas
			cuadros.add_frame(direccion, textura)
	sprite.sprite_frames = cuadros
	if personaje == "lalo": agregar_acciones(cuadros)
	sprite.animation = "down"
	sprite.scale = Vector2.ONE * (0.35 if personaje == "archivero" else 0.26)
	sprite.offset = Vector2(10, -140) if personaje == "archivero" else Vector2(0, -135)
	return sprite

static func agregar_acciones(cuadros: SpriteFrames) -> void:
	var hoja: Texture2D = load("res://assets/sprites/lalo/acciones_sigilo.png")
	# Regiones de atlas, con margen uniforme y pies alineados. No modifica los PNG.
	var regiones := {
		"crouch_down": [Rect2(82,72,192,235),Rect2(388,72,192,231),Rect2(683,72,192,234),Rect2(976,72,194,229)],
		"crouch_right": [Rect2(68,348,226,250),Rect2(370,345,232,252),Rect2(668,346,224,256),Rect2(986,344,226,250)],
		"crouch_up": [Rect2(82,663,188,243),Rect2(385,663,188,243),Rect2(674,660,188,247),Rect2(993,650,182,254)],
		"crawl": [Rect2(38,1018,288,177),Rect2(347,1018,279,177)],
		"dig": [Rect2(645,912,252,295),Rect2(950,964,289,243)]}
	for nombre in regiones:
		cuadros.add_animation(nombre)
		cuadros.set_animation_speed(nombre,5)
		for region in regiones[nombre]:
			var atlas := AtlasTexture.new()
			atlas.atlas = hoja
			atlas.region = region
			var margen: Vector2 = Vector2(320,320) - region.size
			atlas.margin = Rect2(Vector2(margen.x/2,margen.y),margen)
			cuadros.add_frame(nombre,atlas)
	var catalogo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/lalo/atlas_acciones.json"))
	catalogo.erase("caminar_linterna.png")
	catalogo.merge(JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/lalo/atlas_marcha_v10.json")))
	for archivo in catalogo:
		var textura: Texture2D = load("res://assets/sprites/lalo/" + archivo)
		for nombre in catalogo[archivo]:
			cuadros.add_animation(nombre)
			cuadros.set_animation_speed(nombre, 7 if nombre.begins_with("torch") else 5)
			for dato in catalogo[archivo][nombre]:
				var r: Array = dato.region
				var atlas := AtlasTexture.new()
				atlas.atlas = textura
				atlas.region = Rect2(r[0],r[1],r[2],r[3])
				var margen := Vector2(320,320) - atlas.region.size
				atlas.margin = Rect2(Vector2(dato.izquierda,margen.y),margen)
				cuadros.add_frame(nombre,atlas)

static func mover(sprite: AnimatedSprite2D, movimiento: Vector2, corriendo: bool = false) -> void:
	if movimiento.length() < 3.0:
		sprite.pause()
		sprite.frame = 0
		return
	var direccion := "right" if movimiento.x > 0 else "left"
	if abs(movimiento.y) > abs(movimiento.x):
		direccion = "down" if movimiento.y > 0 else "up"
	sprite.speed_scale = 1.5 if corriendo else 1.0
	if sprite.get_meta("personaje") == "archivero":
		var pies := {"down": Vector2(150,300), "left": Vector2(176,302), "right": Vector2(155,284), "up": Vector2(155,302)}
		sprite.offset = Vector2(160,160) - pies[direccion]
	sprite.play(direccion)
