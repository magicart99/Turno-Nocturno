extends RefCounted
## Atuendos cosméticos (plan de trabajo, semana 9): cambian el color de la sudadera de Lalo
## con un shader que solo toca los tonos azules del sprite original.
## [nombre, tono (−1 = original), saturación, condición para desbloquear]
const ATUENDOS := [
	["Azul UT (original)", -1.0, 1.0, "Disponible desde el inicio"],
	["Guinda", 0.97, 1.1, "Termina el juego con el final de escape"],
	["Verde UT", 0.38, 0.95, "Consigue el final alternativo (Sello Roto)"],
	["Gris ceniza", 0.6, 0.0, "Lee los diez documentos del campus"],
]

static func material(indice: int) -> ShaderMaterial:
	var sombreado := Shader.new()
	sombreado.code = """shader_type canvas_item;
uniform float tono = -1.0;
uniform float saturacion = 1.0;
vec3 a_hsv(vec3 c){
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1.0e-10)), d / (q.x + 1.0e-10), q.x);
}
vec3 a_rgb(vec3 c){
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
void fragment(){
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (tono >= 0.0) {
		vec3 h = a_hsv(c.rgb);
		// Solo la sudadera: azules con saturación suficiente.
		if (h.x > 0.55 && h.x < 0.73 && h.y > 0.25 && h.z > 0.06) {
			h.x = tono;
			h.y = clamp(h.y * saturacion, 0.0, 1.0);
			c.rgb = a_rgb(h);
		}
	}
	COLOR = c;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sombreado
	var dato: Array = ATUENDOS[clampi(indice, 0, ATUENDOS.size() - 1)]
	mat.set_shader_parameter("tono", dato[1])
	mat.set_shader_parameter("saturacion", dato[2])
	return mat
