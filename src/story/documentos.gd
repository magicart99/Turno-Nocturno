extends Node
## Coloca los documentos ambientales en un punto libre de cada sala (sin tocar las escenas).
## Los del campus aparecen cuando el exterior se carga por primera vez.
const Geo = preload("res://src/world/geometria_campus.gd")
const DOCUMENTOS := [
	[1, "Direccion", "CORREO DE DIRECCIÓN · 23:58", "Asunto: cierre de cuatrimestre.\nFavor de no dejar pendientes abiertos. Los alumnos que no cierren su trámite antes de las 00:00 serán dados de baja automáticamente por el sistema de archivo.\n— Dirección"],
	[2, "Aula_01", "LISTA DE ASISTENCIA · 9-B", "32 alumnos. Alguien tachó un nombre tantas veces que rompió el papel.\nAl margen, con otra letra:\n«Lalo: presente. Lalo: presente. Lalo: presente.»"],
	[3, "Computo", "CHAT IMPRESO · 03:12", "—¿Ya entregaste?\n—No me deja subir el archivo.\n—Sal ya, cierran a las 12.\n—Una vez más. Solo una vez más.\n[Mensaje no enviado]"],
	[4, "Taller", "RÚBRICA · PROYECTO FINAL", "Maqueta del campus. Avance: 90 %.\nEstado: NO ENTREGADO.\nObservación del profesor: «Le falta la caseta. Sin caseta no hay salida.»"],
	[5, "Rectoria_Archivo", "ACTA DE BAJA", "Alumno: Lalo.\nMotivo: abandono.\nFecha: hace seis años.\nFirma del alumno: es tu letra. La tinta todavía está húmeda."],
	[6, "Entrada", "BITÁCORA DE VIGILANCIA", "Noche 1: sin novedades.\nNoche 2: sin novedades.\n…\nNoche 2,190: sin novedades.\n— D. Chuy\n\nDebajo, más débil: «Ya no sé cuántas veces le he levantado la pluma al mismo muchacho.»"],
	[7, "Bano_M", "NOTA EN EL ESPEJO", "«Si lees esto, ya te escuchó.\nNo corras. Él sigue los pasos, no los nombres.\nY no te escondas dos veces en el mismo lugar.»"],
	[8, "Auditorio", "PROGRAMA DE GRADUACIÓN", "Ceremonia de egreso · Generación del último cuatrimestre.\nLa lista de graduados está en blanco.\nAlguien escribió a lápiz en la última línea: «Nosotros también».", ],
	[9, "patio", "REPORTE DE LA PREFECTA", "Firmé 31 bajas en una sola noche. Me dijeron que era el procedimiento.\nNinguno vino a recoger sus papeles.\nTodos siguen aquí."],
	[10, "estacionamiento", "TICKET DE ESTACIONAMIENTO", "Entrada: 23:41.\nSalida: sin registrar.\nTarifa acumulada: seis años.\nEn el reverso: «Te espero en la caseta. — Mamá»"],
]
const FLASHBACK: Array[String] = [
	"Seis años antes · 23:58.",
	"Lalo se quedó dormido en la recepción de Dirección, esperando su último trámite.",
	"A las 00:00 el sistema de archivo cerró todos los expedientes abiertos. El suyo también.",
	"Don Chuy intentó despertarlo. Cuando volvió con el reporte, la pluma ya no quiso subir.",
	"Desde entonces, cada noche, Lalo vuelve a despertar en la misma silla.",
]
var escuela: Node2D
var principal_listo := false
var campus_listo := false

func _ready() -> void:
	escuela = get_parent()

func _process(_delta: float) -> void:
	if escuela.campana.cambiando:
		return
	# Cada lugar se coloca solo cuando sus colisiones están activas.
	if not principal_listo and escuela.archivero.lista and escuela.campana.lugar == "principal":
		principal_listo = true
		colocar_principal()
	if not campus_listo and is_instance_valid(escuela.campana.exterior) and escuela.campana.lugar == "campus":
		campus_listo = true
		colocar_campus()

func crear(dato: Array, padre: Node, posicion: Vector2) -> void:
	var doc := preload("res://src/story/documento.gd").new()
	doc.name = "Documento%d" % dato[0]
	doc.numero = dato[0]
	doc.encabezado = dato[2]
	doc.texto = dato[3]
	padre.add_child(doc)
	doc.global_position = posicion

func colocar_principal() -> void:
	var pisos: Node = escuela.get_node("Pisos")
	for dato in DOCUMENTOS:
		var sala := pisos.get_node_or_null(NodePath(str(dato[1]))) as Sprite2D
		if sala == null:
			continue
		var rect := Rect2(sala.global_position, sala.region_rect.size * sala.scale)
		var lugar = punto_libre(rect.get_center(), rect.grow(-40.0))
		if lugar != null:
			crear(dato, escuela.get_node("Objetos"), lugar)

func colocar_campus() -> void:
	var centros := {"patio": Geo.PATRULLA[1], "estacionamiento": Geo.PARKING}
	for dato in DOCUMENTOS:
		if not centros.has(dato[1]):
			continue
		var centro: Vector2 = centros[dato[1]]
		var lugar = punto_libre(centro + Vector2(60, 30), Rect2(centro - Vector2(160, 160), Vector2(320, 320)))
		if lugar != null:
			crear(dato, escuela.campana.exterior, lugar)

func punto_libre(centro: Vector2, limites: Rect2) -> Variant:
	# Recorre una espiral desde el centro hasta encontrar suelo sin colisiones.
	var espacio := escuela.get_world_2d().direct_space_state
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 16.0
	consulta.shape = forma
	consulta.collision_mask = 1
	for radio in range(0, 200, 24):
		var vueltas: int = maxi(1, int(radio / 6.0))
		for paso in range(vueltas):
			var p: Vector2 = centro + Vector2.from_angle(TAU * paso / float(vueltas)) * radio
			if not limites.has_point(p):
				continue
			consulta.transform = Transform2D(0, p)
			if espacio.intersect_shape(consulta, 1).is_empty():
				return p
	return null
