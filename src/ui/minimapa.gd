extends Control
## Radar circular siempre visible. Norte fijo y Lalo centrado.
var escuela: Node2D
var viewport: SubViewport
var plano: Control
var leyenda: Label
var barrido: Control
var tiempo: float = 0.0
var fuente: Font = preload("res://assets/fuentes/Rajdhani-SemiBold.ttf")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.size = Vector2i(224,224)
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	plano = preload("res://src/ui/mapa_campus.gd").new()
	plano.escuela = escuela
	plano.radar = true
	plano.size = Vector2(224,224)
	viewport.add_child(plano)
	var imagen := TextureRect.new()
	imagen.texture = viewport.get_texture()
	imagen.position = Vector2(8,8)
	imagen.size = Vector2(224,224)
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE,UV); c.a *= 1.0-smoothstep(0.485,0.495,length(UV-vec2(0.5))); COLOR=c; }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	imagen.material = mat
	add_child(imagen)
	# Capa superior: barrido del radar, marcas de brújula y anillo de peligro.
	barrido = Control.new()
	barrido.position = Vector2.ZERO
	barrido.size = Vector2(240, 240)
	barrido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barrido.draw.connect(dibujar_barrido)
	add_child(barrido)
	leyenda = Label.new()
	leyenda.position = Vector2(-25,247)
	leyenda.size = Vector2(290,80)
	leyenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leyenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leyenda.add_theme_font_size_override("font_size",16)
	leyenda.add_theme_color_override("font_color",Color("f4cb72"))
	leyenda.add_theme_color_override("font_shadow_color",Color.BLACK)
	leyenda.add_theme_constant_override("shadow_offset_y",2)
	add_child(leyenda)
func _process(delta: float) -> void:
	visible = escuela.jugando
	tiempo += delta
	barrido.queue_redraw()
	plano.set_process(visible)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	var g: Control = escuela.interfaz.guia
	leyenda.text = (g.texto if g.texto != "" else "Explora el campus") + "\n" + ("OCULTO · refugio" if escuela.jugador.oculto else ("RUIDO · reduce el paso" if escuela.jugador.ruido > .6 else "▯ Refugio · V / gatillos: plano"))
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2(120,120),120,Color(0.015,0.025,0.04,.92))
	draw_arc(Vector2(120,120),116,0,TAU,96,Color("e39872") if escuela.jugador.ruido > .6 else Color("9bb5bc"),2,true)
	draw_arc(Vector2(120,120),119,0,TAU,96,Color("243844"),2,true)
	draw_string(fuente,Vector2(113,2),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ecf7f3"))

func dibujar_barrido() -> void:
	var c := Vector2(120, 120)
	var angulo := tiempo * 1.6
	for i in range(16):
		var a: float = angulo - i * 0.045
		barrido.draw_line(c, c + Vector2.from_angle(a) * 110.0, Color(0.55, 1.0, 0.85, 0.11 * (1.0 - i / 16.0)), 2.0)
	for i in range(24):
		var dir := Vector2.from_angle(i * TAU / 24.0 - PI / 2.0)
		barrido.draw_line(c + dir * 104.0, c + dir * (111.0 if i % 6 == 0 else 107.0), Color(0.62, 0.76, 0.78, 0.65), 1.0)
	var peligro: float = escuela.peligro
	if peligro > 0.05:
		barrido.draw_arc(c, 113.0, 0, TAU, 72, Color(0.95, 0.16, 0.1, peligro * (0.55 + 0.45 * sin(tiempo * 8.0))), 3.0, true)

