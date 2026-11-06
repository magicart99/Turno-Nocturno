extends Node
const Geo = preload("res://src/world/geometria_campus.gd")
## Estado persistente de los cuatro niveles. La geometría no determina la misión.
var etapa: int = 1
var lugar: String = "principal"
var hechos: Dictionary = {}
var monedas: int = 0
var bateria: float = 100.0
var refresco: float = 0.0
var final_liberado: bool = false
var revision := ""
var revision_origen := Vector2.ZERO
var revision_tiempo := 0.0
var revision_lugar := ""
var puzzle: int = 0
var exterior: Node2D
var cambiando: bool = false
var explorados: Dictionary = {}
var gracia_patio: float = 25.0
var circuito: String = ""
var alimentado: String = "Entrada"
var tablero: CanvasLayer
@onready var escuela: Node2D = get_parent()

func gracia_activa() -> bool:
	return lugar == "campus" and etapa >= 2 and gracia_patio > 0.0

func elegir_circuito() -> void:
	abrir_tablero("Computo")

func reparar(zona: String) -> void:
	if alimentado == zona and escuela.zonas.get(zona,false):
		escuela.alimentar_zona("")
		escuela.jugador.mensaje = "Circuito desconectado. Usa la linterna."
		return
	abrir_tablero(zona)

func abrir_tablero(zona: String) -> void:
	if is_instance_valid(tablero): return
	circuito=zona
	escuela.interfaz.mostrar("electricidad")
	escuela.interfaz.panel.hide()
	escuela.interfaz.fondo.activar(false)
	escuela.sonidos.silenciar_ambiente(false)
	tablero=preload("res://src/ui/tablero_electrico.gd").new()
	tablero.escuela=escuela
	tablero.circuito=zona
	escuela.add_child(tablero)

func conectar_circuito(zona: String) -> void:
	hechos["electricidad_"+zona]=true
	escuela.alimentar_zona(zona)
	if zona == "Exterior_Andador": completar("revision_luz","Andador reparado.")
	escuela.sonidos.efecto("rele",Vector2.INF,-9)
	escuela.emitir_ruido(escuela.jugador.position,.7)
	escuela.jugador.mensaje="Alimentando: %s. Los otros circuitos están apagados."%zona.replace("_"," ")

func datos() -> Dictionary:
	return {"explorados": explorados.duplicate(), "etapa": etapa, "lugar": lugar, "hechos": hechos.duplicate(), "monedas": monedas, "bateria": bateria, "refresco": refresco, "final_liberado": final_liberado, "gracia_patio": gracia_patio, "mapa_version": Geo.VERSION, "alimentado": alimentado}

func restaurar(d: Dictionary) -> void:
	explorados = d.get("explorados", {}).duplicate() if d.get("explorados", {}) is Dictionary else {}
	alimentado = str(d.get("alimentado",""))
	if not d.has("alimentado"):
		for z in ["Computo","Rectoria_Archivo","Entrada"]:
			if escuela.zonas.get(z,false): alimentado=z; break
	etapa = int(d.get("etapa", 1))
	gracia_patio = clampf(float(d.get("gracia_patio", 25.0 if etapa <= 2 else 0.0)),0,25)
	hechos = d.get("hechos", {}).duplicate()
	# Migrar partidas previas sin exigir excavar otra vez ni bloquear finales.
	if etapa >= 4: hechos["talleres"] = true
	if hechos.get("archivo_enterrado", false):
		hechos["memoria_desenterrada"] = true
		if not hechos.get("talleres",false) and not escuela.jugador.inventario.has("Memoria USB del patio"):
			escuela.jugador.inventario.append("Memoria USB del patio")
	if hechos.get("memoria_banca",false) and not hechos.get("autorizacion",false) and not escuela.jugador.inventario.has("Nota de la banca"):
		escuela.jugador.inventario.append("Nota de la banca")
	monedas = int(d.get("monedas", 0))
	bateria = float(d.get("bateria", 100.0))
	refresco = float(d.get("refresco", 0.0))
	final_liberado = d.get("final_liberado", false)
	var posicion: Vector2 = escuela.jugador.position
	if d.get("lugar", "principal") == "campus" and int(d.get("mapa_version",3)) < Geo.VERSION:
		if int(d.get("mapa_version",3)) < 4: posicion = Geo.adaptar_antiguo(posicion)
		posicion = Geo.adaptar_v4(posicion)
	await cambiar_lugar(d.get("lugar", "principal"), posicion, false)
	escuela.alimentar_zona(alimentado)

