extends Node2D
## Circuitos exteriores independientes y luces adaptadas al campus compacto.
func _ready() -> void:
	var escuela := get_tree().get_first_node_in_group("control")
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("d5b478"),Color(0,0,0,0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 700
	tex.height = 700
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5,0.5)
	tex.fill_to = Vector2(1,0.5)
	for p in [Vector2(1500,800),Vector2(900,500),Vector2(2100,1140),Vector2(1200,1450),Vector2(1200,1820),Vector2(1200,2150),Vector2(1200,2400),Vector2(1050,2719),Vector2(2200,2719),Vector2(2470,2630)]:
		var luz := PointLight2D.new()
		luz.position = p
		luz.texture = tex
		luz.energy = 1.05
		luz.shadow_enabled = true
		luz.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		var zona: String = "Exterior_Servicios" if p.y < 1250 else ("Exterior_Andador" if p.y < 2498 else "Exterior_Parking")
		if p.x == 2470: zona = "Exterior_Caseta"
		luz.set_meta("zona", zona)
		luz.set_meta("energia_base", 1.05)
		luz.add_to_group("luces_zona")
		if not escuela.zonas.has(zona): escuela.zonas[zona] = zona == "Exterior_Caseta"
		luz.enabled = escuela.zonas[zona]
		add_child(luz)

	add_child(preload("res://src/world/detalle_patio.gd").new())
