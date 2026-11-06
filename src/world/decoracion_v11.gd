extends Node2D
## Detalle ambiental sin alterar los accesos ni la navegación del campus.
func _ready() -> void:
	for dato in [["estante", Vector2(850,470)], ["refrigerador", Vector2(1130,470)]]:
		var mueble := StaticBody2D.new()
		mueble.position = dato[1]
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/sprites/cafeteria/pixel/" + dato[0] + ".png")
		sprite.z_index = 3
		sprite.scale = Vector2.ONE * 1.5
		sprite.offset.y = -sprite.texture.get_height() * 0.5
		mueble.add_child(sprite)
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(sprite.texture.get_width() * 1.4, 20)
		forma.shape = rect
		forma.position.y = -10
		mueble.add_child(forma)
		var contacto := preload("res://src/world/contacto_productos.gd").new()
		contacto.position.y = 25
		mueble.add_child(contacto)
		add_child(mueble)
	queue_redraw()

func _draw() -> void:
	# Bordes del andador, baldosas reparadas y hojas: paleta apagada y patrón estable.
	var azar := RandomNumberGenerator.new()
	azar.seed = 1107
	for y in range(1330, 2450, 64):
		draw_line(Vector2(1140,y), Vector2(1250,y), Color("394548"), 1)
		if y % 3 == 0:
			draw_polyline(PackedVector2Array([Vector2(1160,y),Vector2(1171,y+8),Vector2(1168,y+16)]),Color("252f34"),1)
	for i in range(100):
		var p := Vector2(azar.randf_range(1080,1330),azar.randf_range(1300,2450))
		draw_rect(Rect2(p,Vector2(3,2)), Color("6f6246") if i % 2 == 0 else Color("475440"))
	# Alfombra, líneas de espera y baldosas del mostrador.
	draw_rect(Rect2(875,510,230,100),Color("293c40"))
	for x in range(880,1100,22):
		draw_line(Vector2(x,510),Vector2(x,610),Color("415252"),1)
	draw_line(Vector2(890,615),Vector2(1090,615),Color("a18c5d"),2)
