# GERADO a partir do projeto GameMaker (tamanho, origem e fps de cada sprite).
extends RefCounted

# nome: [largura, altura, n_frames, origem_x, origem_y, fps]
const META := {
	"spr_agua01Anima": [16, 16, 4, 0, 0, 4.0],
	"spr_bgMontanhas": [320, 72, 1, 0, 72, 1.0],
	"spr_bgNuvens": [192, 40, 1, 0, 0, 1.0],
	"spr_brilho": [16, 16, 5, 8, 8, 12.0],
	"spr_estrela": [16, 16, 2, 8, 8, 1.0],
	"spr_flor01": [16, 16, 4, 8, 14, 5.0],
	"spr_objBAgua01": [64, 64, 1, 0, 64, 3.0],
	"spr_objBPiso01": [16, 16, 1, 0, 16, 1.0],
	"spr_piso01": [16, 16, 1, 0, 16, 30.0],
	"spr_raposaAnda": [64, 64, 4, 32, 48, 6.0],
	"spr_tileSetGrama01": [64, 64, 1, 0, 0, 30.0],
	"spr_vidaCheia": [32, 32, 1, 16, 16, 30.0],
	"spr_vidaVazia": [32, 32, 1, 16, 16, 30.0],
}