func _process(delta: float) -> void:
	if not escuela.jugando or cambiando:
		return
	avanzar_revision(delta)
	if gracia_activa():
		var anterior: int = ceili(gracia_patio)
		gracia_patio = maxf(0, gracia_patio - delta)
		if anterior != ceili(gracia_patio) and gracia_patio > 0 and gracia_patio <= 10:
			escuela.sonidos.efecto("latido", Vector2.INF, -21)
		if gracia_patio <= 0:
			escuela.archivero.despertar()
			escuela.sonidos.efecto("grito", Vector2.INF, -16)
	refresco = maxf(0, refresco - delta)
	if escuela.jugador.linterna and escuela.jugador.get_node("Linterna").enabled and not escuela.jugador.oculto:
		bateria = maxf(0, bateria - delta * 0.12)
		if bateria <= 0:
			escuela.jugador.linterna = false
			escuela.jugador.mensaje = "Sin batería. Busca pilas o el cargador de la entrada."
	if lugar == "campus" and etapa >= 4 and hechos.get("reporte_entregado", false) and Geo.SALIDA.has_point(escuela.jugador.position):
		escuela.ganar()

func objetivo() -> String:
	match etapa:
		1:
			if not escuela.jugador.inventario.has("Llave maestra"): return "N1 · Busca la llave maestra en Dirección"
			if not escuela.jugador.inventario.has("Expediente de Lalo"):
				return "N1 · Recupera el expediente de Rectoría" if escuela.zonas.get("Rectoria_Archivo",false) else "N1 · Tablero de Entrada: alimenta Rectoría / Archivo"
			if not hechos.get("computo", false):
				return "N1 · Habla con la de Cómputo y apaga su monitor" if escuela.zonas.get("Computo",false) else "N1 · Tablero de Entrada: cambia la alimentación a Cómputo"
			if not hechos.get("radio", false) or not hechos.get("pala", false): return "N1 · Recoge radio en Entrada y pala en Taller"
			return "N1 · Registra tu salida en la bitácora de Entrada"
		2:
			if not hechos.get("revision_luz", false): return "N2 · Repara el tablero del andador, frente a la escuela"
			if not hechos.get("revision_agua", false): return "N2 · Revisa la toma de agua del patio"
			if not hechos.get("memoria_banca", false): return "N2 · Recoge la nota de la banca"
			if not hechos.get("archivo_enterrado", false): return "N2 · Recoge la memoria USB que salió de la tierra" if hechos.get("memoria_desenterrada", false) else "N2 · Excava la tierra removida del patio"
			return "N2 · Entrega la nota y la memoria USB a la Prefecta, frente al segundo edificio"
		3:
			if not hechos.get("talleres", false): return "N3 · Lleva la memoria USB al de Talleres, en oficinas"
			if not hechos.get("llave_servicio", false): return "N3 · Recoge la llave de servicio junto al de Talleres"
			if not hechos.get("revision_cafe", false): return "N3 · Revisa el local cerrado de cafetería"
			if not hechos.get("revision_banos", false): return "N3 · Revisa los baños del segundo edificio"
			return "N3 · Abre el archivo del mostrador y recoge el reporte"
		4:
			return "N4 · Cruza la pluma hacia el amanecer" if hechos.get("reporte_entregado", false) else "N4 · Lleva el reporte a Don Chuy en la caseta"
	return "Cierra tu turno"

func completar(clave: String, mensaje: String) -> String:
	if not hechos.get(clave, false):
		hechos[clave] = true
		escuela.sonidos.efecto("recoger")
		if is_instance_valid(escuela.relato): escuela.relato.recuerdo(clave)
	return mensaje

