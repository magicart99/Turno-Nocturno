extends SceneTree
## v14: tablero rediseñado, intensidad por nivel, cordura del GDD y narrativa nueva.
## godot --headless --path . --script res://tests/probar_mejoras_v14.gd
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
func resolver_cables(t: CanvasLayer) -> void:
	for fuente in t.fuentes:
		if fuente.disabled: continue
		fuente.pressed.emit()
		for destino in t.destinos:
			if destino.text == fuente.text:
				destino.pressed.emit()
				break
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await esperar(12)
	e.Guardado.ruta = "res://partidas/prueba_v14.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.set_process(false); e.mente.set_process(false)
	e.archivero.set_physics_process(false); e.archivero.activo = false
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	var c: Node = e.campana
	check(is_instance_valid(e.atmosfera) and e.has_node("Archivero"), "Capa de atmósfera instalada")
	# Tablero eléctrico
	c.abrir_tablero("Computo"); await esperar()
	var t: CanvasLayer = c.tablero
	check(not t.conmutar.visible, "Circuito sin reparar exige cableado")
	t.fuentes[0].pressed.emit()
	for d in t.destinos:
		if d.text != t.fuentes[0].text:
			d.pressed.emit()
			break
	check(t.chispazos == 1 and t.conectados.is_empty() and not t.chispas.is_empty(), "Cortocircuito lanza chispas y queda registrado")
	resolver_cables(t)
	check(t.calibrando and t.medidor.visible, "Cuatro cables muestran el medidor de aguja")
	t.fase = PI / 2; t.estabilizar()
	check(not t.terminado and t.chispazos == 2, "Aguja fuera de rango no repara")
	t.fase = 0.0; t.estabilizar(); await esperar()
	check(c.alimentado == "Computo" and e.jugando, "Aguja en verde alimenta Cómputo")
	e.alimentar_zona("Entrada")
	c.abrir_tablero("Computo"); await esperar()
	t = c.tablero
	check(t.conmutar.visible, "Circuito reparado ofrece conmutación sin cables")
	t.conmutar.pressed.emit(); await esperar()
	check(c.alimentado == "Computo" and e.jugando, "Conmutar alimenta sin repetir el minijuego")
	# Intensidad del Archivero por nivel
	c.etapa = 1; e.archivero.construir_rutas()
	check(e.archivero.velocidad_busqueda < 112.0, "Nivel 1: el Archivero investiga más lento que Lalo andando")
	c.etapa = 4; e.archivero.construir_rutas()
	check(e.archivero.velocidad_busqueda > 112.0, "Nivel 4: persecución más rápida que caminar")
	c.etapa = 1; e.archivero.construir_rutas()
	# Detección y cordura
	j.position = Vector2(2000, 650); e.archivero.position = Vector2(2200, 650)
	e.archivero.activo = true; e.archivero.estado = "PATRULLANDO"; j.cordura = 80
	e.archivero.escuchar(j.position, 0.8)
	check(is_equal_approx(j.cordura, 77.0) and e.archivero.estado == "INVESTIGANDO", "Detección cercana resta cordura")
	e.archivero.escuchar(j.position, 0.8)
	check(is_equal_approx(j.cordura, 77.0), "Seguir investigando no vuelve a restar")
	e.archivero.activo = false; e.archivero.estado = "DORMIDO"
	# Narrativa
	e.relato.cola.clear()
	c.hechos["memoria_desenterrada"] = true; c.hechos["pala"] = true
	c.interactuar("archivo_enterrado")
	check(j.inventario.has("Archivo 001") and j.inventario.has("Memoria USB del patio"), "El Archivo Enterrado entrega el Archivo 001")
	check(e.relato.cola.size() >= 2, "El Archivo 001 revela el origen y la pista del Sello Roto")
	e.relato.cola.clear(); c.etapa = 2
	e.relato._process(0.016)
	check(c.hechos.get("relato_etapa_2", false) and not e.relato.cola.is_empty(), "Don Chuy habla por radio al cambiar de nivel")
	e.al_recoger("Sello roto")
	check(c.hechos.get("relato_objeto_Sello roto", false), "Recoger el Sello Roto tiene reacción de Lalo")
	# Misiones, mochila y salones
	var misiones: Array = c.lista_misiones()
	check(misiones.size() == 5 and misiones[0][1].size() == 5, "Lista de misiones agrupada por nivel")
	var inv: CanvasLayer = preload("res://src/ui/inventario.gd").new()
	inv.escuela = e
	e.add_child(inv); await esperar()
	inv.misiones()
	check(is_instance_valid(inv.panel_misiones), "La mochila muestra la página de misiones")
	inv.misiones()
	check(not is_instance_valid(inv.panel_misiones), "El mismo botón cierra la página de misiones")
	inv.queue_free(); await esperar()
	var lugares: Node = null
	for n in e.get_children():
		if n.get_script() == load("res://src/world/ambiente_lugares.gd"): lugares = n
	check(lugares != null and not lugares.pizarrones.is_empty() and not lugares.relojes.is_empty(), "Salones con pizarrones y relojes intervenidos")
	c.etapa = 1; j.cordura = 5.0
	check(e.guardar_partida(), "El guardado acepta las nuevas marcas narrativas")
	# Cordura en cero: Lalo se convierte en Eco
	j.cordura = 0.0; e.mente._process(0.016); await esperar()
	check(e.motivo_fin == "eco" and not e.jugando and e.interfaz.menu_actual == "muerte", "Cordura en cero convierte a Lalo en Eco")
	await e.aplicar_guardado(); await esperar()
	check(j.cordura >= 20.0 and e.jugando, "El punto seguro devuelve cordura mínima")
	print("RESULTADO: %d fallos"%fallos)
	e.queue_free(); await esperar(); quit(fallos)
