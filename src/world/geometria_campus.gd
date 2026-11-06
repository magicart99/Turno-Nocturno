extends RefCounted
const VERSION: int = 6
const TAMANO := Vector2i(3200,3220)
const ENTRADA := Vector2(1300,2082.5)
const ARCHIVERO := Vector2(1050,1556)
const SALIDA := Rect2(2730,2732.5,430,286)
const PATRULLA := [Vector2(1200,2089),Vector2(1050,1673),Vector2(1510,1370),Vector2(1300,2303.5)]
const PARKING := Vector2(1840,2719.5)
const PRINCIPAL := Rect2(1600,1432.5,640,942.5)
const SERVICIOS := Rect2(600,200,1720,1030)
const ESTACIONAMIENTO := Rect2(520,2498.5,1760,461.5)

static func compactar(p: Vector2) -> Vector2:
	return Vector2(p.x,p.y if p.y <= 1400 else 1400+(p.y-1400)*0.65)

static func adaptar_v4(p: Vector2) -> Vector2:
	# Los cambios de fachada requieren un acceso seguro, no reflejar al jugador.
	if p.y < 1230: return p
	if p.y > 3070: return PARKING
	return ENTRADA

static func adaptar_antiguo(p: Vector2) -> Vector2:
	var pares := [[Vector2(2410,3650),ENTRADA],[Vector2(2800,2100),ARCHIVERO],[Vector2(1760,1650),Vector2(1510,1370)],[Vector2(1650,900),Vector2(1460,1000)],[Vector2(900,500),Vector2(900,500)],[Vector2(2450,1200),Vector2(2160,1120)],[Vector2(1050,1000),Vector2(1040,880)],[Vector2(2800,4800),Vector2(2080,2790)],[Vector2(2480,6350),PARKING],[Vector2(3370,6210),Vector2(2470,3500)],[Vector2(3740,6610),Vector2(2870,3640)]]
	var mejor: Vector2 = ENTRADA
	var distancia: float = INF
	for par in pares:
		var d: float = p.distance_squared_to(par[0])
		if d < distancia:
			distancia = d
			mejor = par[1]
	return mejor
