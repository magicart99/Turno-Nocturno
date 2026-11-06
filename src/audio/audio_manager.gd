extends Node
## Mezcla persistente; las fuentes pertenecen a cada escena y se liberan con ella.
var reverberacion := AudioEffectReverb.new()

func _ready() -> void:
	for nombre in ["Música", "Ambiente", "SFX", "Voces"]:
		if AudioServer.get_bus_index(nombre) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, nombre)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	reverberacion.room_size = 0.72
	reverberacion.damping = 0.65
	reverberacion.wet = 0.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Ambiente"), reverberacion)

func zona(escuela: Node) -> String:
	var p: Vector2 = escuela.jugador.position
	if escuela.campana.lugar == "campus":
		if Rect2(600,800,560,430).has_point(p): return "banos"
		if Rect2(600,200,600,500).has_point(p): return "cafeteria"
		return "pasillo" if Rect2(600,200,1720,1030).has_point(p) else "exterior"
	return "banos" if Rect2(2688,0,1152,448).has_point(p) else "pasillo"

func ajustar_reverb(zona_actual: String, delta: float) -> void:
	reverberacion.wet = move_toward(reverberacion.wet, 0.28 if zona_actual == "pasillo" else 0.06, delta * 0.15)
