extends RefCounted
## Efeitos em pixel (luz, sombra, brilho, desbotar): nada de degrade suave nem alfa continuo.
## - PALETA: a Endesga 32 (a mesma de tools/arte/pixelkit.py);
## - SOMBRA: o tom de sombra de cada cor da paleta, tirado da propria paleta (rampa);
## - bayer4(): matriz de Bayer 4x4 (dither ordenado), igual em GDScript e no shader (BAYER_GLSL);
## - material_sombra(): troca cada pixel da tela embaixo do desenho pelo seu tom de sombra da
##   paleta (as sombras projetadas: Sombras.gd);
## - material_dither(): o alfa do que se desenha vira pixel cheio ou vazio pelo padrao de Bayer
##   (desbotar por quadriculado, preso a grade de 1 px do jogo);
## - material_cortina(): o mesmo em blocos de 2x2 px (cortina/escurecimento de tela inteira, o
##   fade entre cenas): 16 degraus de blocos acesos, sem alfa continuo.

const PALETA := [
	"be4a2f", "d77643", "ead4aa", "e4a672", "b86f50", "733e39", "3e2731", "a22633",
	"e43b44", "f77622", "feae34", "fee761", "63c74d", "3e8948", "265c42", "193c3e",
	"124e89", "0099db", "2ce8f5", "ffffff", "c0cbdc", "8b9bb4", "5a6988", "3a4466",
	"262b44", "181425", "ff0044", "68386c", "b55088", "f6757a", "e8b796", "c28569"]
## Indice (em PALETA) do tom de sombra de cada cor: grama -> grama escura, terra -> terra
## escura, pedra -> pedra escura... o mais escuro (#181425) fica nele mesmo.
const SOMBRA := [
	5, 0, 3, 4, 5, 6, 25, 6,
	7, 0, 9, 10, 13, 14, 15, 25,
	23, 16, 17, 20, 21, 22, 23, 24,
	25, 25, 7, 24, 27, 28, 31, 4]

## Bayer 4x4 em GLSL: limiar 0..15/16 do pixel p (coordenadas em px do jogo). So usa os 2 bits
## baixos de x e y (nada de numero grande: preciso em qualquer ponto do mundo).
const BAYER_GLSL := """
float bayer4(vec2 p) {
	p = mod(floor(p), 4.0);
	vec2 h = floor(p * 0.5);
	vec2 l = p - 2.0 * h;
	return fract(h.x * 0.5 + h.y * 0.75) * 0.25 + fract(l.x * 0.5 + l.y * 0.75);
}
"""

const SHADER_SOMBRA := """
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform vec3 pal[32];
uniform vec3 escura[32];

void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	float melhor = 9.0;
	vec3 a = c;
	vec3 b = c;
	for (int i = 0; i < 32; i++) {
		vec3 d = c - pal[i];
		float e = dot(d, d);
		if (e < melhor) {
			melhor = e;
			a = pal[i];
			b = escura[i];
		}
	}
	vec3 res = b;
	if (melhor > 0.003) {
		// cor fora da paleta (tingida): escurece na mesma proporcao do tom de sombra
		vec3 lum = vec3(0.299, 0.587, 0.114);
		res = c * (dot(b, lum) / max(dot(a, lum), 0.02));
	}
	COLOR = vec4(res, 1.0);
}
"""

const SHADER_DITHER := """
shader_type canvas_item;
varying vec2 px;

//BAYER

void vertex() {
	px = VERTEX;
}

void fragment() {
	COLOR.a = COLOR.a > bayer4(px) ? 1.0 : 0.0;
}
"""

const SHADER_CORTINA := """
shader_type canvas_item;
varying vec2 px;

//BAYER

void vertex() {
	px = VERTEX;
}

void fragment() {
	COLOR.a = COLOR.a > bayer4(floor(px * 0.5)) ? 1.0 : 0.0;
}
"""

## Cor da cortina do fade entre cenas (o tom mais escuro da paleta).
const COR_CORTINA := Color("#181425")

static var _mat_sombra: ShaderMaterial
static var _mat_dither: ShaderMaterial
static var _mat_cortina: ShaderMaterial


## Limiar de Bayer 4x4 (0, 1/16 .. 15/16) do pixel (x, y): o mesmo valor do shader.
static func bayer4(x: int, y: int) -> float:
	var hx := posmod(x, 4) >> 1
	var hy := posmod(y, 4) >> 1
	var lx := posmod(x, 2)
	var ly := posmod(y, 2)
	return fposmod(hx * 0.5 + hy * 0.75, 1.0) * 0.25 + fposmod(lx * 0.5 + ly * 0.75, 1.0)


## Pixel (x, y) aceso para uma cobertura de 0..1 (dither ordenado)?
static func aceso(x: int, y: int, cobertura: float) -> bool:
	return cobertura > bayer4(x, y)


## Cor da paleta pelo indice.
static func cor(i: int) -> Color:
	return Color("#" + PALETA[i])


## Codigo de shader com a funcao bayer4() no lugar de //BAYER.
static func com_bayer(codigo: String) -> String:
	return codigo.replace("//BAYER", BAYER_GLSL)


static func material_sombra() -> ShaderMaterial:
	if _mat_sombra == null:
		var sh := Shader.new()
		sh.code = SHADER_SOMBRA
		_mat_sombra = ShaderMaterial.new()
		_mat_sombra.shader = sh
		var pal := PackedVector3Array()
		var esc := PackedVector3Array()
		for i in PALETA.size():
			var c := cor(i)
			var s := cor(SOMBRA[i])
			pal.append(Vector3(c.r, c.g, c.b))
			esc.append(Vector3(s.r, s.g, s.b))
		_mat_sombra.set_shader_parameter("pal", pal)
		_mat_sombra.set_shader_parameter("escura", esc)
	return _mat_sombra


static func material_dither() -> ShaderMaterial:
	if _mat_dither == null:
		var sh := Shader.new()
		sh.code = com_bayer(SHADER_DITHER)
		_mat_dither = ShaderMaterial.new()
		_mat_dither.shader = sh
	return _mat_dither


static func material_cortina() -> ShaderMaterial:
	if _mat_cortina == null:
		var sh := Shader.new()
		sh.code = com_bayer(SHADER_CORTINA)
		_mat_cortina = ShaderMaterial.new()
		_mat_cortina.shader = sh
	return _mat_cortina
