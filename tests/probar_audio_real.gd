extends SceneTree
## Verifica salida del mezclador real. Ejecutar con ventana, sin --headless.
var escena: Node2D
var fallos: int = 0
var registro: Array[String] = []
func _initialize() -> void: call_deferred("ejecutar")
func medir(nombre: String, posicion: Vector2, db: float, duracion: float) -> void:
	escena.sonidos.efecto(nombre,posicion,db)
	var pico: float = -200
	var restante: float = duracion
	while restante > 0:
		await create_timer(.025).timeout
		pico = maxf(pico,maxf(AudioServer.get_bus_peak_volume_left_db(0,0),AudioServer.get_bus_peak_volume_right_db(0,0)))
		restante -= .025
	var ok: bool = pico > -42 and pico < 0
	if not ok: fallos += 1
	registro.append(("OK " if ok else "FALLO ")+"Salida audible sin saturación · %s · %.1f dB"%[nombre,pico])
	print(registro[-1])
	await create_timer(.15).timeout
func ejecutar() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Esta prueba requiere el mezclador del dispositivo de audio real.")
		quit(1); return
	escena=load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena); current_scene=escena
	await create_timer(.3).timeout
	escena.sonidos.ambiente.stop();escena.sonidos.tension.stop()
	var p: Vector2 = escena.jugador.global_position
	await medir("paso",Vector2.INF,-11,1.0)
	await medir("paso_exterior",Vector2.INF,-11,.4)
	await medir("puerta",p+Vector2(50,0),-2,4.5)
	await medir("paso_archivero",p+Vector2(150,0),-10,.8)
	for nombre in ["jadeo","chispa","rele","susurro","metal"]:
		await medir(nombre,Vector2.INF,-12,escena.sonidos.recursos[nombre].get_length()+.1)
	registro.append("RESULTADO: %d fallos"%fallos)
	print(registro[-1])
	FileAccess.open("res://docs/pruebas_audio_real.txt",FileAccess.WRITE).store_string("\n".join(registro))
	quit(fallos)
