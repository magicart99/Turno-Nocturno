extends SceneTree
## v16: acabados visuales, haz de linterna, documentos, director de tensión e IA del Archivero.
## godot --headless --path . --script res://tests/probar_mejoras_v16.gd
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ")+texto)
	if not ok: fallos += 1
func esperar(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func contar(raiz: Node, nombre: String) -> int:
	var total := 0
	for n in raiz.get_children():
		if str(n.name).begins_with(nombre): total += 1
		total += contar(n, nombre)
	return total
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://partidas/prueba_v16.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	await esperar(4)
	var j: CharacterBody2D = e.jugador
	var a: CharacterBody2D = e.archivero
	# Acabados
	var piso: Sprite2D = e.get_node("Pisos").get_child(0)
	check(piso.material is ShaderMaterial, "Suelos con desgaste")
	check(contar(e.get_node("Paredes"), "CaraV16") > 20, "Muros con cara visible")
	check(contar(e.get_node("Objetos"), "SombraMueble") > 5, "Muebles proyectan sombra para la linterna")
	check(j.get_node("Linterna").shadow_item_cull_mask & 2 != 0, "La linterna lee las sombras de muebles")
	check(is_instance_valid(e.atmosfera.haz), "Haz volumétrico creado")
	# Documentos
	var docs: Array = []
	for n in e.get_node("Objetos").get_children():
		if str(n.name).begins_with("Documento"): docs.append(n)
	check(docs.size() >= 6, "Documentos colocados en las salas (%d)" % docs.size())
	if not docs.is_empty():
		docs[0].interactuar(j)
		check(e.campana.hechos.get(docs[0].marca(), false) and e.interfaz.menu_actual == "dialogo", "Leer un documento abre el texto y lo registra")
		e.continuar()
	check(e.guardar_partida(), "El guardado acepta los documentos leídos")
	# Director de tensión
	e.get_children().filter(func(n): return n.get_script() == load("res://src/world/director_terror.gd"))[0].programar()
	check(e.sonidos.silencio > 0.0, "Antes de un evento el ambiente guarda silencio")
	# IA: persecución de cerca y revisión de escondites
	e.set_process(false); a.set_physics_process(false)
	j.set_physics_process(false)
	j.position = Vector2(2000, 650); a.position = Vector2(2100, 650)
	a.activo = true; a.estado = "INVESTIGANDO"; j.ruido = 1.0; j.oculto = false
	a.seguir_de_cerca()
	check(a.persiguiendo and a.destino == j.global_position, "De cerca sigue a Lalo si hace ruido")
	j.ruido = 0.0; j.linterna = false
	a.seguir_de_cerca()
	check(not a.persiguiendo, "Agachado y sin linterna no lo rastrea")
	var escondite: Node2D = null
	for n in e.get_node("Objetos").get_children():
		if n.get("tipo") == "escondite": escondite = n; break
	if escondite:
		j.oculto = true; j.ultimo_escondite = escondite
		a.position = escondite.position + Vector2(120, 0)
		check(a.buscar_escondite() and a.revisando, "Revisa el escondite cercano")
		check(not a.buscar_escondite(), "No revisa el mismo escondite dos veces seguidas")
		a.volver_patrulla()
		check(not a.revisando, "Volver a patrullar limpia la revisión")
	j.oculto = false; a.activo = false
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free(); await esperar(); quit(fallos)