func interactuar(clave: String, _punto: Node2D = null) -> String:
	if cambiando: return "Cruzando el acceso…"
	if is_instance_valid(escuela.relato) and escuela.relato.revision(clave): return "Escucha antes de actuar."
	if clave.begins_with("moneda_"):
		if not hechos.get(clave, false): monedas += 1
		return completar(clave, "Moneda recogida. Cafetería: frituras $1 / refresco $1.")
	if clave.begins_with("pilas_"):
		if not hechos.get(clave, false): bateria = minf(100, bateria + 65)
		return completar(clave, "Pilas colocadas en la linterna.")
	match clave:
		"tablero_principal":
			elegir_circuito()
			return "Tablero principal: conecta una sola salida de alimentación."
		"radio": return completar(clave, "RADIO · Don Chuy: registra tu salida, revisa el campus y tráeme el reporte. Aquí te espero.")
		"pala": return completar(clave, "Pala de conserjería recogida. Hay tierra removida en el patio.")
		"cargador":
			bateria = 100
			return "Cargador de emergencia: batería al 100 %."
		"computo":
			if not escuela.zonas.get("Computo",false): return "Sin corriente en Cómputo. Conecta su circuito en el tablero de Entrada."
			if hechos.get("computo", false): return "La de Cómputo: busca mi memoria USB bajo la tierra removida del patio. Llévala a la Prefecta."
			puzzle = 0
			mostrar_puzzle()
			return "La de Cómputo señala el monitor. Escucha su historia."
		"bitacora", "salida_principal":
			if etapa >= 2:
				cambiar_lugar("campus", Geo.ENTRADA)
				return "Don Chuy: sigue el andador guindo entre la escuela y la cancha."
			if not escuela.jugador.inventario.has("Expediente de Lalo") or not hechos.get("computo", false) or not hechos.get("radio", false) or not hechos.get("pala", false):
				return "Faltan pendientes. " + objetivo()
			etapa = 2
			completar("bitacora", "Registro enviado.")
			cambiar_lugar("campus", Geo.ENTRADA)
			return "Salida registrada. El turno continúa afuera."
		"volver_principal":
			cambiar_lugar("principal", Vector2(2112, 1180))
			return "Edificio principal."
		"revision_luz":
			reparar("Exterior_Andador")
			return "Repara el circuito del andador. Los demás circuitos siguen separados."
		"luz_servicios":
			reparar("Exterior_Servicios")
			return "Tablero del segundo edificio."
		"luz_parking":
			reparar("Exterior_Parking")
			return "Tablero de estacionamiento."
		"revision_agua": return iniciar_revision(clave)
		"memoria_banca":
			if not hechos.get(clave, false): escuela.jugador.inventario.append("Nota de la banca")
			return completar(clave, "Nota recogida: cerraron la escuela con alumnos dentro. Llévala a la Prefecta junto con la memoria USB.")
		"archivo_enterrado":
			if not hechos.get("pala", false): return "Necesitas la pala de conserjería."
			if hechos.get(clave, false): return "Ya recogiste la memoria USB. Llévala a la Prefecta."
			if hechos.get("memoria_desenterrada", false):
				escuela.jugador.inventario.append("Memoria USB del patio")
				return completar(clave, "Memoria USB recogida. Entrégala a la Prefecta junto con la nota de la banca.")
			escuela.jugador.excavar(_punto)
			return "Excavando… los golpes de la pala pueden delatarte."
		"prefecta":
			for requisito in ["revision_luz", "revision_agua", "memoria_banca", "archivo_enterrado"]:
				if not hechos.get(requisito, false): return "La Prefecta: necesito la nota y la memoria USB. " + objetivo()
			if hechos.get("autorizacion", false): return "La Prefecta: el de Talleres te espera en oficinas. Él puede leer la memoria."
			escuela.jugador.inventario.erase("Nota de la banca")
			etapa = maxi(etapa, 3)
			actualizar_accesos()
			escuela.anunciar("NIVEL 3 · CAFETERÍA Y SERVICIOS", "La Prefecta reconoce la nota. Conserva la USB y llévala al de Talleres, en oficinas.")
			return completar("autorizacion", "La Prefecta: esa grabación prueba lo que pasó. El de Talleres puede recuperarla.")
		"acceso_segundo": return "La Prefecta debe autorizar el acceso." if etapa < 3 else "Acceso autorizado."
		"llave_servicio":
			if not hechos.get("talleres", false): return "El de Talleres guarda esta llave. Habla con él; está en oficinas."
			return completar(clave, "Llave recogida. Revisa cafetería y baños; luego abre el archivo del mostrador.")
		"revision_cafe": return iniciar_revision(clave)
		"revision_banos": return iniciar_revision(clave)
		"reporte":
			for requisito in ["talleres", "llave_servicio", "revision_cafe", "revision_banos"]:
				if not hechos.get(requisito, false): return "El reporte necesita llave y ambas revisiones. " + objetivo()
			etapa = 4
			actualizar_accesos()
			escuela.anunciar("NIVEL 4 · ESTACIONAMIENTO", "Don Chuy: ya abrí el acceso. Evita rozar los autos; sus alarmas lo llaman.")
			return completar(clave, "Reporte recogido. Entrégalo en la caseta.")
		"acceso_parking": return "Don Chuy abrirá este acceso cuando tengas el reporte."
		"tienda":
			escuela.abrir_tienda()
			return "Mostrador de cafetería."
		"talleres":
			if hechos.get("talleres", false): return "El de Talleres: la grabación está recuperada. Toma la llave y busca el reporte del mostrador."
			if not hechos.get("autorizacion", false): return "El de Talleres: lleva primero la memoria USB a la Prefecta. Ella reconocerá la grabación."
			escuela.interfaz.elegir("EL DE TALLERES / LA GRABACIÓN", "Yo escondí esa USB antes de que cerraran las puertas.\nSe oye a los alumnos pidiendo salir. El Archivero borró sus nombres, pero no sus voces.\nDéjame recuperarla. Mi llave abre el archivo de cafetería.", ["Entregar la USB y recuperar la grabación"], func(i: int):
				if i != 0: return
				escuela.jugador.inventario.erase("Memoria USB del patio")
				if not escuela.jugador.inventario.has("Grabación recuperada"): escuela.jugador.inventario.append("Grabación recuperada")
				completar("talleres", "Grabación recuperada. Recoge la llave junto al de Talleres.")
				escuela.anunciar("VOCES RECUPERADAS", "Toma la llave. El reporte permitirá a Don Chuy abrir la salida.")
			)
			return "El de Talleres conecta la memoria a su equipo."
		"guardia":
			if etapa < 4 or not hechos.get("reporte", false): return "Don Chuy: me falta tu reporte de cierre. No puedo levantar la pluma."
			if hechos.get("reporte_entregado", false): return "Don Chuy: ya cerraste tu turno. Cruza la salida."
			var opciones: Array[String] = ["Entregar reporte y salir"]
			if hechos.get("archivo_enterrado", false) and escuela.jugador.inventario.has("Sello roto") and escuela.jugador.cordura >= 50:
				opciones.append("Usar Sello Roto · liberar a los Ecos")
			opciones.append("Volver")
			escuela.interfaz.elegir("DON CHUY · VIGILANCIA", "Tu turno termina aquí. Tú decides qué pasa con los demás.", opciones, func(i: int):
				if i == opciones.size() - 1: return
				final_liberado = i == 1
				completar("reporte_entregado", "Don Chuy: salida registrada. Nos vemos al amanecer.")
				actualizar_accesos()
				escuela.sonidos.efecto("puerta")
				escuela.anunciar("TURNO CERRADO", "Cruza la pluma. Los Ecos también saldrán." if final_liberado else "Cruza la pluma hacia la calle.")
			)
			return "Don Chuy revisa el reporte."
		"salida_final": return "Cruza hacia la calle." if hechos.get("reporte_entregado", false) else "Entrega primero el reporte a Don Chuy."
	return ""

