extends SceneTree
## Calcula regiones/pivotes sin modificar los píxeles de la hoja generada.
func _initialize() -> void:
	var imagen := Image.load_from_file("res://assets/sprites/lalo/caminar_linterna_v10.png")
	var nombres := ["torch_down", "torch_right", "torch_up", "torch_left"]
	var filas := [0, 300, 600, 890, 1199]
	var animaciones := {}
	for fila in range(4):
		var cuadros := []
		for columna in range(4):
			var inicio := columna * 328
			var limite := mini(inicio + 328, imagen.get_width())
			var izq := limite; var der := inicio; var arriba: int = filas[fila + 1]; var abajo: int = filas[fila]
			for y in range(filas[fila], filas[fila + 1]):
				for x in range(inicio, limite):
					if imagen.get_pixel(x, y).a > 0.7:
						izq = mini(izq, x); der = maxi(der, x)
						arriba = mini(arriba, y); abajo = maxi(abajo, y)
			var suma := 0.0; var cuenta := 0
			for y in range(arriba, mini(arriba + 65, abajo)):
				for x in range(izq, der + 1):
					var color := imagen.get_pixel(x, y)
					if color.a > 0.9 and maxf(color.r, maxf(color.g, color.b)) < 0.3:
						suma += x; cuenta += 1
			var centro := suma / maxf(1, cuenta)
			cuadros.append({"region": [izq, arriba, der - izq + 1, abajo - arriba + 1], "izquierda": 160 - (centro - izq)})
		animaciones[nombres[fila]] = cuadros
	var salida := FileAccess.open("res://assets/sprites/lalo/atlas_marcha_v10.json", FileAccess.WRITE)
	salida.store_string(JSON.stringify({"caminar_linterna_v10.png": animaciones}, "\t"))
	salida.close()
	quit()
