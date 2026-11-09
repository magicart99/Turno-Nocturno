extends Node2D
var escuela: Node2D
var silueta: Sprite2D
var tiempo := 0.0
func _ready() -> void:
	escuela = get_tree().get_first_node_in_group("control")
	silueta = get_parent().get_node("Sprite3")
	silueta.modulate = Color(.67,.9,1,.8)
	silueta.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var nombre := Label.new()
	nombre.text = "LA DE CÓMPUTO"
	var tinta := CanvasItemMaterial.new()
	tinta.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	nombre.material = tinta
	nombre.position=Vector2(-78,-110)
	nombre.add_theme_font_override("font",preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"))
	nombre.add_theme_font_size_override("font_size",18)
	nombre.modulate=Color(.6,.9,1,.85)
	add_child(nombre)
func _process(delta: float) -> void:
	if not escuela.jugando: return
	tiempo += delta
	silueta.position=Vector2(sin(tiempo*.7)*3,-15+sin(tiempo*1.6)*7)
	silueta.rotation=sin(tiempo*.8)*.022
	silueta.modulate.a=.58+sin(tiempo*2)*.10
	if escuela.campana.hechos.get("computo",false): silueta.modulate.a = .32
	# La figura se desdobla apenas, como una imagen retenida en el monitor.
	silueta.skew = sin(tiempo*1.1)*.025
	queue_redraw()
func _draw() -> void:
	# Sombra en el suelo y motas que ascienden: altura visible sin mover la colisión.
	draw_set_transform(Vector2(0,28),0,Vector2(1,.24))
	draw_circle(Vector2.ZERO,24,Color(.02,.05,.08,.65))
	draw_set_transform(Vector2.ZERO)
	for i in range(12):
		var y: float = fmod(tiempo*15+i*13,100)
		draw_circle(Vector2(sin(i*2.4+tiempo*.4)*28,30-y),1.3,Color(.45,.85,1,(1-y/100)*.45))
