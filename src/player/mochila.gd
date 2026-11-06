extends RefCounted
const CAPACIDAD := 6
const Productos = preload("res://src/world/productos_cafeteria.gd")

static func ocupa(item: String) -> bool:
	return Productos.PRODUCTOS.has(item) or item in ["Termo de cafe", "Extintor", "Grapadora"]

static func usados(inventario: Array) -> int:
	var total := 0
	for item in inventario:
		if ocupa(item): total += 1
	return total

static func cabe(inventario: Array, item: String) -> bool:
	return not ocupa(item) or usados(inventario) < CAPACIDAD
