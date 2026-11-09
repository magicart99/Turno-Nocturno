extends Node
## Escenas narrativas y revisiones jugables. Las marcas viven en campana.hechos.
var escuela: Node2D
var texto: Label
var fondo: PanelContainer
var restante := 0.0
var espera := 6.0
var cola: Array[String] = []
var ultima_etapa := 0
const LINEAS_ETAPA := {
	2: ["DON CHUY, POR RADIO · Ya estás afuera. Mira el cielo: rojo, como si no quisiera amanecer. Ni un grillo… aquí el ruido viaja lejos.",
		"DON CHUY · Revisa la luz del andador y la toma de agua. La Prefecta cuida el segundo edificio; ella recuerda más que yo."],
	3: ["DON CHUY · La Prefecta te dejó pasar. A nadie lo deja pasar.",
		"DON CHUY · El de Talleres sigue con su maqueta a medio terminar. No agarres lo que no es tuyo: se enoja."],
	4: ["DON CHUY · Ya tienes el reporte. Él también lo sabe: ahora viene más rápido.",
		"DON CHUY · Pasa entre los autos sin rozarlos. Si suena una alarma, no te detengas hasta la caseta."],
}
const VOCES_ARCHIVERO := [
	"EL ARCHIVERO · …matrícula sin firma… baja por abandono…",
	"EL ARCHIVERO · Lista de asistencia. Falta uno. Siempre falta uno.",
	"EL ARCHIVERO · Nadie sale con pendientes.",
	"EL ARCHIVERO · Te escuché. Tu expediente hace el mismo ruido.",
	"EL ARCHIVERO · Sello. Fecha. Archivo. Silencio.",
]
const LINEAS_OBJETOS := {
	"Expediente de Lalo": "LALO · Mi foto, mi matrícula… y una firma de baja que nunca hice. La fecha es de hace seis años.",
	"Sello roto": "LALO · Un sello de Rectoría partido a la mitad. Dice «REVOCADO». Tal vez sirva para devolver lo que el Archivero se llevó.",
	"Termo de cafe": "LALO · Café frío. Me va a mantener despierto un rato más. Lo guardo para cuando lo necesite.",
	"Grapadora": "LALO · Si la lanzo lejos (Q / RB), el ruido lo llevará hacia otro lado.",
	"Extintor": "LALO · No lo va a lastimar… pero puede darme unos segundos.",
}

func _ready() -> void:
	escuela = get_parent()
	var capa := CanvasLayer.new()
	capa.layer = 19
	add_child(capa)
	fondo = PanelContainer.new()
	fondo.position = Vector2(350,493)
	fondo.size = Vector2(580,85)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(.015,.028,.04,.94)
	estilo.border_color = Color("789a9a")
	estilo.border_width_left = 3
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 12
	fondo.add_theme_stylebox_override("panel",estilo)
	capa.add_child(fondo)
	texto = Label.new()
	texto.add_theme_font_override("font",preload("res://assets/fuentes/Barlow-Regular.ttf"))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(544,48)
	texto.add_theme_font_size_override("font_size",18)
	texto.add_theme_color_override("font_color",Color("d6e7df"))
	fondo.add_child(texto)
	fondo.hide()

func decir(linea: String) -> void:
	cola.append(linea)

func _process(delta: float) -> void:
	fondo.visible = escuela.jugando and restante > 0
	if not escuela.jugando: return
	restante = maxf(0,restante-delta)
	espera -= delta
	if espera <= 0 and not escuela.campana.hechos.get("relato_despertar",false):
		escuela.campana.hechos["relato_despertar"] = true
		decir("LALO · Me quedé dormido en la escuela. Las puertas están cerradas y mi expediente dice que desaparecí hace años.")
		decir("Una voz bajo la puerta · Busca tu expediente en Rectoría. Si el Archivero lo sella, tampoco recordarás cómo salir.")
	# La radio de Don Chuy acompaña cada cambio de nivel. La marca en hechos evita repetirla al cargar.
	var etapa: int = escuela.campana.etapa
	if etapa != ultima_etapa:
		ultima_etapa = etapa
		var marca := "relato_etapa_%d" % etapa
		if LINEAS_ETAPA.has(etapa) and not escuela.campana.hechos.get(marca, false):
			escuela.campana.hechos[marca] = true
			escuela.sonidos.efecto("radio_estatica", Vector2.INF, -16)
			for linea in LINEAS_ETAPA[etapa]: decir(linea)
	if restante <= 0 and not cola.is_empty():
		texto.text = cola.pop_front()
		restante = 7.0
		fondo.modulate.a=0
		create_tween().tween_property(fondo,"modulate:a",1.0,.35)
		fondo.show()