func mostrar_puzzle() -> void:
	escuela.interfaz.elegir("LA DE CÓMPUTO / NO ME DEJES AQUÍ", "Cuando cerraron la escuela, yo seguía en esta sala.\nCada noche el monitor vuelve a mostrar el momento en que desaparecí. Apágalo, por favor.\nEscondimos una memoria USB bajo la tierra removida del patio. Entrégasela a la Prefecta: contiene la prueba de que no salimos.", ["Apagar el monitor y ayudarla"], func(i: int):
		if i != 0 or hechos.get("computo", false): return
		completar("computo", "Monitor apagado. Recoge la radio y la pala; sal al patio por la bitácora.")
		escuela.sonidos.efecto("rele", Vector2.INF, -10)
		escuela.anunciar("EL MONITOR SE APAGA", "En el cristal queda una huella… por dentro. Busca la USB en el patio.")
	)

func comprar(i: int) -> void:
	if i == 3: return
	if i < 2 and monedas <= 0:
		escuela.jugador.mensaje = "No tienes monedas. Busca en bancos, escritorios y patio."
		return
	if i == 2:
		escuela.mente.presenciar(20)
		escuela.sonidos.efecto("grito", escuela.jugador.position, -14)
		escuela.emitir_ruido(escuela.jugador.position, 4)
		escuela.jugador.mensaje = "El de Talleres te delató. ¡Aléjate del mostrador!"
		return
	monedas -= 1
	if i == 0: escuela.jugador.cordura = minf(100, escuela.jugador.cordura + 30)
	else:
		refresco = 45
		escuela.jugador.energia = 100
	escuela.sonidos.efecto("recoger")

