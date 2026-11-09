extends CharacterBody2D

signal ruido_emitido(posicion: Vector2, intensidad: float)
signal recogido(id: String)
@export var tipo: String = "decoracion"
@export var titulo: String = "Objeto"
@export var zona: String = ""
var abierto: bool = false
var ocupado: bool = false
var textura_cerrada: Texture2D
var textura_abierta: Texture2D = preload("res://assets/sprites/puerta_abierta.png")
## Las puertas de vidrio dejan pasar la luz: su oclusor permanece apagado.
var vidrio: bool = false
var sombra: LightOccluder2D
var escala_puerta: Vector2 = Vector2.ONE
var giro_puerta: Tween
var hoja_casillero: Sprite2D
var hueco_casillero: Polygon2D

func _ready() -> void:
	if tipo == "escondite" and "Casillero" in titulo:
		var escala: Vector2 = $Sprite.scale
		var origen := Vector2(-35,-69) * escala
		var tam := Vector2(66,173) * escala
		hueco_casillero = Polygon2D.new()
		hueco_casillero.polygon = PackedVector2Array([origen,origen+Vector2(tam.x,0),origen+tam,origen+Vector2(0,tam.y)])
		hueco_casillero.color = Color("090f15")
		hueco_casillero.z_index = 1
		add_child(hueco_casillero)
		var puerta := AtlasTexture.new()
		puerta.atlas = $Sprite.texture
		puerta.region = Rect2(24,59,66,173)
		hoja_casillero = Sprite2D.new()
		hoja_casillero.texture = puerta
		hoja_casillero.scale = escala
		hoja_casillero.position = origen + Vector2(tam.x,tam.y*.5)
		hoja_casillero.offset = Vector2(-33,0)
		hoja_casillero.z_index = 6
		add_child(hoja_casillero)
		animar_escondite(0)
	if tipo == "puerta":
		escala_puerta = $Sprite.scale
		textura_cerrada = $Sprite.texture
		sombra = LightOccluder2D.new()
		var poligono := OccluderPolygon2D.new()
		poligono.polygon = PackedVector2Array([Vector2(-48,-9), Vector2(48,-9), Vector2(48,9), Vector2(-48,9)])
		sombra.occluder = poligono
		add_child(sombra)
	if tipo != "decoracion":
		add_to_group("interactivos")

func animar_escondite(apertura: float) -> void:
	if not is_instance_valid(hoja_casillero): return
	hoja_casillero.visible = apertura > 0.001
	hueco_casillero.visible = apertura > 0.001
	hoja_casillero.scale.x = $Sprite.scale.x * lerpf(1.0,.10,apertura)
	hoja_casillero.skew = -0.12 * apertura

func interactuar(jugador: CharacterBody2D) -> String:
	var escuela: Node = get_tree().get_first_node_in_group("control")
	match tipo:
		"salida":
			return escuela.campana.interactuar("salida_principal")
		"puerta":
			if abierto:
				var consulta := PhysicsShapeQueryParameters2D.new()
				var volumen := RectangleShape2D.new()
				volumen.size = Vector2(92, 16)
				consulta.shape = volumen
				consulta.transform = global_transform
				consulta.exclude = [get_rid()]
				consulta.collision_mask = 3
				if not get_world_2d().direct_space_state.intersect_shape(consulta).is_empty():
					return "Hay algo en el marco. Apartalo para cerrar."
			establecer_puerta(not abierto)
			escuela.sonidos.efecto("puerta", global_position, -2.0)
			ruido_emitido.emit(global_position, 0.35)
			return "Puerta abierta" if abierto else "Puerta cerrada"
		"empujar":
			var direccion: Vector2 = (global_position - jugador.global_position).normalized()
			move_and_collide(direccion * 32.0)
			escuela.rutas_pendientes = true
			escuela.sonidos.efecto("papel", global_position)
			ruido_emitido.emit(global_position, 0.7)
			return "Moviste: " + titulo
		"recoger":
			if titulo == "Expediente de Lalo":
				if not jugador.inventario.has("Llave maestra"):
					return "El expediente está cerrado. Busca la llave maestra en Dirección."
				if not escuela.zonas.get("Rectoria_Archivo", false):
					return "No puedes leer el expediente. Enciende el circuito de Rectoría."
			if not preload("res://src/player/mochila.gd").cabe(jugador.inventario,titulo):
				return "Mochila llena (6/6). Consume o descarta un suministro con I / Y."
			escuela.recogidos.append(str(name))
			jugador.inventario.append(titulo)
			escuela.sonidos.efecto("recoger", global_position)
			if titulo == "Expediente de Lalo":
				escuela.anunciar("EXPEDIENTE RECUPERADO", "Habla con la de Cómputo. Después toma la radio y la pala para salir al patio.")
				escuela.emitir_ruido(global_position, 1.4)
			recogido.emit(titulo)
			queue_free()
			return "Recogido: " + titulo
		"interruptor":
			escuela.sonidos.efecto("interruptor", global_position)
			escuela.campana.reparar(zona)
			return "Reparación del circuito: " + zona
		"breaker":
			escuela.sonidos.efecto("interruptor", global_position)
			escuela.campana.elegir_circuito()
			return "Selecciona un circuito para reparar. Cada zona es independiente."
		"escondite":
			jugador.esconder(self)
			return "Saliendo del escondite…" if jugador.oculto else "Entrando al escondite…"
	return titulo

func establecer_puerta(valor: bool) -> void:
	abierto = valor
	$Colision.set_deferred("disabled", abierto)
	$Sprite.texture = textura_abierta if abierto else textura_cerrada
	if giro_puerta: giro_puerta.kill()
	giro_puerta = create_tween()
	giro_puerta.tween_property($Sprite, "scale:x", escala_puerta.x * 0.84, 0.10)
	giro_puerta.tween_property($Sprite, "scale:x", escala_puerta.x, 0.14)
	if is_instance_valid(sombra):
		sombra.visible = not abierto and not vidrio

func abrir_archivero() -> void:
	establecer_puerta(true)
	var escuela := get_tree().get_first_node_in_group("control")
	escuela.sonidos.efecto("puerta", global_position, -12)
