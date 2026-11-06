extends Node2D
## Accesorio en la mano y polvo acompasado con la pala.
func _ready() -> void:
	z_index = 6

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var j := get_parent()
	if j.oculto or j.accion in ["entrar", "salir"]: return
	if j.accion == "excavar":
		var fase: float = fmod(j.avance_accion * 1.5, 1.0)
		var lado: float = -1 if j.apuntado.x < 0 else 1
		for i in range(7):
			var p := Vector2(lado*(18+i*2),-2) + Vector2(sin(i*2.4)*18,-18-float(i)*2)*fase
			draw_rect(Rect2(p,Vector2(2,2)),Color(0.55,0.43,0.3,1-fase))
		return
	if not j.linterna: return
	if j.sprite.animation.begins_with("torch_"): return
	var p: Vector2 = j.mano + j.apuntado*12
	draw_set_transform(p,j.apuntado.angle())
	draw_rect(Rect2(-4,-3,17,6),Color("202b35"))
	draw_rect(Rect2(9,-4,5,8),Color("818b91"))
	draw_line(Vector2(14,-3),Vector2(14,3),Color("fff3c5"),2)
	draw_circle(Vector2(0,2),2.8,Color("ba8768"))
