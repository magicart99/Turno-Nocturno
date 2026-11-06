extends RefCounted
## Una ranura y un respaldo. La partida se valida antes de tocar el mundo.
static var ruta: String = "res://partidas/partida.json"

static func configurar() -> void:
	if OS.has_feature("standalone") and not OS.has_feature("editor"):
		ruta = "user://partidas/partida.json"

static func leer_archivo(archivo: String) -> Dictionary:
	if not FileAccess.file_exists(archivo):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(archivo)) != OK:
		return {}
	var datos: Variant = json.data
	if not datos is Dictionary or datos.get("version") != 1:
		return {}
	for campo in ["jugador", "archivero", "objetos", "zonas"]:
		if not datos.get(campo) is Dictionary:
			return {}
	if not datos.get("recogidos") is Array or not datos.jugador.get("inventario") is Array:
		return {}
	if not posicion_valida(datos.jugador.get("posicion")) or not posicion_valida(datos.archivero.get("posicion")) or not posicion_valida(datos.archivero.get("destino")):
		return {}
	for clave in ["energia", "cordura"]:
		var valor: Variant = datos.jugador.get(clave)
		if not (valor is float or valor is int) or not is_finite(float(valor)) or valor < 0 or valor > 100:
			return {}
	for objeto in datos.objetos.values():
		if not objeto is Dictionary or not posicion_valida(objeto.get("posicion")) or not objeto.get("abierto") is bool:
			return {}
	for item in datos.jugador.inventario + datos.recogidos:
		if not item is String:
			return {}
	for valor in datos.zonas.values():
		if not valor is bool:
			return {}
	if not datos.jugador.get("linterna") is bool or not datos.archivero.get("activo") is bool:
		return {}
	if datos.jugador.has("agachado") and not datos.jugador.agachado is bool: return {}
	if datos.jugador.has("sigilo"):
		var s: Variant=datos.jugador.sigilo
		if not (s is int or s is float) or not is_finite(float(s)) or s<0 or s>100:return {}
	if datos.jugador.has("sigilo_agotado") and not datos.jugador.sigilo_agotado is bool:return {}
	if datos.jugador.has("descanso_sigilo"):
		var d: Variant=datos.jugador.descanso_sigilo
		if not (d is int or d is float) or not is_finite(float(d)) or d<0 or d>2.5:return {}
	if not datos.archivero.get("estado") in ["DORMIDO", "PATRULLANDO", "INVESTIGANDO", "BUSCANDO"]:
		return {}
	for clave in ["tiempo", "memoria", "espera"]:
		var valor: Variant = datos.get(clave) if clave == "tiempo" else datos.archivero.get(clave)
		if not (valor is float or valor is int) or not is_finite(float(valor)) or valor < 0:
			return {}
	if datos.has("campana"):
		var c: Variant = datos.campana
		if not c is Dictionary or not (c.get("etapa") is int or c.get("etapa") is float) or c.etapa < 1 or c.etapa > 4 or c.etapa != floorf(c.etapa) or not c.get("lugar") in ["principal","campus"] or not c.get("hechos") is Dictionary:
			return {}
		for clave in ["monedas", "bateria", "refresco"]:
			var v: Variant = c.get(clave)
			if not (v is int or v is float) or not is_finite(float(v)) or v < 0: return {}
		if c.bateria > 100 or not c.get("final_liberado") is bool: return {}
		if c.has("alimentado") and not c.alimentado is String:return {}
		if c.has("explorados"):
			if not c.explorados is Dictionary or c.explorados.size()>2048: return {}
			for k in c.explorados:
				if not k is String or not c.explorados[k] is bool: return {}
		if c.has("gracia_patio"):
			var gracia: Variant = c.gracia_patio
			if not (gracia is int or gracia is float) or not is_finite(float(gracia)) or gracia < 0 or gracia > 60: return {}
		for v in c.hechos.values():
			if not v is bool: return {}
	return datos

static func posicion_valida(valor: Variant) -> bool:
	if not valor is Array or valor.size() != 2:
		return false
	for numero in valor:
		if not (numero is float or numero is int) or not is_finite(float(numero)):
			return false
	return valor[0] >= 0 and valor[0] <= 4200 and valor[1] >= 0 and valor[1] <= 7200

static func leer() -> Dictionary:
	var datos := leer_archivo(ruta)
	return leer_archivo(ruta + ".bak") if datos.is_empty() else datos

static func guardar(datos: Dictionary) -> bool:
	var carpeta := ProjectSettings.globalize_path(ruta.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(carpeta) != OK:
		return false
	var temporal := ruta + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.flush()
	var correcto := archivo.get_error() == OK
	archivo.close()
	if not correcto or leer_archivo(temporal).is_empty():
		return false
	if not leer_archivo(ruta).is_empty():
		if DirAccess.copy_absolute(ruta, ruta + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(temporal, ruta) == OK
