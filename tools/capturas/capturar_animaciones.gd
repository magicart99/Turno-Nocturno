extends SceneTree
func _initialize() -> void: call_deferred("ejecutar")
func ejecutar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("101a23")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fondo)
	var titulo := Label.new()
	titulo.text = "LALO · LINTERNА, SIGILO Y ACCIONES"
	titulo.position = Vector2(40,20)
	titulo.add_theme_font_size_override("font_size",24)
	fondo.add_child(titulo)
	var referencia := preload("res://src/player/animacion_personaje.gd").crear("lalo")
	var animaciones := ["torch_right","torch_down","torch_up","torch_left","crouch_right","crouch_down","crouch_up","crawl_up","crawl","crawl_down","dig","dig_up"]
	for i in range(animaciones.size()):
		var origen := Vector2(40 + (i%4)*300,70+(i/4)*200)
		var tarjeta := ColorRect.new()
		tarjeta.position=origen; tarjeta.size=Vector2(280,184);tarjeta.color=Color("172934")
		fondo.add_child(tarjeta)
		var nombre := Label.new()
		nombre.text=animaciones[i].replace("torch","linterna").replace("crouch","agachado").replace("crawl","gatear").replace("dig","excavar")
		nombre.position=Vector2(12,10)
		nombre.add_theme_font_size_override("font_size",18)
		tarjeta.add_child(nombre)
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames=referencia.sprite_frames
		sprite.position=Vector2(140,169);sprite.offset=Vector2(0,-160);sprite.scale=Vector2.ONE*.45
		tarjeta.add_child(sprite)
		sprite.play(animaciones[i])
	await create_timer(.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/capturas_anteriores/animaciones_lalo_v3.png")
	referencia.free()
	quit()
