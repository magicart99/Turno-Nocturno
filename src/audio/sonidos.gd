extends Node
var capas: Dictionary = {}
var espera_goteo := 3.0
var ambiente: AudioStreamPlayer
var volumen: float = 0.7
var recursos: Dictionary = {}
var tension: AudioStreamPlayer
var pasos_indice := 0
var variantes_pasos: Dictionary = {}
## Segundos de silencio pedidos por el director antes de un evento.
var silencio: float = 0.0
var presencia: AudioStreamPlayer2D

func _ready() -> void:
	volumen = Controles.volumen
	for nombre in ["paso", "papel", "puerta", "interruptor", "linterna", "recoger", "latido", "sello", "aviso", "ambiente"]:
		recursos[nombre] = load("res://assets/audio/" + nombre + ".wav")
	recursos["paso"] = load("res://assets/audio/cc0/Ejimas1.ogg")
	recursos["puerta"] = load("res://assets/audio/v7/puerta.ogg")
	recursos["ambiente"] = load("res://assets/audio/cc0/lost.ogg")
	for nombre in ["paso_exterior", "paso_archivero", "grito", "alarma", "jadeo", "chispa", "rele", "susurro", "metal"]:
		recursos[nombre] = load("res://assets/audio/" + nombre + ".wav")
	for tipo in ["concrete", "grass"]:
		variantes_pasos[tipo] = []
		for i in range(4): variantes_pasos[tipo].append(load("res://assets/audio/v7/footstep_%s_%03d.ogg" % [tipo,i]))
	for nombre in ["murmullo", "papeles", "radio_estatica"]:
		recursos[nombre] = load("res://assets/audio/v7/" + nombre + ".wav")
	for i in range(1,6):
		recursos["eco_%d" % i] = load("res://assets/audio/v8/eco_%d.mp3" % i)
	for nombre in ["goteo", "paso_baldosa"]:
		recursos[nombre] = load("res://assets/audio/v11/" + nombre + ".wav")
	for zona in ["pasillo", "cafeteria", "banos", "exterior"]:
		var capa := AudioStreamPlayer.new()
		capa.bus = "Ambiente"
		var audio: AudioStreamWAV = load("res://assets/audio/v11/" + zona + ".wav")
		audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio.loop_end = int(audio.data.size() / 2.0)
		capa.stream = audio
		capa.volume_db = -60
		add_child(capa)
		capas[zona] = capa
		if DisplayServer.get_name() != "headless": capa.play()
	ambiente = AudioStreamPlayer.new()
	ambiente.bus = "Música"
	ambiente.stream = recursos["ambiente"]
	ambiente.volume_db = -36.0
	add_child(ambiente)
	ambiente.finished.connect(ambiente.play)
	if DisplayServer.get_name() != "headless":
		ambiente.play()
	ajustar(volumen)
	tension = AudioStreamPlayer.new()
	tension.bus = "Música"
	tension.stream = load("res://assets/audio/cc0/ambient_horror.ogg")
	tension.volume_db = -60
	add_child(tension)
	tension.finished.connect(tension.play)
	if DisplayServer.get_name() != "headless": tension.play()

func _process(delta: float) -> void:
	var escuela := get_parent()
	var peligro: float = escuela.peligro if escuela.jugando else 0.0
	silencio = maxf(0.0, silencio - delta)
	actualizar_presencia(escuela, delta)
	var zona_actual: String = AudioManager.zona(escuela)
	AudioManager.ajustar_reverb(zona_actual, delta)
	for zona in capas:
		var objetivo: float = -22.0 - peligro * 12.0 if zona == zona_actual and silencio <= 0.0 else -60.0
		capas[zona].volume_db = move_toward(capas[zona].volume_db, objetivo, delta * 12.0)
		capas[zona].stream_paused = not escuela.jugando
	espera_goteo -= delta if escuela.jugando else 0.0
	if espera_goteo <= 0:
		espera_goteo = randf_range(3.5, 7.0)
		if zona_actual == "banos": efecto("goteo", Vector2(900, 950) if escuela.campana.lugar == "campus" else Vector2(2980, 180), -13)
	ambiente.volume_db = move_toward(ambiente.volume_db, -60.0 if silencio > 0.0 else -36.0 - peligro * 8.0, delta * 30.0)
	# Música por nivel: el mismo ambiente se vuelve más grave en cada nivel del campus.
	var etapa: int = clampi(int(escuela.campana.etapa), 1, 4)
	var tono_nivel: float = 1.0 if escuela.campana.lugar == "principal" else [1.0, 0.95, 0.9, 0.85][etapa - 1]
	ambiente.pitch_scale = move_toward(ambiente.pitch_scale, tono_nivel, delta * 0.05)
	tension.pitch_scale = move_toward(tension.pitch_scale, tono_nivel, delta * 0.05)
	# En el nivel 4 la capa de tensión nunca desaparece del todo: la persecución es constante.
	var minimo_tension: float = -44.0 if escuela.campana.etapa >= 4 and escuela.campana.lugar == "campus" else -60.0
	tension.volume_db = move_toward(tension.volume_db, lerpf(minimo_tension,-31,peligro),delta*14)

