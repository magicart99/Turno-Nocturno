extends SceneTree
var fallos := 0
var escena: Node

func _initialize() -> void:
	call_deferred("ejecutar")

func comprobar(condicion: bool, mensaje: String) -> void:
	print(("OK: " if condicion else "FALLO: ") + mensaje)
	if not condicion: fallos += 1

func captura(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/menu_video/" + nombre + ".png")

func ejecutar() -> void:
	escena = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	await create_timer(1.0).timeout
	var ui = escena.interfaz
	comprobar(ui.fondo.video.is_playing() and ui.fondo.musica.playing, "Inicio con video y música")
	await captura("inicio")
	await create_timer(12.5).timeout
	comprobar(ui.fondo.video.is_playing() and ui.fondo.video.stream_position < 12, "Video sigue en bucle tras 12 segundos")
	ui.mostrar("opciones")
	comprobar(ui.fondo.musica.playing, "Opciones conserva la música")
	ui.jugar()
	comprobar(not ui.fondo.video.is_playing() and not ui.fondo.musica.playing, "Juego detiene el fondo y su música")
	escena.jugando = true
	escena.archivar()
	comprobar(escena.transicion and ui.menu_actual == "cinematica", "Captura inicia cinemática y bloquea el juego")
	await create_timer(1.0).timeout
	await captura("muerte_video")
	comprobar(ui.cinematica.is_playing(), "Video de muerte reproduciéndose")
	await create_timer(4.0).timeout
	comprobar(ui.menu_actual == "muerte" and not escena.transicion, "Cinemática termina en reintento")
	comprobar(ui.fondo.video.is_playing() and ui.fondo.musica.playing, "Reintento recupera fondo y música")
	await captura("reintento")
	ui.mostrar("inicio")
	comprobar(ui.columna.get_child_count() == 6, "Menú principal conserva sus cuatro opciones")
	print("RESULTADO: %d fallos" % fallos)
	quit(fallos)
