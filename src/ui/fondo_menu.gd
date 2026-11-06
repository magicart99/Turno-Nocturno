extends Control
## Fondo compartido por todos los menús. El audio mantiene su propio bucle.
var video: VideoStreamPlayer
var musica: AudioStreamPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(negro)
	video = VideoStreamPlayer.new()
	video.stream = preload("res://assets/cinematicas/fondo_menu.ogv")
	video.expand = true
	video.loop = true
	video.volume_db = -80
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(video)
	resized.connect(ajustar_video)
	ajustar_video()
	musica = AudioStreamPlayer.new()
	var pista := load("res://assets/cinematicas/musica_menu.wav") as AudioStreamWAV
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0
	pista.loop_end = int(pista.get_length() * pista.mix_rate)
	musica.stream = pista
	musica.volume_db = -10
	add_child(musica)

func ajustar_video() -> void:
	# Rellena sin deformar; recorta los bordes en ventanas de otra proporción.
	var escala := maxf(size.x / 1280.0, size.y / 720.0)
	video.size = Vector2(1280, 720) * escala
	video.position = (size - video.size) * 0.5

func activar(activo: bool) -> void:
	visible = activo
	if activo:
		if not video.is_playing(): video.play()
		if not musica.playing: musica.play()
	else:
		video.stop()
		musica.stop()

func _exit_tree() -> void:
	if is_instance_valid(video):
		video.stop()
		video.stream = null
	if is_instance_valid(musica):
		musica.stop()
		musica.stream = null
