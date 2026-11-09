extends Node
## Tutorial contextual (plan de trabajo, semana 6): cada consejo aparece una sola vez,
## cuando hace falta, y queda marcado en la partida guardada.
const PASOS := [
	["tut_mover", "WASD / stick para caminar · Shift corre, pero tus pasos se oyen lejos."],
	["tut_linterna", "F / X enciende la linterna. Ilumina, pero el Archivero puede ver el haz."],
	["tut_esconder", "E / A junto a casilleros, escritorios y archiveros para esconderte."],
	["tut_agachar", "C / Ctrl para agacharte: no haces ruido, pero gastas la barra de SIGILO."],
	["tut_mochila", "I / Y abre la mochila: objetos, MISIONES y el diario con lo que encuentres."],
	["tut_distraer", "Q / RB lanza la grapadora para atraer al Archivero hacia otro lado."],
	["tut_plano", "V / Tab abre el plano completo con la ruta al objetivo."],
	["tut_seguro", "La luz cálida marca un PUNTO SEGURO: guarda la partida y recupera cordura."],
]
var escuela: Node2D
var espera: float = 2.5

func _ready() -> void:
	escuela = get_parent()

func _process(delta: float) -> void:
	if not escuela.jugando or escuela.campana == null:
		return
	espera -= delta
	if espera > 0.0:
		return
	for paso in PASOS:
		var clave: String = paso[0]
		if escuela.campana.hechos.get(clave, false) or not cumple(clave):
			continue
		escuela.campana.hechos[clave] = true
		escuela.interfaz.mostrar_consejo(paso[1])
		espera = 8.0
		return

func cumple(clave: String) -> bool:
	var j: CharacterBody2D = escuela.jugador
	match clave:
		"tut_mover": return true
		"tut_linterna": return escuela.tiempo > 12.0
		"tut_esconder":
			var cerca: Variant = escuela.cercano_actual
			return is_instance_valid(cerca) and cerca.get("tipo") == "escondite"
		"tut_agachar": return escuela.archivero.activo
		"tut_mochila": return not j.inventario.is_empty()
		"tut_distraer": return j.inventario.has("Grapadora")
		"tut_plano": return escuela.tiempo > 40.0
		"tut_seguro":
			for punto in escuela.get_tree().get_nodes_in_group("puntos_seguros"):
				if punto.activo() and punto.global_position.distance_to(j.global_position) < 260.0: return true
	return false
