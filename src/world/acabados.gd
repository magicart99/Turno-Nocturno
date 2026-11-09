extends RefCounted
## Acabados visuales que no alteran la jugabilidad:
## desgaste de suelos (manchas, humedad y grano) y sombras de muebles para la linterna.
const MASCARA_MUEBLES := 2
const MUEBLES := ["Fotocopiadora", "Estanteria", "Archivero mueble", "Sofa de espera", "Maqueta", "Escritorio"]
static func material_desgaste() -> ShaderMaterial:
	# Sin caché estática: el material vive con los nodos y se libera al cerrar.
	var sombreado := Shader.new()
	# El ruido usa coordenadas del mundo: cada baldosa repetida se ve distinta.
	sombreado.code = """shader_type canvas_item;
varying vec2 mundo;
uniform float brillo_piso = 0.0;
void vertex(){ mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
float azar(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment(){
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float manchas = smoothstep(0.55, 0.88, ruido(mundo * 0.006)) * 0.30;
	float humedad = smoothstep(0.62, 0.92, ruido(mundo * 0.013 + 17.0));
	float grano = (ruido(mundo * 0.35) - 0.5) * 0.07;
	vec3 r = c.rgb * (1.0 - manchas);
	r = mix(r, r * vec3(0.74, 0.84, 0.78), humedad * 0.45);
	r += grano;
	float gris = dot(r, vec3(0.299, 0.587, 0.114));
	r = mix(r, vec3(gris), 0.2);
	COLOR = vec4(r, c.a);
}
void light(){
	float d = length(LIGHT_POSITION.xy - LIGHT_VERTEX.xy);
	float brillo = pow(clamp(1.0 - d / 150.0, 0.0, 1.0), 6.0) * 0.5 * brillo_piso;
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY + LIGHT_COLOR.rgb * LIGHT_ENERGY * brillo, LIGHT_COLOR.a);
}"""
	var material := ShaderMaterial.new()
	material.shader = sombreado
	return material

static func desgastar_suelos(raiz: Node, brillo: float = 0.0) -> int:
	# Solo los suelos grandes con región repetida; muebles y paredes no cambian.
	var cantidad := 0
	if raiz == null:
		return cantidad
	var material := material_desgaste()
	# Brillo de vitropiso solo en el interior; pasto y asfalto quedan mates.
	material.set_shader_parameter("brillo_piso", brillo)
	for n in raiz.get_children():
		if n is Sprite2D and n.region_enabled and n.region_rect.size.x > 40 and n.region_rect.size.y > 40 and n.material == null:
			n.material = material
			cantidad += 1
	return cantidad

static func sombras_muebles(objetos: Node) -> int:
	# Huella del mueble como oclusor; solo la linterna y la luz de Lalo lo leen (máscara 2).
	var cantidad := 0
	for objeto in objetos.get_children():
		var titulo: Variant = objeto.get("titulo")
		var tipo: Variant = objeto.get("tipo")
		if titulo == null or objeto.has_node("SombraMueble"):
			continue
		if not (tipo == "escondite" or str(titulo) in MUEBLES):
			continue
		var colision := objeto.get_node_or_null("Colision") as CollisionShape2D
		if colision == null or not colision.shape is RectangleShape2D:
			continue
		var tam: Vector2 = (colision.shape as RectangleShape2D).size * 0.8
		var poligono := OccluderPolygon2D.new()
		poligono.polygon = PackedVector2Array([-tam * 0.5, Vector2(tam.x, -tam.y) * 0.5, tam * 0.5, Vector2(-tam.x, tam.y) * 0.5])
		var sombra := LightOccluder2D.new()
		sombra.name = "SombraMueble"
		sombra.occluder = poligono
		sombra.occluder_light_mask = MASCARA_MUEBLES
		sombra.position = colision.position
		objeto.add_child(sombra)
		cantidad += 1
	return cantidad
