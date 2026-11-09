extends Node
## Acciones centralizadas: cambia aquí las teclas o botones del prototipo.
var mando: int = -1
var usando_mando: bool = false
var vibracion: bool = true
var volumen: float = 0.7
var ruta_opciones: String = "res://partidas/opciones.cfg"
## Recompensas persistentes entre partidas: atuendo elegido y atuendos desbloqueados.
var atuendo: int = 0
var desbloqueados: Array = [0]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("standalone") and not OS.has_feature("editor"):
		ruta_opciones = "user://partidas/opciones.cfg"
	var opciones := ConfigFile.new()
	if opciones.load(ruta_opciones) == OK:
		var sonido: Variant = opciones.get_value("audio", "volumen", 0.7)
		var vibrar: Variant = opciones.get_value("mando", "vibracion", true)
		if sonido is float or sonido is int:
			volumen = clampf(float(sonido), 0.0, 1.0)
		if vibrar is bool:
			vibracion = vibrar
		var guardados: Variant = opciones.get_value("recompensas", "desbloqueados", [0])
		if guardados is Array:
			desbloqueados = [0]
			for i in guardados:
				if (i is int or i is float) and int(i) >= 0 and int(i) < 4 and not desbloqueados.has(int(i)):
					desbloqueados.append(int(i))
		var elegido: Variant = opciones.get_value("recompensas", "atuendo", 0)
		if (elegido is int or elegido is float) and desbloqueados.has(int(elegido)):
			atuendo = int(elegido)
	var teclas := {"izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT], "arriba": [KEY_W, KEY_UP], "abajo": [KEY_S, KEY_DOWN], "interactuar": [KEY_E], "linterna": [KEY_F], "correr": [KEY_SHIFT], "pausa": [KEY_ESCAPE], "guardar": [KEY_F5], "distraer": [KEY_Q], "mapa": [KEY_TAB, KEY_M], "agacharse": [KEY_C, KEY_CTRL], "minimapa": [KEY_V], "inventario": [KEY_I]}
	for accion in teclas:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.34)
		for tecla in teclas[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			InputMap.action_add_event(accion, evento)
	# Device -1 acepta mandos conectados después de iniciar, incluso si no son el ID 0.
	var botones := {"interactuar": JOY_BUTTON_A, "linterna": JOY_BUTTON_X, "correr": JOY_BUTTON_LEFT_SHOULDER, "pausa": JOY_BUTTON_START, "inventario": JOY_BUTTON_Y, "distraer": JOY_BUTTON_RIGHT_SHOULDER, "mapa": JOY_BUTTON_BACK, "agacharse": JOY_BUTTON_B}
	for accion in botones:
		var evento := InputEventJoypadButton.new()
		evento.device = -1
		evento.button_index = botones[accion]
		InputMap.action_add_event(accion, evento)
	for entrada in [["izquierda", JOY_AXIS_LEFT_X, -1.0], ["derecha", JOY_AXIS_LEFT_X, 1.0], ["arriba", JOY_AXIS_LEFT_Y, -1.0], ["abajo", JOY_AXIS_LEFT_Y, 1.0]]:
		var evento := InputEventJoypadMotion.new()
		evento.device = -1
		evento.axis = entrada[1]
		evento.axis_value = entrada[2]
		InputMap.action_add_event(entrada[0], evento)
	var gatillo := InputEventJoypadMotion.new()
	gatillo.device = -1
	gatillo.axis = JOY_AXIS_TRIGGER_LEFT
	gatillo.axis_value = 1.0
	InputMap.action_set_deadzone("minimapa", 0.65)
	InputMap.action_add_event("minimapa", gatillo)
	var gatillo_derecho := gatillo.duplicate() as InputEventJoypadMotion
	gatillo_derecho.axis = JOY_AXIS_TRIGGER_RIGHT
	InputMap.action_add_event("minimapa", gatillo_derecho)
	# Menús y diálogos comparten el mismo contrato que las acciones del juego.
	for accion in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
		for evento in InputMap.action_get_events(accion):
			if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
				InputMap.action_erase_event(accion, evento)
	for entrada in [["ui_accept",JOY_BUTTON_A],["ui_cancel",JOY_BUTTON_B],["ui_up",JOY_BUTTON_DPAD_UP],["ui_down",JOY_BUTTON_DPAD_DOWN],["ui_left",JOY_BUTTON_DPAD_LEFT],["ui_right",JOY_BUTTON_DPAD_RIGHT]]:
		var evento := InputEventJoypadButton.new()
		evento.device = -1
		evento.button_index = entrada[1]
		InputMap.action_add_event(entrada[0], evento)
	for entrada in [["ui_left",JOY_AXIS_LEFT_X,-1.0],["ui_right",JOY_AXIS_LEFT_X,1.0],["ui_up",JOY_AXIS_LEFT_Y,-1.0],["ui_down",JOY_AXIS_LEFT_Y,1.0]]:
		var evento := InputEventJoypadMotion.new()
		evento.device = -1
		evento.axis = entrada[1]
		evento.axis_value = entrada[2]
		InputMap.action_set_deadzone(entrada[0],0.35)
		InputMap.action_add_event(entrada[0],evento)
	Input.joy_connection_changed.connect(_conexion)
	for id in Input.get_connected_joypads():
		mando = id
		usando_mando = true
		break

func _conexion(id: int, conectado: bool) -> void:
	if conectado and mando == -1:
		mando = id
	elif not conectado and id == mando:
		for accion in ["izquierda","derecha","arriba","abajo","correr"]:
			Input.action_release(accion)
		mando = -1
		usando_mando = false
		for otro in Input.get_connected_joypads():
			mando = otro
			break

func _input(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton or (evento is InputEventJoypadMotion and abs(evento.axis_value) > 0.34):
		usando_mando = true
		mando = evento.device
	elif evento is InputEventKey or evento is InputEventMouseButton or (evento is InputEventMouseMotion and evento.relative.length() > 2):
		usando_mando = false

func vibrar(fuerza: float, duracion: float = 0.12) -> void:
	if vibracion and mando >= 0:
		Input.start_joy_vibration(mando, fuerza * 0.5, fuerza, duracion)

func detener() -> void:
	for id in Input.get_connected_joypads():
		Input.stop_joy_vibration(id)

func guardar_opciones() -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ruta_opciones.get_base_dir())) != OK:
		return false
	var opciones := ConfigFile.new()
	opciones.set_value("audio", "volumen", volumen)
	opciones.set_value("mando", "vibracion", vibracion)
	opciones.set_value("recompensas", "desbloqueados", desbloqueados)
	opciones.set_value("recompensas", "atuendo", atuendo)
	return opciones.save(ruta_opciones) == OK

func desbloquear(indice: int) -> bool:
	# Devuelve true solo la primera vez, para anunciar la recompensa.
	if desbloqueados.has(indice):
		return false
	desbloqueados.append(indice)
	guardar_opciones()
	return true

func boton_interaccion() -> String:
	if not usando_mando:
		return "E"
	var nombre := Input.get_joy_name(mando).to_lower()
	return "Cruz" if "playstation" in nombre or "dual" in nombre or "sony" in nombre or "ps" in nombre else "A"
