extends RefCounted
## Efectos de juego; no representan propiedades nutricionales reales.
const PRODUCTOS = {
    "Papas limón": ["cafeteria/pixel/limon.png", 20.0, 10.0, 0.0, "+20 cordura y +10 resistencia."],
    "Churritos": ["cafeteria/pixel/churritos.png", 10.0, 35.0, 0.0, "+10 cordura y +35 resistencia."],
    "Agua mineral": ["cafeteria/pixel/agua.png", 0.0, 30.0, 15.0, "+30 resistencia y +15 sigilo."],
    "Chocolate": ["cafeteria/pixel/chocolate.png", 25.0, 15.0, 0.0, "+25 cordura y +15 resistencia."],
	"Sabritas Original": ["cafeteria/pixel/sabritas.png", 30.0, 0.0, 0.0, "Crujientes para tomar un respiro.\n+30 cordura."],
	"Sabritas Adobadas": ["cafeteria/pixel/adobadas.png", 15.0, 25.0, 0.0, "+15 cordura y +25 resistencia."],
	"Coca-Cola": ["cafeteria/pixel/coca_cola.png", 0.0, 50.0, 20.0, "+50 resistencia y +20 sigilo.\n45 s de menor gasto al correr y pasos más discretos."],
	"Marías Gamesa": ["cafeteria/pixel/marias.png", 20.0, 30.0, 0.0, "+20 cordura y +30 resistencia."]
}

static func consumir(escuela: Node, item: String) -> bool:
	if not PRODUCTOS.has(item) or not escuela.jugador.inventario.has(item): return false
	var j: CharacterBody2D = escuela.jugador
	var p: Array = PRODUCTOS[item]
	if (p[1] == 0 or j.cordura >= 100) and (p[2] == 0 or j.energia >= 100) and (p[3] == 0 or j.sigilo >= 100) and (item != "Coca-Cola" or escuela.campana.refresco > 0):
		return false
	j.inventario.erase(item)
	j.cordura = minf(100, j.cordura + p[1])
	j.energia = minf(100, j.energia + p[2])
	j.sigilo = minf(100, j.sigilo + p[3])
	if j.sigilo >= 35: j.sigilo_agotado = false
	if j.energia >= 25: j.carrera_agotada = false
	if item == "Coca-Cola": escuela.campana.refresco = 45
	escuela.sonidos.efecto("recoger", Vector2.INF, -20)
	return true
