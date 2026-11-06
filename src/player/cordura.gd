extends Node
## Un punto cada diez segundos jugados, también con luz y en refugios.
var escuela: Node2D
var vision := 0.0
var inversion := 0.0
var espera := 55.0
var reloj_luz := 0.0
var a_oscuras := false
var pantalla: ColorRect
var tiempo_visual := 0.0
func _ready() -> void:
	escuela=get_parent()
	var capa := CanvasLayer.new();capa.layer=11;add_child(capa)
	pantalla=ColorRect.new();pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pantalla.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code='''shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensidad = 0.0;
uniform float reloj = 0.0;
void fragment(){
 vec2 uv=SCREEN_UV;
 float borde=smoothstep(0.15,0.7,length(uv-vec2(0.5)));
 uv.x+=sin(uv.y*43.0+reloj*1.7)*intensidad*intensidad*0.012*borde;
 vec3 c=texture(pantalla,clamp(uv,vec2(0.001),vec2(0.999))).rgb;
 float desplazamiento=intensidad*intensidad*0.004;
 c.r=texture(pantalla,clamp(uv+vec2(desplazamiento,0),vec2(0.001),vec2(0.999))).r;
 float gris=dot(c,vec3(0.299,0.587,0.114));
 c=mix(c,vec3(gris)*vec3(0.77,0.91,0.94),intensidad*0.55);
 c*=1.0-intensidad*0.025*(0.5+0.5*sin(uv.y*600.0));
 COLOR=vec4(c,1.0);
}'''
	var material_fx := ShaderMaterial.new();material_fx.shader=shader; pantalla.material=material_fx
	capa.add_child(pantalla);pantalla.hide()
func presenciar(segundos: float=20.0) -> void:
	vision=maxf(vision,segundos)
func luz_segura() -> bool:
	var j: CharacterBody2D=escuela.jugador
	if j.linterna and escuela.campana.bateria>0 and not j.oculto:return true
	for l in get_tree().get_nodes_in_group("luces_zona"):
		if not l.enabled or not l.is_visible_in_tree() or l.global_position.distance_to(j.global_position)>260:continue
		var rayo:=PhysicsRayQueryParameters2D.create(j.global_position+Vector2(0,-20),l.global_position,1,[j.get_rid(),escuela.archivero.get_rid()])
		if escuela.get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():return true
	return false
func avanzar(delta: float, _oscuridad: bool) -> void:
	if not escuela.jugando:return
	escuela.jugador.cordura=clampf(escuela.jugador.cordura - 0.1*delta,0,100)
	vision=maxf(0,vision-delta)
	inversion=maxf(0,inversion-delta)
	if escuela.jugador.oculto or escuela.jugador.accion!="":inversion=0
	espera-=delta
	if espera<=0:
		espera=randf_range(50,85)
		if escuela.jugador.cordura<99.9:
			escuela.sonidos.efecto("eco_%d"%randi_range(1,5),escuela.jugador.position+Vector2.from_angle(randf()*TAU)*140,-23)
		if escuela.jugador.cordura<30 and not escuela.jugador.oculto and escuela.jugador.accion=="" and escuela.peligro<.6:
			inversion=0.0
			escuela.jugador.mensaje="Las paredes respiran. Tus pasos no suenan solos."
func _process(delta: float) -> void:
	pantalla.visible=escuela.jugando and escuela.jugador.cordura<99.9
	if not escuela.jugando:return
	reloj_luz-=delta
	if reloj_luz<=0:
		reloj_luz=.25;a_oscuras=not luz_segura()
	avanzar(delta,a_oscuras)
	tiempo_visual+=delta
	pantalla.material.set_shader_parameter("intensidad",clampf((100-escuela.jugador.cordura)/100,0,1))
	pantalla.material.set_shader_parameter("reloj",tiempo_visual)
