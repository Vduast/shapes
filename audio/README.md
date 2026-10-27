# Audio

El juego **no necesita archivos de audio**: los efectos y la música se generan por código
(`scripts/sound_manager.gd`, autoload `Sound`). Esta carpeta es opcional y sirve para
**reemplazar** o **añadir** sonidos con tus propios archivos.

## Música en bucle

Pon un archivo en `audio/music/` con el nombre de la pista y se usará en vez de la
procedural, **en bucle automático** (no hace falta marcarlo al importar):

| Archivo | Suena en |
|---|---|
| `audio/music/menu.ogg` (o `.mp3` / `.wav`) | Menú principal y menú de niveles |
| `audio/music/game.ogg` | Durante la partida |

Cualquier otro nombre sirve para pistas nuevas: `Sound.play_music("jefe")` busca
`audio/music/jefe.ogg|mp3|wav`. También puedes pasar un `AudioStream` directo:
`Sound.play_music_stream(preload("res://mi_cancion.ogg"))`.

Se recomienda **OGG** (el WAV funciona pero pesa mucho). Para que el bucle no tenga un
"clic", la canción debería empezar y terminar en el mismo punto musical.

## Efectos

`audio/sfx/<nombre>.ogg|mp3|wav` reemplaza al efecto procedural con ese nombre. Los
nombres incluidos: `click`, `hover`, `locked`, `pick`, `drop`, `paint`, `eat`, `happy`,
`reject`, `levelup`, `pop`, `whoosh`, `sparkle`. Un nombre nuevo se usa igual:
`Sound.play("mi_efecto")`.
