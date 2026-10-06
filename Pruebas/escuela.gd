extends Node2D

var estado: int = 0
var mapa: bool = false
var zonas: Dictionary = {}
@onready var jugador: CharacterBody2D = $Jugador
@onready var texto: Label = $Interfaz/Texto

func _ready() -> void:
	add_to_group("control")
	for nombre in ["izquierda", "derecha", "arriba", "abajo", "interactuar", "linterna", "correr", "luces", "mapa"]:
		if not InputMap.has_action(nombre):
			InputMap.add_action(nombre)
	var teclas := {"izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT], "arriba": [KEY_W, KEY_UP], "abajo": [KEY_S, KEY_DOWN], "interactuar": [KEY_E], "linterna": [KEY_F], "correr": [KEY_SHIFT], "luces": [KEY_L], "mapa": [KEY_M]}
	for accion in teclas:
		for tecla in teclas[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			InputMap.action_add_event(accion, evento)
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		zonas[luz.get_meta("zona")] = true
		luz.set_meta("energia_base", luz.energy)
	modo_luz(0)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("luces"):
		modo_luz((estado + 1) % 3)
	if Input.is_action_just_pressed("mapa"):
		mapa = not mapa
		$VistaGeneral.enabled = mapa
		$Jugador/Camera2D.enabled = not mapa
	var cercano: Node2D = jugador.mas_cercano()
	var ayuda: String = "E: " + cercano.titulo if is_instance_valid(cercano) else ""
	texto.text = "TURNO NOCTURNO | ESCUELA MODULAR\nWASD / Flechas: caminar   Shift: correr   E: interactuar / empujar\nF: linterna   Raton: apuntar   L: luz normal / apagon / mixta   M: plano\n" + ayuda + "\n" + jugador.mensaje + "\nInventario: " + str(jugador.inventario.size()) + " objetos | Ruido: " + str(snapped(jugador.ruido, 0.1))
	for luz in get_tree().get_nodes_in_group("parpadeo"):
		luz.energy = float(luz.get_meta("energia_base", 0.5)) * (0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.017))

func modo_luz(modo: int) -> void:
	estado = modo
	$Ambiente.color = Color(0.42, 0.47, 0.56) if modo == 0 else Color(0.065, 0.08, 0.13)
	for zona in zonas:
		zonas[zona] = modo == 0 or (modo == 2 and zona in ["Entrada", "Direccion", "Aula_01", "Aula_04", "Pasillo"])
	actualizar_luces()

func alternar_zona(zona: String) -> void:
	zonas[zona] = not zonas.get(zona, false)
	actualizar_luces()

func alternar_general() -> void:
	modo_luz(1 if estado == 0 else 0)

func actualizar_luces() -> void:
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		luz.enabled = zonas.get(luz.get_meta("zona"), false)
	for lampara in get_tree().get_nodes_in_group("lamparas"):
		var encendida: bool = zonas.get(lampara.get_meta("zona"), false)
		lampara.texture = load("res://assets/lampara_encendida.png" if encendida else "res://assets/lampara_apagada.png")
