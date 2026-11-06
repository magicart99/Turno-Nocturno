extends Node2D
## Cuadros completos: evita las juntas y pies separados del recorte procedural.
var activo := false
func _process(_delta: float) -> void:
	var j := get_parent()
	var s: AnimatedSprite2D = j.sprite
	s.self_modulate.a = 1.0
	activo = j.escuela.jugando and j.accion == "" and not j.oculto and j.get_real_velocity().length() > 3
	if not activo:return
	s.pause()
	var zancada: float = 44.0 if j.agachado else 72.0
	var fase: float = fposmod(j.distancia_animada / zancada, 1.0)
	var cuadros: int = s.sprite_frames.get_frame_count(s.animation)
	s.frame = mini(int(fase * cuadros),cuadros-1)
	# Desplazamiento de medio píxel; nunca deforma ni separa el atlas.
	s.position.y = -absf(sin(fase * TAU)) * (0.3 if j.agachado else 0.6)