func actualizar_accesos() -> void:
	if not is_instance_valid(exterior): return
	for par in [["PuertaSegundo", etapa >= 3], ["RejaParking", etapa >= 4], ["PlumaSalida", hechos.get("reporte_entregado", false)]]:
		var puerta := exterior.get_node_or_null(par[0])
		if puerta:
			puerta.visible = not par[1]
			puerta.get_node("Colision").set_deferred("disabled", par[1])
	escuela.archivero.velocidad_busqueda = 116 if etapa == 4 else 98
	if final_liberado and not exterior.has_node("EcosLiberados"):
		var ecos := Node2D.new()
		ecos.name = "EcosLiberados"
		exterior.add_child(ecos)
		for i in range(3):
			var eco := Sprite2D.new()
			eco.texture = load("res://assets/sprites/eco_computo.png")
			eco.position = Vector2(2520-i*35,3590+i*45)
			eco.scale = Vector2.ONE * 0.3
			eco.modulate = Color(0.7,0.95,0.86,0.65)
			eco.z_index = 5
			ecos.add_child(eco)
			var salida := create_tween()
			salida.tween_property(eco,"position:x",3060.0,7.0+i)
			salida.parallel().tween_property(eco,"modulate:a",0.0,8.0+i)
	escuela.rutas_pendientes = true