func actualizar_presencia(escuela: Node, delta: float) -> void:
	# Murmullo continuo pegado al Archivero: se le sigue por el oído, como él te sigue a ti.
	if DisplayServer.get_name() == "headless" or not is_instance_valid(escuela.archivero):
		return
	if presencia == null:
		var original: AudioStreamWAV = recursos.get("murmullo")
		if original == null:
			return
		var bucle := original.duplicate() as AudioStreamWAV
		bucle.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bucle.loop_begin = 0
		bucle.loop_end = int(bucle.get_length() * bucle.mix_rate)
		presencia = AudioStreamPlayer2D.new()
		presencia.stream = bucle
		presencia.bus = "Voces"
		presencia.max_distance = 760.0
		presencia.attenuation = 1.6
		presencia.volume_db = -60.0
		escuela.archivero.add_child(presencia)
	var archivero: CharacterBody2D = escuela.archivero
	var activo: bool = escuela.jugando and archivero.activo and archivero.visible
	if activo and not presencia.playing:
		presencia.play()
	presencia.stream_paused = not activo
	# A través de las paredes se oye más apagado.
	var objetivo: float = -60.0
	if activo:
		var rayo := PhysicsRayQueryParameters2D.create(archivero.global_position, escuela.jugador.global_position, 1, [archivero.get_rid(), escuela.jugador.get_rid()])
		var directo: bool = archivero.get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()
		objetivo = (-13.0 if directo else -21.0) + (3.0 if archivero.estado == "INVESTIGANDO" else 0.0)
	presencia.volume_db = move_toward(presencia.volume_db, objetivo, delta * 20.0)

func efecto(nombre: String, posicion: Vector2 = Vector2.INF, db: float = -8.0) -> void:
	if DisplayServer.get_name() == "headless" or not recursos.has(nombre):
		return
	var reproductor: Node
	if posicion == Vector2.INF:
		reproductor = AudioStreamPlayer.new()
	else:
		reproductor = AudioStreamPlayer2D.new()
		reproductor.position = posicion
		reproductor.max_distance = 900.0
		reproductor.attenuation = 0.7
	reproductor.bus = "Voces" if nombre.begins_with("eco_") or nombre in ["susurro", "murmullo", "grito"] else "SFX"
	if nombre == "goteo": reproductor.bus = "Ambiente"
	reproductor.stream = recursos[nombre]
	if nombre in ["paso", "paso_exterior"]:
		var tipo := "grass" if nombre == "paso_exterior" else "concrete"
		reproductor.stream = variantes_pasos[tipo][pasos_indice % 4]
		pasos_indice += 1
	# Las fuentes CC0 tienen niveles distintos: compensa sin alterar los originales.
	var compensacion := {"puerta": -3.0}
	reproductor.volume_db = db + float(compensacion.get(nombre,0.0))
	if nombre in ["paso", "paso_exterior", "paso_baldosa", "paso_archivero", "puerta"]:
		reproductor.pitch_scale = randf_range(0.91,1.08)
	# Límite de voces para carreras y persecuciones largas.
	if get_child_count() > 24:
		reproductor.free()
		return
	add_child(reproductor)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()

func ajustar(valor: float) -> void:
	volumen = valor
	Controles.volumen = valor
	AudioServer.set_bus_mute(0, valor <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(valor, 0.001)))

func _exit_tree() -> void:
	if is_instance_valid(presencia):
		presencia.stop()
		presencia.stream = null
	for reproductor in get_children():
		if reproductor is AudioStreamPlayer or reproductor is AudioStreamPlayer2D:
			reproductor.stop()
			reproductor.stream = null

func silenciar_ambiente(silenciar: bool) -> void:
	ambiente.stream_paused = silenciar
	tension.stream_paused = silenciar
	if silenciar:
		for voz in get_children():
			if voz != ambiente and voz != tension and not voz in capas.values() and (voz is AudioStreamPlayer or voz is AudioStreamPlayer2D):
				voz.stop()
				voz.queue_free()
