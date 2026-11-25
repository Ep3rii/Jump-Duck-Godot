# Jump Duck — versão Godot 4

Conversão do projeto GameMaker `Jump Duck` para **Godot 4.4+** (renderer Compatibility).
Abra a pasta no Godot (`project.godot`) e rode com F5. Na primeira abertura o editor importa
os PNGs e o MP3 sozinho.

## Controles (iguais ao original)

| Ação | Teclas |
|---|---|
| Mover | Setas ou A / D |
| Pular (pulo duplo) | Espaço |
| Pausar | Esc |
| Menus | Setas/W/S, Enter ou Espaço, mouse |

## Mapa GameMaker → Godot

| GameMaker | Godot |
|---|---|
| `obj_game_manager` (estado, menus, pontuação, ini) | `scripts/game.gd` (autoload `Game`) |
| `Draw_64` do manager (menus e HUD) | `scripts/ui.gd` (desenha em código, grade 320x180) |
| `obj_player` | `scenes/player.tscn` + `scripts/player.gd` |
| `obj_raposa` | `scenes/raposa.tscn` + `scripts/raposa.gd` |
| `obj_flor01` / `obj_efeito` | `scenes/flor.tscn` / `scenes/efeito.tscn` |
| `obj_blocoPiso01` | `scenes/block.tscn` (`tiles_w` / `tiles_h` = image_xscale/yscale) |
| `obj_camera` | `scripts/camera.gd` (Camera2D) |
| `obj_parallax` | `scripts/parallax.gd` |
| rooms `menu`, `tutorial_fase1` | `scenes/menu.tscn`, `scenes/tutorial_fase1.tscn` |
| sprites | `assets/sprites/*.png` (tiras horizontais) + `assets/frames/*.tres` (SpriteFrames) |
| tilemaps `Tiles_1` / `Tiles_2` | `scripts/tile_data.gd` → `TileMapLayer` montado em `level.gd` |
| `ini_*` (jump_duck_settings.ini) | `ConfigFile` em `user://jump_duck_settings.cfg` |

## Decisões da conversão

- **Física idêntica ao GameMaker.** O movimento foi portado passo a passo para `_physics_process`
  (60 Hz): gravidade 0.25, pulo -4, buffer de pulo, dano por queda de 96 px, pisão na raposa.
  A colisão usa retângulos (a máscara dos sprites no GameMaker) contra os blocos, em vez de
  `CharacterBody2D`, para manter a mesma sensação.
- **Ordem de desenho** (`depth` do GameMaker) virou `z_index = -depth` nos nós de cada camada.
- **Tile 0** do GameMaker é o tile "vazio" e não é desenhado (as células com índice 0 foram omitidas).
- A fonte pixel (`spr_fontPixel`, glifos 8x8) é desenhada diretamente, com a mesma ordem de glifos.
- O jogo abre em **tela cheia** por padrão, como no original (Configurações → TELA).
- `obj_blocoAgua01`, `obj_lago01`, `obj_piso01` e `obj_florVazia01` existem no GameMaker, mas não são
  usados em nenhuma sala, então não foram convertidos. A água da fase é só decoração (tiles).
- Sprites não usados (`spr_agua01Anima`, `spr_BBg01Anima`, `spr_voltar`, `spr_fechar`...) foram
  exportados para `assets/` caso queira usá-los.