func cambiar_lugar(destino: String, posicion: Vector2, anuncio: bool = true) -> void:
	cambiando = true
	var seguir: bool = escuela.jugando
	escuela.jugando = false
	escuela.jugador.cancelar_accion()
	escuela.jugador.oculto = false
	escuela.jugador.ultimo_escondite = null
	lugar = destino
	escuela.get_node("Ambiente").color = Color(0.075,0.095,0.13) if destino == "campus" else Color(0.045,0.06,0.09)
	if gracia_activa():
		escuela.archivero.activo = false
		escuela.archivero.hide()
	for nombre in ["Pisos", "Paredes", "Objetos", "Iluminacion", "Rotulos", "DetallesPrincipal"]:
		var nodo := escuela.get_node_or_null(nombre)
		if nodo:
			activar_colisiones(nodo, destino == "principal")
			nodo.visible = destino == "principal"
			nodo.process_mode = Node.PROCESS_MODE_INHERIT if destino == "principal" else Node.PROCESS_MODE_DISABLED
	if destino == "campus" and not is_instance_valid(exterior):
		exterior = load("res://scenes/campus.tscn").instantiate()
		exterior.add_child(preload("res://src/world/decoracion_v11.gd").new())
		escuela.add_child(exterior)
		preload("res://src/world/pared_v12.gd").renovar(exterior)
	if is_instance_valid(exterior):
		activar_colisiones(exterior, destino == "campus")
		exterior.visible = destino == "campus"
		exterior.process_mode = Node.PROCESS_MODE_INHERIT if destino == "campus" else Node.PROCESS_MODE_DISABLED
		actualizar_accesos()
	var camara: Camera2D = escuela.jugador.get_node("Camera2D")
	camara.limit_right = Geo.TAMANO.x if destino == "campus" else 3840
	camara.limit_bottom = Geo.TAMANO.y if destino == "campus" else 1344
	escuela.jugador.position = posicion
	camara.reset_smoothing()
	if anuncio:
		escuela.archivero.position = Geo.ARCHIVERO if destino == "campus" else Vector2(3264,670)
		escuela.archivero.destino = escuela.archivero.position
		escuela.archivero.memoria = 0
		escuela.archivero.estado = "PATRULLANDO" if escuela.archivero.activo else "DORMIDO"
	await get_tree().physics_frame
	await get_tree().physics_frame
	escuela.archivero.construir_rutas()
	escuela.rutas_pendientes = false
	cambiando = false
	escuela.jugando = seguir
	if anuncio:
		escuela.anunciar("NIVEL %d · %s" % [etapa, "CAMPUS" if destino == "campus" else "EDIFICIO PRINCIPAL"], objetivo())
		if gracia_activa():
			escuela.anunciar("EXPLORA ANTES DE QUE LLEGUE", "%d segundos para recolectar. Agáchate con C / B / Círculo para no hacer pasos." % ceili(gracia_patio))
		escuela.guardar_partida()

func iniciar_revision(clave: String) -> String:
	if hechos.get(clave,false): return "Inspección ya registrada."
	if revision != "": return "Hay una inspección en curso. Aléjate para cancelarla."
	revision = clave
	revision_origen = escuela.jugador.position
	revision_lugar = lugar
	revision_tiempo = 6.0
	escuela.emitir_ruido(revision_origen,0.7)
	return "INSPECCIÓN · permanece aquí 6 s. El cierre hace ruido; aléjate para cancelar."

func avanzar_revision(delta: float) -> void:
	if revision == "" or not escuela.jugando: return
	if lugar != revision_lugar or escuela.jugador.position.distance_to(revision_origen)>35 or escuela.jugador.oculto:
		revision = ""
		escuela.jugador.mensaje = "Inspección interrumpida. Tendrás que revisar de nuevo."
		return
	var antes := ceili(revision_tiempo)
	revision_tiempo = maxf(0,revision_tiempo-delta)
	escuela.jugador.mensaje = "INSPECCIÓN · %d s · escucha antes de terminar" % ceili(revision_tiempo)
	if antes != ceili(revision_tiempo):
		escuela.sonidos.efecto("metal",revision_origen,-23)
		escuela.emitir_ruido(revision_origen,0.35)
	if revision_tiempo <= 0:
		var clave := revision
		revision = ""
		escuela.jugador.mensaje = completar(clave,"Inspección registrada. Ahora debes regresar.")

func activar_colisiones(nodo: Node, activo: bool) -> void:
	if nodo is CollisionObject2D:
		if not activo and not nodo.has_meta("capas_inactivas"):
			nodo.set_meta("capas_inactivas", Vector2i(nodo.collision_layer, nodo.collision_mask))
			nodo.collision_layer = 0
			nodo.collision_mask = 0
		elif activo and nodo.has_meta("capas_inactivas"):
			var capas: Vector2i = nodo.get_meta("capas_inactivas")
			nodo.collision_layer = capas.x
			nodo.collision_mask = capas.y
			nodo.remove_meta("capas_inactivas")
	for hijo in nodo.get_children(): activar_colisiones(hijo, activo)
