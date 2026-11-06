extends Node2D
## El hallazgo emerge durante la excavación y queda disponible hasta recogerlo.
var escuela: Node2D
var usb: Sprite2D
var etiqueta: Label
var avance := 0.0

func _ready() -> void:
	escuela = get_tree().get_first_node_in_group("control")
	z_index = 8
	var tinta := CanvasItemMaterial.new()
	tinta.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = tinta
	usb = Sprite2D.new()
	usb.texture = preload("res://assets/sprites/usb.png")
	usb.scale = Vector2.ONE * (32.0 / usb.texture.get_width())
	usb.use_parent_material = true
	add_child(usb)
	etiqueta = Label.new()
	etiqueta.text = "MEMORIA USB"
	etiqueta.position = Vector2(-72,-62)
	etiqueta.size.x = 144
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 17)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 5)
	etiqueta.use_parent_material = true
	add_child(etiqueta)

func _process(_delta: float) -> void:
	var c: Node = escuela.campana
	var excavando: bool = escuela.jugador.accion == "excavar" and escuela.jugador.global_position.distance_to(global_position) < 100
	avance = 1.0 if c.hechos.get("memoria_desenterrada",false) else (escuela.jugador.avance_accion / escuela.jugador.duracion_accion if excavando else 0.0)
	usb.visible = avance > 0.45
	usb.modulate.a = clampf((avance-0.45)/0.55,0,1)
	usb.position.y = -22 * smoothstep(0.45,1.0,avance) + sin(escuela.tiempo*2.2)*2
	etiqueta.visible = avance >= 1
	get_parent().titulo = "Memoria USB · recoger" if avance >= 1 else "Tierra removida · excavar"
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.45))
	draw_circle(Vector2.ZERO,27,Color("302821"))
	draw_circle(Vector2.ZERO,20,Color("100f13"))
	draw_arc(Vector2.ZERO,25,0,TAU,32,Color("75604b"),2,true)
	draw_set_transform(Vector2.ZERO)
	if avance > 0 and avance < 1:
		for i in range(8):
			var fase := fposmod(avance*4+i*.17,1.0)
			var p := Vector2((i-3.5)*6*fase,-sin(fase*PI)*18)
			draw_circle(p,2,Color(.45,.34,.22,1-fase))
	if avance >= 1:
		draw_arc(Vector2(0,-22),23,0,TAU,40,Color(.75,.9,.7,.45+sin(escuela.tiempo*2)*.15),1.5,true)