func revision(clave: String) -> bool:
	var c: Node = escuela.campana
	if c.hechos.get(clave,false): return false
	match clave:
		"revision_agua":
			escuela.interfaz.elegir("PATIO / TRES GOLPES", "Hay golpes dentro de la tubería. Entre el agua escuchas:\n«Cierra la entrada… no la salida».\nLa válvula roja alimenta la toma; la azul purga el conducto.", ["Cerrar la válvula roja y escuchar", "Abrir la purga azul", "Alejarse"], func(i: int):
				if i == 0:
					c.completar(clave,"Toma aislada. Los golpes se detuvieron.")
					escuela.sonidos.efecto("metal",Vector2.INF,-13)
					decir("LA DE CÓMPUTO, POR LA TUBERÍA · Nos encerraron aquí. La memoria está bajo la tierra del patio. No vuelvas sin ella.")
				elif i == 1:
					escuela.emitir_ruido(escuela.jugador.position,1.1)
					escuela.sonidos.efecto("metal",Vector2.INF,-8)
					decir("El golpe retumba por el patio. La entrada sigue abierta. Debo volver a la válvula roja.")
			)
			return true
		"revision_cafe":
			escuela.interfaz.elegir("CAFETERÍA / EL ÚLTIMO SERVICIO", "Una hornilla sigue encendida. Hay olor a gas.\nSobre la mesa alguien escribió: «Primero la llave. Después la luz».\nLa grabación menciona este local. La taza sigue caliente después de tantos años.", ["Cerrar el gas antes de apagar la hornilla", "Apagar solo la luz del local", "Volver"], func(i: int):
				if i == 0:
					c.completar(clave,"Gas aislado y hornilla apagada.")
					escuela.sonidos.efecto("rele",Vector2.INF,-10)
					decir("EL DE TALLERES, POR LA RADIO · Aquí empezó todo. Ahora revisa los baños y recoge el reporte: necesitamos que alguien lo lea fuera de esta escuela.")
				elif i == 1: decir("La llama sigue viva en la oscuridad. Falta cerrar el gas; la revisión no está terminada.")
			)
			return true
		"revision_banos":
			escuela.interfaz.elegir("SERVICIOS / OCUPADO", "Tres golpes salen del último cubículo.\nUna voz cuenta alumnos, pero nunca llega a tu nombre.\nEn la puerta: «No abras. Solo necesito que alguien responda».", ["Responder: te escucho, no estás solo", "Golpear la puerta", "Volver"], func(i: int):
				if i == 0:
					c.completar(clave,"La voz respondió. Servicios revisados.")
					escuela.sonidos.efecto("murmullo",Vector2.INF,-15)
					decir("ECO · En el reporte escribe que seguimos aquí. No pongas «sin novedades» otra vez.")
				elif i == 1:
					escuela.emitir_ruido(escuela.jugador.position,1.2)
					escuela.sonidos.efecto("puerta",Vector2.INF,-8)
					decir("La puerta te devuelve el golpe. Alguien empezó a caminar del otro lado.")
			)
			return true
	return false

func recuerdo(clave: String) -> void:
	var marca := "relato_" + clave
	if escuela.campana.hechos.get(marca,false): return
	escuela.campana.hechos[marca] = true
	var lineas := {
		"radio": "DON CHUY · No eres el primero que despierta aquí. Yo no tengo expediente de alumno; por eso no puede llevarme. Tú necesitas cerrar tu turno.",
		"memoria_banca": "LA PREFECTA, EN EL PAPEL · Yo firmaba las bajas. Decían «abandono». Ahora recuerdo sus caras… ninguno pudo salir.",
		"archivo_enterrado": "LALO · La USB está fría y tiene tierra dentro del conector. Hay algo grabado. La Prefecta debe verla.",
		"autorizacion": "LA PREFECTA · Yo firmé que todos habían salido. Mentí. Lleva la USB al de Talleres, en oficinas; él puede salvar la grabación.",
		"reporte": "LALO · No son objetos perdidos. Son personas. El Sello Roto puede devolverles su nombre… si llego a la caseta sin olvidarme del mío.",
		"computo": "LA DE CÓMPUTO · Gracias. Ya no tengo que verlo otra vez. Toma la pala del Taller y busca la USB en el patio."
	}
	if lineas.has(clave):
		escuela.sonidos.efecto("radio_estatica" if clave == "radio" else "papeles",Vector2.INF,-15)
		decir(lineas[clave])
	if clave == "archivo_enterrado":
		decir("ARCHIVO 001, ENVUELTO CON LA USB · «Primera baja sin firma. El archivo aprendió a archivar solo.» Al reverso, a lápiz: «El sello que lo rompe sigue en Rectoría».")

func voz_archivero() -> void:
	if cola.size() < 2:
		decir(VOCES_ARCHIVERO[randi() % VOCES_ARCHIVERO.size()])

func objeto_recogido(titulo: String) -> void:
	var marca := "relato_objeto_" + titulo
	if not LINEAS_OBJETOS.has(titulo) or escuela.campana.hechos.get(marca, false): return
	escuela.campana.hechos[marca] = true
	decir(LINEAS_OBJETOS[titulo])
