extends CanvasLayer
## Secuencia de texto a pantalla completa: introducción, finales y conversión en Eco.
## Interactuar / aceptar / clic avanza; Esc / B / Start la omite. Emite `terminada`.
signal terminada

var lineas: Array[String] = []
var amanecer: bool = false
var raiz: Control
var cielo: ColorRect
var texto: Label
var indice: int = -1
var visibles: float = 0.0
var espera: float = 0.0
var cerrando: bool = false
var reloj: float = 0.0
const VELOCIDAD := 40.0
const PAUSA_LINEA := 2.8
const FUENTE = preload("res://assets/fuentes/Barlow-Regular.ttf")

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(negro)
	cielo = ColorRect.new()
	cielo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cielo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombreado := Shader.new()
	# Amanecer: sube desde el horizonte. Sin amanecer, solo grano y viñeta sobre negro.
	sombreado.code = """shader_type canvas_item;
uniform float progreso = 0.0;
uniform float amanecer = 0.0;
void fragment(){
	float h = 1.0 - UV.y;
	vec3 alba = mix(vec3(0.92,0.45,0.20), vec3(0.10,0.12,0.26), smoothstep(0.0,0.8,h));
	float sol = smoothstep(0.42,0.0,length((UV-vec2(0.5,1.08))*vec2(1.0,1.7)));
	alba += vec3(1.0,0.78,0.45)*sol*0.55;
	float grano = fract(sin(dot(floor(FRAGCOORD.xy*0.5)+floor(TIME*12.0),vec2(12.9898,78.233)))*43758.5453);
	float vineta = smoothstep(0.25,0.85,length(UV-vec2(0.5)));
	vec3 c = alba*progreso*amanecer;
	c = c*(1.0-vineta*0.6) + vec3(grano*0.035);
	COLOR = vec4(c, 1.0);
}"""
	var material_cielo := ShaderMaterial.new()
	material_cielo.shader = sombreado
	material_cielo.set_shader_parameter("amanecer", 1.0 if amanecer else 0.0)
	cielo.material = material_cielo
	raiz.add_child(cielo)
	texto = Label.new()
	texto.position = Vector2(190, 260)
	texto.size = Vector2(900, 200)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_override("font", FUENTE)
	texto.add_theme_font_size_override("font_size", 27)
	texto.add_theme_color_override("font_color", Color("e3e9e4"))
	texto.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	texto.add_theme_constant_override("shadow_offset_y", 3)
	raiz.add_child(texto)
	var pista := Label.new()
	pista.position = Vector2(0, 662)
	pista.size = Vector2(1280, 30)
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pista.add_theme_font_override("font", FUENTE)
	pista.add_theme_font_size_override("font_size", 14)
	pista.add_theme_color_override("font_color", Color(0.6, 0.66, 0.66, 0.7))
	pista.text = "E / A / clic · continuar      Esc / B · omitir"
	raiz.add_child(pista)
	var foco := get_viewport().gui_get_focus_owner()
	if foco: foco.release_focus()
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, 0.6)
	siguiente()

func siguiente() -> void:
	indice += 1
	if indice >= lineas.size():
		terminar()
		return
	texto.text = lineas[indice]
	texto.visible_characters = 0
	visibles = 0.0
	espera = 0.0
	var escuela := get_parent()
	if escuela != null and escuela.get("sonidos") != null:
		escuela.sonidos.efecto("papel", Vector2.INF, -24)
	if amanecer:
		var t := create_tween()
		t.tween_property(cielo.material, "shader_parameter/progreso", float(indice + 1) / lineas.size(), 2.2)

func _process(delta: float) -> void:
	reloj += delta
	if cerrando or indice < 0 or indice >= lineas.size():
		return
	# Temblor leve, como una señal que no termina de sintonizar.
	texto.modulate.a = 0.92 + 0.08 * sin(reloj * 23.0) * sin(reloj * 7.0)
	var total := texto.get_total_character_count()
	if visibles < total:
		visibles = minf(total, visibles + VELOCIDAD * delta)
		texto.visible_characters = int(visibles)
	else:
		espera += delta
		if espera >= PAUSA_LINEA:
			siguiente()

func _input(evento: InputEvent) -> void:
	if cerrando or evento.is_echo():
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		terminar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("interactuar") or evento.is_action_pressed("ui_accept") or (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT):
		if visibles < texto.get_total_character_count():
			visibles = texto.get_total_character_count()
			texto.visible_characters = -1
		else:
			siguiente()
		get_viewport().set_input_as_handled()

func terminar() -> void:
	if cerrando:
		return
	cerrando = true
	terminada.emit()
	var t := create_tween()
	t.tween_property(raiz, "modulate:a", 0.0, 0.9)
	t.tween_callback(queue_free)
