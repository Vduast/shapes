# SHAPES

Juego educativo 2D para niños desarrollado con **Godot Engine 4.7 (GDScript)**. Un slime con un globo de pensamiento **pide una figura** (círculo, cuadrado, triángulo, estrella o corazón) y, según el nivel, también un **color**. El jugador arrastra la figura hasta el slime; en los niveles avanzados primero tiene que **pintarla con botes de pintura de colores primarios y mezclarlos** (rojo + amarillo = naranja, etc.). Todo el dibujo del juego es **procedural**: no hay una sola imagen, cada figura, el slime (**con ojos y boca que cambian de cara según lo que pasa**), los botes, el borrador, los globos, el menú y los efectos se dibujan con **shaders** (campos de distancia con signo, SDF) sobre `ColorRect`.

---

## Tabla de contenidos

1. [Descripción general](#descripción-general)
2. [Cómo se juega](#cómo-se-juega)
3. [Tecnología utilizada](#tecnología-utilizada)
4. [Estructura del proyecto](#estructura-del-proyecto)
5. [Configuración del proyecto (project.godot)](#configuración-del-proyecto-projectgodot)
6. [Arquitectura y flujo del juego](#arquitectura-y-flujo-del-juego)
7. [Sistema de colores y niveles (GameData)](#sistema-de-colores-y-niveles-gamedata)
8. [Documentación de scripts y funciones](#documentación-de-scripts-y-funciones)
   - [game_data.gd](#game_datagd)
   - [main.gd](#maingd)
   - [monster.gd](#monstergd)
   - [slime_face.gd](#slime_facegd)
   - [tutorial_ghost.gd](#tutorial_ghostgd)
   - [shape.gd](#shapegd)
   - [shape_tray.gd](#shape_traygd)
   - [paint_bucket.gd](#paint_bucketgd)
   - [color_palette.gd](#color_palettegd)
   - [eraser.gd](#erasergd)
   - [request_bubble.gd](#request_bubblegd)
   - [paint_burst.gd](#paint_burstgd)
   - [paint_drop.gd](#paint_dropgd)
   - [hud.gd](#hudgd)
   - [confirm_dialog.gd](#confirm_dialoggd)
   - [main_menu.gd](#main_menugd)
   - [menu_slime.gd](#menu_slimegd)
   - [cream_button.gd](#cream_buttongd)
   - [animated_title.gd](#animated_titlegd)
   - [level_select.gd](#level_selectgd)
   - [save_data.gd](#save_datagd)
   - [sound_manager.gd](#sound_managergd)
9. [Escenas: cómo funciona cada una](#escenas-cómo-funciona-cada-una)
10. [Shaders y efectos visuales](#shaders-y-efectos-visuales)
11. [Técnicas de animación usadas](#técnicas-de-animación-usadas)
12. [Cambios recientes y notas conocidas](#cambios-recientes-y-notas-conocidas)

---

## Descripción general

SHAPES es un juego de arrastrar y soltar con **once niveles** progresivos (formas, colores primarios, mezclas una por una, marrón y un nivel final sin fin), precedido por un **menú principal** animado:

- Un **slime** (`Monster`) en el centro de la pantalla muestra en un globo de pensamiento la figura (y el color) que quiere comer. Tiene **cara** (ojos y boca dibujados por shader) que cambia según lo que ocurre: se emociona cuando le acercas una figura, mastica y se pone feliz al comer, festeja al subir de nivel, se entristece si rechaza, se sorprende si lo tocan en el menú y se duerme si pasa mucho rato sin actividad. Parpadea y sigue el ratón con la mirada.
- Una **bandeja** (`ShapeTray`) en la parte inferior ofrece solo las figuras que pide el nivel actual (3 en el nivel 1, las 5 desde el nivel 2 y solo estrella y corazón en el nivel 9): al sacar una, la bandeja repone otra igual. Las figuras de la bandeja **reaccionan al pasar el ratón** (crecen, se menean y se iluminan).
- Una **paleta** (`Palette`) a la derecha con 3 botes de pintura (rojo, amarillo, azul) y un bote de "Limpiar". Se activa a partir del nivel 3.
- Un **borrador** (`Eraser`) a la izquierda para deshacerse de las figuras que sobran.
- Un **menú de niveles** (`level_select.tscn`) que se arma solo a partir de `GameData.STAGES` y un **guardado** (`SaveData`) del nivel más alto alcanzado: el botón *Jugar* pasa a *Continuar* y los niveles se desbloquean al llegar a ellos.
- **Sonido 100 % procedural** (`Sound`, autoload): efectos y música en bucle generados por código, con soporte para reemplazarlos o ampliarlos con tus propios archivos (ver [sound_manager.gd](#sound_managergd)).
- Una **mano fantasma** (`TutorialGhost`) que, al empezar cada nivel, muestra sin palabras cómo cumplir lo que pide el slime (ver [tutorial_ghost.gd](#tutorial_ghostgd)).
- Un **HUD** con el nivel, el progreso, el botón **Menú** (pide confirmación antes de salir) y un letrero grande que anuncia cada nivel nuevo.
- Mucho "juice" (sensación de gelatina): resortes que inclinan y estiran las figuras al moverlas, gotas de pintura que escurren, estallidos de chispas y un slime que respira, se agita y se aplasta al comer.

> **Nota de arquitectura:** el proyecto no usa texturas ni sprites. Cada `ColorRect` lleva un `ShaderMaterial` que calcula la forma con matemáticas en el fragmento. Los datos del juego (colores, niveles, peticiones) viven en una clase estática, `GameData`, que no es un nodo ni un autoload: se usa como `GameData.STAGES`, `GameData.mask_to_color(...)`, etc. desde cualquier script.

---

## Cómo se juega

| Nivel | Nombre | Qué pide el slime | Paleta | Aciertos para pasar |
|---|---|---|---|---|
| 1 | Formas | Solo la forma (círculo, cuadrado o triángulo), cualquier color | No | 5 |
| 2 | Nuevas formas | Las 5 formas (llegan la estrella y el corazón), cualquier color | No | 5 |
| 3 | Colores primarios | Forma (las 5) + color primario (rojo, amarillo o azul) | Sí | 6 |
| 4 | Naranja | Forma + naranja (rojo + amarillo) | Sí | 4 |
| 5 | Verde | Forma + verde (amarillo + azul) | Sí | 4 |
| 6 | Morado | Forma + morado (azul + rojo) | Sí | 4 |
| 7 | Solo Mezclas | Forma + naranja, verde o morado | Sí | 6 |
| 8 | Marrón | Forma + marrón (los tres primarios) | Sí | 4 |
| 9 | Estrellas y corazones | Solo estrella o corazón, en cualquiera de los 7 colores | Sí | 6 |
| 10 | ¡Todo junto! | Las 5 formas + primarios y mezclas (sin marrón) | Sí | 8 |
| 11 | Maestro de colores | Las 5 formas + los 7 colores, sin fin | Sí | ∞ (el HUD muestra ★ con los aciertos) |

1. Mira lo que pide el globo del slime y toma la figura de la bandeja (se ilumina y se menea al pasar el ratón por encima; el cursor cambia a manita).
2. Si pide un color: arrastra un **bote de pintura** sobre una figura suelta para pintarla (los colores se **mezclan**). El bote regresa solo a su lugar.
3. Arrastra la figura hasta el slime y suéltala encima. Si coincide, se la come y cambia de color; si no, la rechaza y la figura sale despedida.
4. Para borrar una figura o repintarla desde cero: suéltala sobre el **borrador**, o usa el bote **Limpiar** (vuelve la figura a blanco).
5. Las figuras sueltas desaparecen solas tras 45 s sin tocarlas (parpadean durante los últimos 6 s).
6. **Tutorial fantasma:** al empezar cada nivel aparece una mano translucida que repite 3 veces la jugada: toma la figura que pide el slime de la bandeja, la lleva a una "mesa" en el centro, la **pinta** arrastrando sobre ella los botes que hagan falta (la figura fantasma cambia de color, así se ve cómo se mezcla) y se la lleva al slime; una guía de puntitos marca el camino. Desaparece con el primer clic del jugador y vuelve a salir como ayuda si pasan 15 s sin hacer clic.
7. **Niveles y progreso:** el juego guarda el nivel más alto que alcanzas. En el menú, **Continuar** retoma ahí y **Niveles** abre una cuadrícula con todos los niveles: los ya alcanzados se pueden repetir (con ★ los superados, y el actual brilla) y los demás aparecen bloqueados. Los niveles nuevos que añadas a `GameData` aparecen solos. **Borrar progreso** (con confirmación) vuelve a empezar.
8. Para volver al menú, pulsa el botón **Menú** (abajo a la izquierda) o **Esc**: aparece una ventana de confirmación ("¿Volver al menú?") con **Sí, salir** y **Seguir jugando**. Esc o un clic fuera de la ventana también cancelan. Al salir se pierde el progreso (no hay guardado).

---

## Tecnología utilizada

| Componente | Detalle |
|---|---|
| Motor | Godot Engine 4.7 (renderer Forward+) |
| Lenguaje | GDScript |
| Dibujo | Shaders `canvas_item` sobre `ColorRect` (SDF analíticos: sin texturas ni sprites), incluida la cara del slime |
| Interacción | `Area2D` con `input_pickable` + detección de solapamientos (`get_overlapping_areas()`) |
| Animación | `Tween` + resortes subamortiguados calculados a mano en `_process` |
| Plugins de editor | `script-ide` (solo editor, no forma parte del juego) |
| Alcance | Sin red, sin audio y sin autoloads; el proyecto no incluye presets de exportación |

---

## Estructura del proyecto

```
shapes/
├── scenes/                  # Escenas (.tscn)
│   ├── main_menu.tscn       #   Menú principal (escena de arranque)
│   ├── level_select.tscn    #   Menú de niveles (tarjetas creadas desde GameData.STAGES)
│   ├── menu_slime.tscn      #   Slime del menú (cambia de color, te mira, reacciona)
│   ├── cream_button.tscn    #   Botón crema reutilizable (menú, HUD y diálogo)
│   ├── confirm_dialog.tscn  #   Ventana de confirmación (¿Volver al menú?)
│   ├── tutorial_ghost.tscn  #   Mano fantasma del tutorial (figura y bote fantasma incluidos)
│   ├── main.tscn            #   Escena del juego: ensambla todo
│   ├── background.tscn      #   Fondo animado (ColorRect + shader)
│   ├── monster.tscn         #   Slime que pide y come figuras
│   ├── request_bubble.tscn  #   Globo de pensamiento con la figura pedida
│   ├── shape.tscn           #   Figura arrastrable (plantilla de la bandeja y figuras sueltas)
│   ├── shape_tray.tscn      #   Bandeja que ofrece y repone las figuras del nivel
│   ├── color_palette.tscn   #   Tabla de pintor con los 4 botes
│   ├── paint_bucket.tscn    #   Bote de pintura individual
│   ├── eraser.tscn          #   Borrador
│   ├── hud.tscn             #   Interfaz (nivel, progreso, botón Menú, diálogo)
│   ├── paint_burst.tscn     #   Efecto: anillo + chispas
│   └── paint_drop.tscn      #   Efecto: gota de pintura
├── scripts/                 # Lógica en GDScript (un .gd por escena + game_data.gd, slime_face.gd, save_data.gd y sound_manager.gd)
├── shaders/                 # 13 shaders .gdshader (todo el arte del juego)
├── audio/                   # (opcional) tus propios sonidos y música; ver audio/README.md
├── addons/script-ide/       # Plugin de editor (no afecta al juego)
├── icon.svg
└── project.godot            # Configuración del proyecto
```

> Los archivos `*.uid` que acompañan a scripts y shaders los genera Godot 4.4+ para rastrear recursos; no se editan a mano. La carpeta `.godot/` es caché del editor (ya está en `.gitignore`) y no debe subirse al repositorio.
>
> Los `main.tscn*.tmp` que aparecen en `scenes/` son temporales que Godot deja al guardar; no forman parte del juego y pueden borrarse.

---

## Configuración del proyecto (project.godot)

| Parámetro | Valor |
|---|---|
| Nombre de la aplicación | `Shapes` |
| Escena principal | `res://scenes/main_menu.tscn` (**Jugar/Continuar** carga `res://scenes/main.tscn`; **Niveles** carga `res://scenes/level_select.tscn`) |
| Autoload | `Sound` → `res://scripts/sound_manager.gd` |
| Guardado | `user://shapes_save.cfg` (ConfigFile) |
| Versión de Godot | `4.7` (Forward Plus) |
| Resolución base | `1280 x 720` |
| Modo de estiramiento | `canvas_items`, aspecto `expand` (la interfaz se escala con la ventana) |
| Plugin de editor habilitado | `script-ide` |
| Motor de física 3D | `Jolt Physics` (no se usa: el juego es 2D) |
| Driver de renderizado (Windows) | `d3d12` |

El proyecto define **un solo autoload, `Sound`** (`scripts/sound_manager.gd`, sección `[autoload]` de `project.godot`), que también crea en tiempo de ejecución los buses de audio `Music` y `SFX`. No define grupos globales ni acciones de entrada propias. El input del juego es de ratón y se procesa dentro de cada `Area2D`; la única tecla usada es `ui_cancel` (Esc), una acción que Godot ya trae: en el juego pide volver al menú, en el menú cierra "Cómo jugar", en el menú de niveles vuelve al menú y en el diálogo de confirmación cancela.

---

## Arquitectura y flujo del juego

### Árbol de la escena principal

```
Main (Node2D, main.gd)
├── Background          (ColorRect + background.gdshader)
├── Monster             (Area2D, monster.gd)        pos (610, 229)
│   ├── Collision       (círculo r=140)
│   ├── Body            (ColorRect 340×340 + monster.gdshader)
│   ├── AbsorbPoint     (Marker2D en (0, 20))
│   └── RequestBubble   (Node2D, request_bubble.gd) pos (-205, -57)
├── Palette             (Node2D, color_palette.gd)  pos (1150, 136)
│   ├── Red / Yellow / Blue / Clean   (instancias de PaintBucket, cada 130 px hacia abajo)
├── ShapeTray           (Node2D, shape_tray.gd)     pos (640, 620)
├── Eraser              (Area2D, eraser.gd)         pos (93, 287)
├── TutorialGhost       (Node2D, tutorial_ghost.gd, z_index 30)  oculto hasta que Main lo lanza
├── HUD                 (CanvasLayer, hud.gd)
│   ├── ScoreLabel / HintLabel / MenuButton (CreamButton)
│   └── ConfirmDialog   (Control, confirm_dialog.gd)  oculto hasta pedir salir
└── Camera2D                                        pos (643, 360)
```

### Ciclo de una jugada

0. Desde el menú, **Jugar/Continuar** (`MainMenu._on_play`) deja en `SaveData.pending_stage` el nivel más alto alcanzado, desliza el panel, hace que el slime reaccione y carga `main.tscn`. **Niveles** carga `level_select.tscn`, donde elegir una tarjeta deja ese nivel en `pending_stage` y también carga `main.tscn`.
1. `Main._ready()` toma el nivel de partida de `SaveData.pending_stage` (o del export `start_stage` si no hay), arranca la música `game`, activa el orden de picking del viewport, conecta `Monster.food_accepted` y aplica el nivel inicial (incluida la bandeja, con `tray.set_allowed_shapes()`).
2. El `Monster` elige una petición al azar con `GameData.random_request()` y la muestra en su `RequestBubble`.
3. Al pasar el ratón sobre una plantilla de la bandeja, esta reacciona (hover). El jugador la saca: al moverla más de 8 px deja de ser plantilla y emite `left_tray`; la `ShapeTray` crea una nueva del mismo tipo.
4. (Niveles 2+) El jugador arrastra un `PaintBucket` sobre la figura. Al soltarlo, el bote llama a `shape.paint(mask)`: el color se **mezcla con OR de bits** y se anima una onda de color.
5. Al soltar la figura, `Shape._end_drag()` revisa qué `Area2D` tiene debajo:
   - si es el slime → `Monster.try_eat(shape)`;
   - si es el borrador → `Eraser.erase_shape(shape)`.
6. Si el slime la acepta: se la come (mastica y se pone feliz), cambia de color, emite `food_accepted` y `Main` suma progreso. Si el progreso alcanza la meta del nivel, sube de nivel (se guarda con `SaveData.unlock_stage`, letrero, confeti, paleta con animación y el slime festeja con `celebrate()`). Si la rechaza, pone cara triste.
7. Al terminar de comer, el slime pide otra cosa distinta de la anterior (y mira de reojo hacia su globo). Si el nivel acaba de empezar, `Main` espera 0.8 s (1.6 s tras subir de nivel) y lanza `ghost.play(...)` con esa petición.
8. El tutorial se corta con el primer clic del jugador o cuando el slime come; si pasan 15 s sin clics, `Main` lo repite como ayuda.
9. En cualquier momento, **Esc** o el botón **Menú** llaman a `HUD.request_exit()`, que abre el diálogo de confirmación; solo si se pulsa **Sí, salir** se cambia a `main_menu.tscn`.

### Comunicación entre escenas

Las escenas se hablan por **señales hacia arriba** y **llamadas a métodos hacia abajo**. Además, para no acoplar clases, se usa *duck typing*: cada objeto pregunta `has_method("...")` sobre lo que tiene encima en lugar de comprobar su tipo.

| Quién pregunta | Método que busca (`has_method`) | Qué descubre |
|---|---|---|
| `Monster._process` | `get_eaten` | Hay una figura encima → se emociona (`excite` y cara `EXCITED`) |
| `Eraser._process` | `is_dragging` | Hay una figura arrastrándose encima → se resalta |
| `PaintBucket._find_target` | `can_paint` | Figuras pintables cercanas (imán y resaltado) |
| `Shape._end_drag` | `try_eat` / `erase_shape` | Soltó la figura sobre el slime / sobre el borrador |

| Señal | Emisor | Receptor |
|---|---|---|
| `food_accepted(shape_type, mask)` | `Monster` | `Main._on_food_accepted` (avanza progreso y niveles) |
| `food_rejected(shape_type, mask)` | `Monster` | *(nadie conectado; la cara triste la pone el propio `Monster`)* |
| `left_tray(shape)` | `Shape` | `ShapeTray._on_shape_left` (repone la figura, con `bind(type)`) |
| `request_changed(shape_type, mask)` | `Monster` | `Main._on_request_changed` (programa el tutorial del nivel) |
| `finished` | `TutorialGhost` | *(nadie conectado)* |
| `confirmed` / `cancelled` | `ConfirmDialog` | `HUD` (`confirmed` → `_go_to_menu`; `cancelled` no necesita receptor) |
| `poked` | `MenuSlime` | `MainMenu` (`title.jump`: el título hace su ola de saltos) |

### Picking del ratón

`Main._ready()` activa en el viewport `physics_object_picking_sort = true` y `physics_object_picking_first_only = true`: cuando varias `Area2D` pickable se solapan bajo el cursor, **solo la de más arriba** recibe el `_input_event`. Por eso una figura que se arrastra (con `z_index = 10` y movida al final de la lista de hijos) siempre gana sobre el resto. El `Monster` y el `Eraser` tienen `input_pickable = false`: no reciben clics, solo sirven de zona de destino.

---

## Sistema de colores y niveles (GameData)

Los colores son una **máscara de bits** (rojo = 1, amarillo = 2, azul = 4). Pintar mezcla con OR (`color_mask |= brush_mask`), así las mezclas salen solas:

| Máscara | Binario | Nombre | Color (RGB 0–1) | Cómo se obtiene |
|---|---|---|---|---|
| 0 | `000` | Blanco | (0.93, 0.93, 0.93) | Figura sin pintar o limpiada |
| 1 | `001` | Rojo | (0.90, 0.12, 0.12) | Primario |
| 2 | `010` | Amarillo | (1.00, 0.85, 0.10) | Primario |
| 4 | `100` | Azul | (0.15, 0.30, 0.95) | Primario |
| 3 | `011` | Naranja | (1.00, 0.50, 0.05) | Rojo + Amarillo |
| 6 | `110` | Verde | (0.10, 0.70, 0.25) | Amarillo + Azul |
| 5 | `101` | Morado | (0.58, 0.15, 0.78) | Azul + Rojo |
| 7 | `111` | Marrón | (0.38, 0.24, 0.12) | Los tres primarios |

`ANY_COLOR = -1` es el valor especial de `wanted_mask` que significa "el slime acepta cualquier color; solo importa la forma". El marrón (7) se pide en los niveles 8, 9 y 11.

**Definición de niveles (`STAGES`):**

| Campo | Significado |
|---|---|
| `name` | Nombre mostrado en el letrero de nivel |
| `hint` | Texto de ayuda para el HUD |
| `shapes` | Tipos de figura que puede pedir (índices de `ShapeType`: 0 círculo, 1 cuadrado, 2 triángulo, 3 estrella, 4 corazón). **También define qué figuras ofrece la bandeja** en ese nivel |
| `masks` | Colores que puede pedir (vacío = cualquier color) |
| `goal` | Aciertos para pasar al siguiente nivel (`0` = nivel final, infinito; solo el último debe tenerlo) |
| `palette` | Si se muestran los botes de pintura |

**Para añadir un nivel** basta con agregar otro diccionario con esos seis campos a `STAGES` antes del último (el que tiene `goal: 0`). `Main`, `Monster`, la bandeja, el HUD, el menú de niveles y el guardado (`SaveData`) leen la lista, así que no hay que tocar nada más: el nivel nuevo aparece bloqueado en el menú de niveles hasta que el jugador llegue a él. Un campo opcional `"tutorial": false` desactiva la mano fantasma en ese nivel (por defecto está activa). En `Main` el export `start_stage` permite empezar directamente en cualquier nivel para probarlo (0 = primero).

---

## Documentación de scripts y funciones

### `game_data.gd`
**Clase:** `GameData` — **Hereda de:** `RefCounted`. Repositorio estático de datos y reglas del juego; no se instancia.

**Enum y constantes**
- `ShapeType { CIRCLE, SQUARE, TRIANGLE, STAR, HEART }` — los 5 tipos de figura (coinciden con el `shape_type` de `shape.gdshader`).
- `RED = 1`, `YELLOW = 2`, `BLUE = 4`, `ANY_COLOR = -1`.
- `COLORS` / `NAMES` — diccionarios `máscara → Color` y `máscara → nombre en español`.
- `STAGES` — array con la configuración de los **11 niveles** (ver tabla de "Cómo se juega").

| Función | Descripción |
|---|---|
| `mask_to_color(mask)` | Devuelve el `Color` de una máscara; si no existe, el blanco (`COLORS[0]`). |
| `mask_to_name(mask)` | Devuelve el nombre en español de la máscara, o `"?"`. |
| `random_request(stage, last = {})` | Elige una petición `{shape, mask}` al azar según el nivel (con `clampi` sobre el índice). Si el nivel no tiene `masks`, usa `ANY_COLOR`. Intenta hasta **12 veces** no repetir la petición anterior (`last`); si no lo logra, se queda con la última. |

---

### `main.gd`
**Hereda de:** `Node2D` — Director del juego: progreso, niveles y celebración.

**Exportados:** `tutorial` (activa o desactiva la mano fantasma) y `start_stage` — nivel con el que empieza (0 = primero, tope `GameData.STAGES.size() - 1`); útil para probar un nivel directamente desde el Inspector.

**Variables:** `stage` (nivel actual), `progress` (aciertos en el nivel). Referencias a `$Monster`, `$Palette`, `$HUD` y `$ShapeTray`.

| Función | Descripción |
|---|---|
| `_ready()` | Llama a `randomize()`, activa el orden y el "solo el primero" del picking del viewport, conecta `monster.food_accepted` y aplica el nivel inicial (limitado con `clampi`). |
| `_input(event)` | Un clic izquierdo cancela el tutorial que estaba por salir y reinicia el contador de ayuda. |
| `_process(delta)` | Cuenta regresiva del tutorial (`_tutorial_wait`) y, si el jugador lleva `HELP_AFTER` = 15 s sin clics, lo repite como ayuda. No corre con el diálogo de confirmación abierto. |
| `_play_tutorial()` | Llama a `ghost.play(monster.wanted_shape, monster.wanted_mask, tray, palette, absorb_point)`. Si el slime está comiendo o hay un clic presionado, espera 0.4 s. |
| `_on_request_changed(...)` | Con la primera petición de un nivel, programa el tutorial (`TUTORIAL_FIRST_DELAY` 0.8 s / `TUTORIAL_STAGE_DELAY` 1.6 s). |
| `_unhandled_input(event)` | Con `ui_cancel` (Esc) llama a `hud.request_exit()`, que abre la confirmación. Si el diálogo ya está abierto, este Esc nunca llega aquí: el diálogo lo consume antes para cancelar. |
| `_apply_stage(celebrate)` | Configura el nivel actual: `monster.set_stage(stage, not celebrate)`, `palette.set_enabled(cfg.palette, celebrate)`, `tray.set_allowed_shapes(cfg.shapes, celebrate)`, la pista del HUD y el progreso. Con `celebrate = true` (cambio de nivel) además llama a `monster.celebrate()` (el slime festeja con la cara grande al terminar de comer), muestra el letrero `¡Nivel N!  Nombre` y lanza el confeti. En un cambio de nivel el slime **no** cambia de petición al instante: la nueva llega cuando termina de comer. |
| `_update_hud()` | Envía al HUD nivel, aciertos y meta. |
| `_on_food_accepted(...)` | Suma 1 al progreso. Si la meta es mayor que 0, se alcanzó y no es el último nivel, sube de nivel y reinicia el progreso; si no, solo actualiza el HUD. |
| `_confetti()` | Instancia 6 `PaintBurst` en círculo (radio 170 px) alrededor del slime, uno por cada color [rojo, amarillo, azul, naranja, verde, morado], con escala 1.3. |

---

### `monster.gd`
**Clase:** `Monster` — **Hereda de:** `Area2D`. El slime: pide, acepta/rechaza figuras y se anima a través de su shader.

**Señales:** `food_accepted(shape_type, mask)`, `food_rejected(shape_type, mask)`.

**Exportado:** `start_color` (por defecto `Color(0.35, 0.75, 0.85)`) — color inicial del cuerpo.

**Constante:** `SLEEP_AFTER = 14.0` (segundos sin actividad para que le dé sueño).

**Estado:** `wanted_shape`, `wanted_mask`, `stage`; internos `_excite`, `_squish`, `_busy`, `_hovering`, `_cheer`, `_idle_time`, `_last_mouse`, `_current_color`, `_last_request` y `_face` (su `SlimeFace`).

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material del cuerpo (para que cada slime tenga el suyo), aplica `start_color`, crea su `SlimeFace` con ese material y hace la primera petición. |
| `_process(delta)` | Si no está ocupado, detecta con `get_overlapping_areas()` si hay una figura encima (`has_method("get_eaten")`) y suaviza `_excite` hacia 1 o 0 (`lerp` exponencial, factor 10). Cada frame envía `excite` y `squish` al shader y actualiza la **cara**: la cara de fondo es `EXCITED` con una figura encima, `SLEEPY` tras `SLEEP_AFTER` s sin actividad (ni figuras ni movimiento del ratón) o `IDLE` en los demás casos, y mira hacia el ratón. |
| `set_stage(value, refresh)` | Cambia el nivel; con `refresh = true` pide algo nuevo de inmediato. |
| `is_busy()` | `true` mientras come o rechaza una figura. |
| `celebrate()` | La llama `Main` al subir de nivel: marca `_cheer` para que el bocado actual termine con la cara `CHEER` en vez de `HAPPY`. |
| `new_request()` | Despierta al slime (`_idle_time = 0`), le hace mirar de reojo hacia el globo 1.2 s (`glance`), pide una petición con `GameData.random_request(stage, _last_request)` y la muestra en el globo. Si acepta cualquier color, la figura del globo se dibuja en blanco. |
| `try_eat(shape)` | Punto de entrada que llama la figura al soltarse encima. Si está ocupado devuelve `false`. Compara forma y color (`ANY_COLOR` ignora el color). Acepta (`_accept`) o rechaza (`_reject`) y devuelve el resultado. |
| `_accept(shape)` | Se marca ocupado, ordena a la figura volar al `AbsorbPoint` (`get_eaten`), cambia de color si la figura estaba pintada (una figura blanca no cambia el color del slime), emite `food_accepted` (ahí `Main` puede llamar a `celebrate()`), reproduce la secuencia de cara **masticar (0.45 s) → feliz (1.0 s)** —o **→ festejo (1.7 s)** si subió de nivel— y anima: `_excite` a 1 y bajando en 0.7 s, y `_squish` 1.0 → −0.6 → 0 (aplasta, estira y rebote elástico). Al final (~0.87 s) llama a `_finish_eating()`. |
| `_finish_eating()` | Libera el estado ocupado y pide una nueva petición (ya con el nivel nuevo, si cambió). |
| `_reject(shape)` | Pone cara **triste** 1.1 s, emite `food_rejected` y hace un gesto de "no" con `_squish` (0.5 → −0.3 → 0, ~0.46 s) mientras está ocupado. |
| `_change_color(to)` | Interpola el color del cuerpo del color actual al nuevo en 0.5 s con `tween_method`. |
| `_set_body_color(c)` | Escribe el uniform `body_color` del shader. |

---

### `slime_face.gd`
**Clase:** `SlimeFace` — **Hereda de:** `RefCounted`. La **cara** del slime (ojos y boca). El dibujo lo hace `monster.gdshader`; esta clase solo decide qué cara poner y la anima. La comparten `Monster` (juego) y `MenuSlime` (menú): cada uno crea la suya con `SlimeFace.new(material)` (el material ya duplicado) y la actualiza cada frame.

**Estados de ánimo (`Mood`)** — cada uno es un conjunto de valores para los uniforms de cara del shader (`PRESETS`):

| Mood | Cuándo aparece | Cara |
|---|---|---|
| `IDLE` | De fondo, sin nada especial | Ojos ovalados abiertos y boquita sonriente |
| `EXCITED` | Una figura arrastrada encima del slime (juego) o el ratón cerca (menú) | Ojos más grandes y **brillantes**, boca enorme en "D" con lengua, mejillas |
| `EATING` | Los primeros 0.45 s tras aceptar una figura | Ojos felices `^ ^` y boca que **abre y cierra** (mastica) |
| `HAPPY` | Después de masticar (1 s) | Ojos felices, bocota con lengua, mejillas rosadas y destellos |
| `CHEER` | Después de masticar el bocado que sube de nivel (1.7 s) | Boca abierta al máximo, mejillas a tope y **destellos** girando alrededor |
| `SAD` | Al rechazar una figura (1.1 s) | Ojos enormes y llorosos, cejas caídas, boca de puchero y **lágrimas** que caen |
| `SURPRISED` | Al tocar al slime del menú (0.35 s, luego `HAPPY`) | Ojos gigantes y boca en "o" |
| `SLEEPY` | 14 s sin actividad en el juego | Ojos casi cerrados y boquita en "o" |

**API**

| Función | Descripción |
|---|---|
| `_init(material)` | Guarda el `ShaderMaterial` y parte de la cara `IDLE`. |
| `update(delta, base_mood, look_dir)` | Se llama cada frame. Elige la cara (un gesto temporal pisa a `base_mood`), acerca cada parámetro a su objetivo con suavizado exponencial (`RATE = 12`), suaviza la mirada, dispara el **parpadeo** (cada 2–5 s al azar, 0.16 s) y escribe todo en el shader. En `EATING` suma a `mouth_open` un seno rápido (`0.3 · sin(t · 22)`) para masticar. |
| `play(sequence)` | Reproduce gestos en orden, cada uno `[mood, segundos]`; p. ej. `[[EATING, 0.45], [HAPPY, 1.0]]`. Al terminar vuelve a la cara de fondo. Una secuencia nueva reemplaza a la anterior. |
| `glance(dir, seconds)` | Fuerza la mirada hacia `dir` (−1..1) durante unos segundos, sin importar el ratón (el slime mira hacia su globo al pedir). |

**Parámetros del shader que controla** (mismos nombres en `PRESETS` y en `monster.gdshader`): `eye_open`, `eye_happy`, `eye_size`, `shine`, `brow`, `mouth_curve`, `mouth_open`, `mouth_width`, `blush`, `tears` y `sparkle`; además `blink` y `look`, que calcula `update()` aparte.

**Para añadir una cara nueva:** agrega un valor al enum `Mood`, su entrada en `PRESETS` con los once parámetros y úsala con `play()` o como `base_mood`.

---

### `tutorial_ghost.gd`
**Clase:** `TutorialGhost` — **Hereda de:** `Node2D` (`z_index` 30, oculto al inicio). Tutorial visual para niños que aún no leen: una **mano fantasma** demuestra la jugada del nivel. No conoce el juego; `Main` le pasa lo que necesita.

**Señal:** `finished` (terminó o se detuvo). **Exportados:** `loops` (3 repeticiones) y `move_time` (0.85 s por traslado).

**Una vuelta de la demostración** (línea de tiempo de un solo `Tween` con `set_loops`):
1. La mano aparece junto a la figura pedida en la bandeja, se cierra en puño y la agarra (se crea una **figura fantasma** translúcida con el mismo `shape.gdshader`).
2. Si el slime pide **cualquier color**: la lleva directo a su boca. Si pide un **color**: la lleva a una "mesa de trabajo" entre la bandeja y el slime y, por cada color primario de la máscara (rojo 1, amarillo 2, azul 4), va al bote, lo arrastra (un **bote fantasma**) sobre la figura y la pinta: estallido de pintura y la figura cambia de color con la misma onda del juego. Así el naranja se ve como *rojo, luego amarillo*; el marrón, como los tres.
3. Recoge la figura ya pintada y se la lleva al slime, que "se la come" (la figura se encoge y hay un estallido blanco). La mano se desvanece y vuelve a empezar.

Una **guía de puntitos** (`_draw`) marca los caminos y los puntos "corren" hacia el destino.

| Función | Descripción |
|---|---|
| `play(shape_type, mask, tray, palette, target)` | Calcula las posiciones con `tray.slot_position()` y `palette.bucket_position()`, arma la guía y lanza la línea de tiempo. `mask <= 0` = sin pintar. |
| `stop(immediate)` | Detiene todo; con fundido de 0.25 s o de golpe. Emite `finished`. |
| `is_playing()` | `true` mientras la demostración corre. |
| `_input(event)` | Un clic izquierdo del jugador la detiene. |
| `_process(delta)` | Hace que la figura/bote fantasma siga a la mano y que esta se balancee. |
| `_build(...)` | Construye la línea de tiempo (pasos 1 a 3 de arriba). |

**Quién la lanza:** `Main` (ver `_play_tutorial`). Sale al llegar la primera petición de cada nivel, se corta con el primer clic o cuando el slime come, y reaparece como ayuda tras 15 s sin clics. Con `tutorial = false` en `Main` se desactiva por completo.

---

### `shape.gd`
**Clase:** `Shape` — **Hereda de:** `Area2D`. La figura arrastrable. Es el script más complejo: arrastre, pintura, ciclo de vida, el efecto gelatina y el feedback de hover.

**Señal:** `left_tray(shape)` — se emite cuando una plantilla sale de la bandeja.

**Constantes:** `BURST` (escena del estallido), `WARNING_TIME = 6.0` (segundos de parpadeo antes de desaparecer).

**Exportados:** `shape_type` (enum: Círculo, Cuadrado, Triángulo, Estrella, Corazón), `lifetime` (45 s; 0 = nunca desaparece) y `jelly` (0 = rígida, 1 = normal, 2 = exagerada).

**Estado:** `color_mask` (0–7), `is_template` (`true` mientras está en la bandeja: no se puede pintar). Internos de arrastre (`_dragging`, `_moved`, `_vanishing`, `_grab_offset`, `_press_mouse`), de gelatina (`_sway`, `_stretch`, `_lift`, `_tremor` con sus velocidades) y de hover (`_hovered`, `_hover`).

**API pública (la usan otras escenas)**

| Función | Descripción |
|---|---|
| `setup(type, mask = 0)` | Fija tipo y color; refresca el visual si el nodo ya está listo (la bandeja la llama antes de añadirla al árbol). |
| `is_dragging()` | `true` si se está arrastrando (lo consulta el borrador para resaltarse). |
| `can_paint()` | `true` si no es plantilla y no está desapareciendo (lo consulta el bote de pintura). |
| `set_highlight(value)` | Activa el uniform `selected` (contorno blanco) cuando un bote está cerca. |
| `paint(brush_mask)` | `0` = limpia a blanco; si no, mezcla con OR. Guarda el color anterior en `old_color`, anima `wave` 0 → 1 en 0.4 s (la onda de color), lanza un `PaintBurst`, y da un "golpe": escala 1.25 y giro aleatorio de ±0.3 rad que se recuperan con `TRANS_BACK` / `TRANS_ELASTIC`. |
| `vanish()` | Desaparece con "puf": estallido del color actual, encoge a 0 y gira 180° en 0.35 s, y se libera. Lo llaman el borrador y el fin de la vida útil. |
| `get_eaten(target)` | Lo llama el slime al aceptarla: vuela hasta `target` mientras se encoge (0.25 s) y se libera. |

**Funciones internas**

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material, centra el pivote del visual, guarda su posición base y conecta las señales `mouse_entered` / `mouse_exited` del `Area2D`. |
| `_refresh()` | Envía tipo y color al shader (`shape_type`, `fill_color`, `old_color`, `wave = 1`). |
| `_input_event(...)` / `_input(event)` | Pulsar sobre la figura inicia el arrastre; soltar el botón izquierdo en cualquier parte lo termina (por eso va en `_input`, para no perder el "soltar" si el cursor se sale). |
| `_process(delta)` | Actualiza la gelatina. Si se arrastra: tras mover **más de 8 px** deja de ser plantilla y emite `left_tray`; sigue al ratón con retraso suave (`lerp` exponencial, factor 24), limitada a la pantalla menos 50 px de margen. Si está suelta: cuenta `_idle`, parpadea (alpha 0.5–1) los últimos 6 s y llama a `vanish()` al agotarse. |
| `_update_jelly(delta)` | Calcula la velocidad real de la figura y mueve **solo el dibujo** (`visual`) con 3 resortes subamortiguados: inclinación (según velocidad X), estiramiento (horizontal vs. vertical) y "levantada" (crece al agarrarla), más un temblor sinusoidal que se apaga tras soltarla. También gestiona el **hover**: suaviza `_hover` hacia 1 solo si el cursor está encima de una plantilla que no se arrastra (`lerp` exponencial, factor 14), lo envía al shader, sube el objetivo de `_lift` (`0.10 × _hover`), añade un meneo suave (`0.06 · _hover · sin(t)` rad) y eleva el dibujo 8 px (`bob`). Ver [Técnicas de animación](#técnicas-de-animación-usadas). |
| `_on_mouse_entered()` / `_on_mouse_exited()` | Marcan `_hovered`. Al entrar sobre una plantilla (no desapareciendo) el cursor cambia a manita (`CURSOR_POINTING_HAND`); al salir vuelve a flecha. |
| `_exit_tree()` | Si la figura se libera con el cursor encima (por ejemplo al sacarla de la bandeja y desaparecer), restaura el cursor a flecha para que no se quede la manita. |
| `_start_drag()` | Guarda el desplazamiento entre el cursor y el centro, sube `z_index` a 10, da un saltito y se mueve al final de la lista de hijos (se dibuja por encima). |
| `_end_drag()` | Si solo fue un clic (sin mover) no hace nada. Si se movió: golpecito de gelatina y revisa los `Area2D` solapados — el primero con `try_eat` (slime) la ofrece; si la rechaza la empuja lejos (`_push_away`); el primero con `erase_shape` (borrador) la borra. |
| `_push_away(center)` | Si el slime la rechaza, la lanza 240 px en dirección contraria al slime (limitada a pantalla) con `TRANS_BACK`. |
| `_touch()` | Reinicia el temporizador de vida y restaura el alpha. |
| `_spawn_burst(color)` | Instancia un `PaintBurst` en la posición de la figura. |
| `_kill_tween()` | Detiene el `Tween` activo para que no se pisen animaciones. |

---

### `shape_tray.gd`
**Clase:** `ShapeTray` — **Hereda de:** `Node2D`. Ofrece las figuras plantilla **del nivel actual** y las repone al sacarlas. Ya no crea figuras por su cuenta: es `Main` quien le indica cuáles con `set_allowed_shapes()`. Su tablero (`Board`, dibujado por `tray.gdshader`) crece o se encoge según cuántas figuras ofrezca el nivel.

**Exportados:** `shape_scene` (`PackedScene` de `shape.tscn`), `spacing` (160 px entre figuras; `slot_position(type)` devuelve la posición global de la casilla de un tipo, para el tutorial), `board_height` y `board_side` (medidas del tablero), `shape_lifetime` (45 s; se pasa a cada figura).

**Estado:** `_allowed` (tipos permitidos en el nivel, ordenados) y `_templates` (diccionario `tipo → figura plantilla` que hay ahora en la bandeja).

| Función | Descripción |
|---|---|
| `set_allowed_shapes(types, animate = true)` | Define qué figuras ofrece la bandeja. Quita las plantillas cuyo tipo ya no está permitido (con `vanish()` si `animate`, o `queue_free()` si no), crea las que faltan y reacomoda todas. `Main` la llama en cada cambio de nivel con `cfg["shapes"]`. |
| `_slot_x(type)` | Posición X de un tipo según su índice dentro de `_allowed`: `(i - (n - 1) / 2) * spacing`, de modo que la bandeja siempre queda centrada. |
| `_layout(animate)` | Mueve cada plantilla a su casilla; con `animate`, deslizándolas en 0.3 s (`TRANS_BACK`). |
| `_spawn(type, animate)` | Instancia una figura, la coloca en su casilla, le asigna `lifetime`, la configura con `setup(type, 0)`, conecta su señal `left_tray` con `bind(type)`, la registra en `_templates` y, si `animate`, la hace aparecer escalando de 0 a 1 en 0.3 s (`TRANS_BACK`). |
| `_on_shape_left(_shape, type)` | Cuando el jugador saca una plantilla, la quita de `_templates` y repone una nueva del mismo tipo **solo si ese tipo sigue permitido**. |

> Con `animate = false` (arranque del juego) las figuras aparecen directamente; en una subida de nivel, las nuevas entran con animación y las existentes se deslizan para quedar centradas. Las figuras que el jugador ya sacó de la bandeja no se tocan.

---

### `paint_bucket.gd`
**Clase:** `PaintBucket` — **Hereda de:** `Area2D`. Bote de pintura arrastrable que pinta la figura más cercana al soltarse.

**Exportados:** `mask` (1 = rojo, 2 = amarillo, 4 = azul, 0 = limpiar) y `trail_spacing` (16 px entre gota y gota de la estela).

**Estado:** `home_position` (se guarda en `_ready` desde su posición en el editor, a donde vuelve), `_dragging`, `_returning`, `_highlighted` (figura resaltada) y los resortes `_sway` y `_lift`.

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material y lo configura con el shader de figuras: `shape_type = 0` (círculo) con el color del bote. Rotula `"Limpiar"` o el nombre del color. |
| `_input_event(...)` / `_input(event)` | Pulsar inicia el arrastre (`z_index = 20`, saltito, contorno blanco y cancela el tween de regreso); soltar lo termina. |
| `_process(delta)` | Mientras se arrastra: busca el objetivo, sigue al ratón con **efecto imán** (si hay objetivo cercano, el destino se desplaza un 30 % hacia él), gestiona el resaltado y suelta una gotita cada 0.12 s aunque esté quieto. Siempre que se mueve (arrastrando o regresando) deja una **estela** de gotas cada `trail_spacing` px con velocidad contraria al movimiento. Inclinación y "crecer" con resortes. |
| `_find_target()` | Devuelve la figura pintable (`can_paint()`) solapada más cercana, a menos de **70 px**, o `null`. |
| `_set_highlight(shape, value)` | Resalta/quita el resalte de una figura con protección ante nodos liberados (`is_instance_valid`). |
| `_end_drag()` | Quita resalte, si hay objetivo llama `target.paint(mask)`, lanza una **salpicadura** de 10 gotas en todas direcciones y regresa al lugar de origen con `TRANS_BACK` en 0.3 s. |
| `_spawn_drop(pos, velocity, size, life)` | Instancia un `PaintDrop` en la escena actual, con el color del bote. |

---

### `color_palette.gd`
**Hereda de:** `Node2D`. Contenedor de los 4 botes; controla su visibilidad, expone `bucket_position(mask)` (posición global en reposo de cada bote, para el tutorial) y ajusta la tabla de madera (`Board`, `palette_board.gdshader`) a donde estén los botes.

| Función | Descripción |
|---|---|
| `set_enabled(value, animate = true)` | Muestra u oculta la paleta. Cada hijo `Area2D` activa o desactiva `input_pickable` (oculto = tampoco se puede agarrar). Al mostrarla con `animate`, cada bote entra escalando de 0 a 1 en 0.45 s (`TRANS_BACK`) con un desfase de 0.12 s entre botes; sin `animate`, aparece directamente. |

---

### `eraser.gd`
**Hereda de:** `Area2D`. Zona de borrado. No se agarra (`input_pickable = false`): se activa cuando una figura se suelta encima.

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material de su `Visual`. |
| `_process(delta)` | Si hay una figura **arrastrándose** encima (`is_dragging()`), sube `_hover` hacia 1 (suavizado exponencial, factor 12); si no, hacia 0. Envía `hover` al shader (se ilumina y su contorno se vuelve blanco) y crece hasta un 15 % (`scale`). |
| `erase_shape(shape)` | La llama la figura al soltarse. Ordena `shape.vanish()` y hace un meneo de goma (giro a +0.3 rad, −0.3 rad y regreso elástico a 0). |

---

### `request_bubble.gd`
**Clase:** `RequestBubble` — **Hereda de:** `Node2D`. Globo que muestra la figura y el color que pide el slime.

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material de `Item` (el dibujo de la figura dentro del globo). |
| `show_request(shape_type, mask)` | Pone `shape_type` y `fill_color` en el shader de la figura y reproduce una animación de aparición: escala 0 → 1 en 0.4 s (`TRANS_BACK`). |

---

### `paint_burst.gd`
**Hereda de:** `Node2D`. Estallido de anillo y chispas de un solo uso.

| Función | Descripción |
|---|---|
| `play(color)` | Duplica el material, asigna `burst_color` (el color aclarado un 15 %), anima el uniform `progress` de 0 a 1 en 0.6 s con `tween_method` y se libera al terminar (`queue_free`). Lo usan `Shape` (al pintar o desaparecer) y `Main` (confeti de subida de nivel). |

---

### `paint_drop.gd`
**Hereda de:** `Node2D`. Gota de pintura con física simple; se destruye sola.

| Función | Descripción |
|---|---|
| `launch(color, size, velocity, life = 0.6)` | Duplica el material, asigna `drop_color`, fija la escala base (`size / 40`, porque el `Rect` mide 40 px) y guarda la velocidad inicial y la vida. |
| `_process(delta)` | Avanza la edad. Aplica **gravedad** (+700 px/s² en Y) y **fricción** (`exp(-2.5·delta)`), mueve la gota, la encoge con `(1 − t²)` y la desvanece con alpha `1 − t`. Se libera cuando `t ≥ 1`. |

---

### `hud.gd`
**Clase:** `HUD` — **Hereda de:** `CanvasLayer`. Interfaz superpuesta: puntuación, botón **Menú** (`CreamButton`) y el diálogo de confirmación (`ConfirmDialog`).

| Función | Descripción |
|---|---|
| `_ready()` | Conecta el botón **Menú** y el `confirmed` del diálogo, y crea **por código** un `Label` grande (fuente 56, blanco con contorno morado oscuro de 14 px, centrado, 1280×90 en (0, 230), ignora el ratón, transparente) para anunciar cada nivel. |
| `set_progress(level, done, goal)` | Si hay meta, muestra `Nivel N   hechos/meta`; en el nivel final (meta 0) muestra `Nivel N   ★ hechos`. |
| `set_hint(text)` | Cambia el texto de la pista (`HintLabel`). |
| `is_dialog_open()` | `true` si la ventana de confirmación está abierta (el tutorial se pausa). |
| `request_exit()` | Abre el diálogo "¿Volver al menú?" (`confirm.ask(...)`). Lo llaman el botón **Menú** y `Main` al pulsar Esc. **No** cambia de escena por sí mismo. |
| `_go_to_menu()` | Solo se ejecuta cuando el jugador confirma (`confirmed`): carga `res://scenes/main_menu.tscn`. |
| `show_banner(text)` | Muestra el letrero: alpha 1, escala 0.4 → 1 en 0.4 s (`TRANS_BACK`), se mantiene 1.6 s y se desvanece en 0.5 s. |

---

### `confirm_dialog.gd`
**Clase:** `ConfirmDialog` — **Hereda de:** `Control`. Ventana de confirmación con el estilo del menú (panel crema de `menu_panel.gdshader` + dos `CreamButton`). Es un `Control` de pantalla completa dentro del `HUD`: bloquea los clics hacia el juego mientras está abierta (el panel y la propia raíz tienen `mouse_filter` en *stop*) y oscurece el fondo con un `ColorRect` (`Dim`).

**Señales:** `confirmed` (botón *Sí*), `cancelled` (botón *No*, Esc o clic fuera del panel).

| Función | Descripción |
|---|---|
| `_ready()` | Se oculta, pasa el tamaño del panel al shader (`rect_size`), centra su pivote y conecta los dos botones a `_answer(true/false)`. |
| `ask(title, message, yes_text, no_text)` | Muestra el diálogo (los textos vacíos dejan los de la escena). Aparece con un fundido de 0.15 s y el panel crece de 0.7 a 1 con `TRANS_BACK`. Si ya está abierto no hace nada. |
| `is_open()` | `true` si está visible. |
| `_gui_input(event)` | Un clic izquierdo sobre el fondo (fuera del panel) cancela. |
| `_unhandled_input(event)` | Con Esc y el diálogo abierto, consume el evento (`set_input_as_handled`) y cancela; así el Esc de `Main` no lo vuelve a abrir. |
| `_answer(accepted)` | Cierra con un fundido de 0.12 s y emite `confirmed` o `cancelled`. |

> No pausa el árbol: mientras está abierto, las figuras sueltas siguen con su cuenta regresiva de 45 s. Si prefieres congelar el juego, pon `get_tree().paused = true` en `ask()` y `process_mode = PROCESS_MODE_ALWAYS` en la escena (y devuélvelo en `_answer()`).

---

### `main_menu.gd`
**Hereda de:** `Node2D`. Menú principal (escena de arranque): panel semitransparente a la izquierda (título animado + botones **Jugar/Continuar** —el texto cambia si hay progreso guardado—, **Niveles**, **Cómo jugar**, **Salir** y un interruptor **Sonido: Sí/No** que usa `Sound.toggle_mute()`) y el slime del menú a la derecha, rodeado de figuras que flotan.

| Función | Descripción |
|---|---|
| `_ready()` | Pasa el tamaño del panel a su shader, crea las figuras decorativas, conecta los botones y la señal `poked` del slime (`title.jump`), y reproduce la entrada: el panel se desliza desde la izquierda y el slime "salta" a escena (escala 0 → 1.35 con `TRANS_ELASTIC`). |
| `_process(delta)` | Mece las figuras decorativas (posición, giro y escala con senos desfasados por figura). |
| `_build_decor()` | Crea un `ColorRect` con `shape.gdshader` por cada entrada de `DECOR` (tipo, máscara de color, posición y tamaño). |
| `_show_help(value)` | Alterna entre los botones y las instrucciones; Esc también vuelve de la ayuda. |
| `_on_play()` | Hace reaccionar al slime y al título, desliza el panel hacia afuera y a los 0.7 s carga `main.tscn`. |

---

### `menu_slime.gd`
**Hereda de:** `Node2D`. Slime del menú: reutiliza `monster.gdshader` y `SlimeFace`.

**Señal:** `poked` (lo tocó el jugador). **Exportados:** `change_interval` (1.8 s entre colores), `change_duration` (0.9 s de transición) y `click_radius` (150 px).

| Función | Descripción |
|---|---|
| `_process(delta)` | Cada `change_interval` cambia de color (nunca repite el anterior); se emociona cuando el ratón está cerca y actualiza su **cara**: `EXCITED` con el ratón cerca, `IDLE` si no, y siempre mira hacia el ratón. |
| `poke()` | Lo llama un clic cercano (y el botón **Jugar**): se aplasta, cambia de color de golpe, suelta un `PaintBurst`, pone cara **sorprendido (0.35 s) → feliz (1.1 s)** y emite `poked`. |

---

### `cream_button.gd`
**Clase:** `CreamButton` — **Hereda de:** `ColorRect`. Botón crema dibujado por `menu_button.gdshader` con texto azul oscuro. Emite `pressed` al soltar el clic izquierdo con el ratón encima. Crece con el hover, se hunde al presionar y "tiembla" suave. **Exportados:** `text`, `font_size`, `disabled` (se ve apagado y no emite `pressed`; al intentar presionarlo tiembla y suena `locked`) y `emphasized` (se ve "iluminado" y respira, para destacar una opción). Suena `hover` al pasar el ratón y `click` al presionar. Lo usan el menú, el botón **Menú** del HUD y el diálogo de confirmación.

---

### `animated_title.gd`
**Clase:** `AnimatedTitle` — **Hereda de:** `Control`. Título con un `Label` por letra: cada una flota, se inclina y "respira" con su propio desfase, y cada `jump_interval` s (o al llamar a `jump()`) todo el título hace una ola de saltos con aplastamiento y estiramiento. `title_letter.gdshader` recolorea el relleno de cada letra con colores que cambian.

---

### `level_select.gd`
**Hereda de:** `Node2D`. Menú de niveles. Una cuadrícula de 3 columnas con scroll (rueda del ratón) con **una tarjeta (`CreamButton`) por cada entrada de `GameData.STAGES`**, creada en `_build_cards()`: por eso al añadir un nivel a `GameData` aparece aquí sin tocar nada más.

| Tarjeta | Aspecto |
|---|---|
| Nivel ya superado (`SaveData.is_completed`) | `★ Nivel N` + nombre |
| Nivel actual (el más alto alcanzado) | `Nivel N` + nombre, con brillo (`emphasized`) |
| Nivel bloqueado | `Nivel N` + "Bloqueado", apagada y sin respuesta (`disabled`) |

| Función | Descripción |
|---|---|
| `_ready()` | Conecta *Volver*, *Borrar progreso* y el diálogo de confirmación, construye las tarjetas, arranca la música `menu` y anima la entrada del panel. |
| `_build_cards()` | Borra y vuelve a crear las tarjetas; el subtítulo muestra "Nivel alcanzado: X de N". Las tarjetas usan `mouse_filter = PASS` para que la rueda del ratón llegue al scroll. |
| `_play_stage(index)` | Deja el nivel en `SaveData.pending_stage`, hace una salida con fundido y carga `main.tscn`. |
| `_ask_reset()` / `_reset()` | Pide confirmación (`ConfirmDialog`) y llama a `SaveData.reset_progress()`; luego reconstruye las tarjetas. |
| `_unhandled_input(event)` | Esc vuelve al menú principal. |

---

### `save_data.gd`
**Clase:** `SaveData` — **Hereda de:** `RefCounted`. Guardado en `user://shapes_save.cfg` (un `ConfigFile`). Todo es **estático**: no se instancia ni es autoload.

| Miembro | Descripción |
|---|---|
| `pending_stage` | (variable estática) Nivel elegido en el menú para la próxima partida; `-1` = ninguno. `Main` lo lee en `_ready()` y lo limpia. |
| `unlocked_stage()` | Índice (desde 0) del nivel más alto alcanzado, siempre dentro de `GameData.STAGES` (si borras niveles, se ajusta solo). |
| `unlock_stage(index)` | Lo sube (y guarda) si es mayor al actual; `Main` lo llama al subir de nivel. |
| `is_unlocked(i)` / `is_completed(i)` | Un nivel está desbloqueado si `i <= unlocked_stage()` y completado si `i < unlocked_stage()` (el último, al ser infinito, nunca). |
| `reset_progress()` | Borra el progreso y conserva los ajustes. |
| `get_setting(key, default)` / `set_setting(key, value)` | Ajustes guardados (`muted`, `music_volume`, `sfx_volume`). |

> Solo se guarda **el nivel alcanzado**, no los aciertos dentro del nivel: al continuar se empieza ese nivel desde 0 aciertos. En Windows el archivo queda en `%APPDATA%\Godot\app_userdata\Shapes\` (en el editor: *Proyecto → Abrir carpeta de datos de usuario*).

---

### `sound_manager.gd`
**Autoload:** `Sound` — **Hereda de:** `Node`. Todo el sonido del juego, **sin archivos de audio**: se sintetiza por código y se guarda en caché. Crea los buses `Music` y `SFX` y un grupo de 10 `AudioStreamPlayer` para los efectos (10 a la vez).

**Efectos procedurales.** Cada efecto de la constante `SFX` es una lista de *capas* que se suman: `at` (inicio en s), `dur`, `f0`/`f1` (frecuencia inicial y final → barrido), `wave` (`SINE`, `TRI`, `SQUARE`, `SAW`, `NOISE`), `amp`, `atk`, `dec` (caída exponencial), `rel`, `vib_hz`/`vib` (vibrato) y `noise` (mezcla de ruido). `_render_layer()` genera la onda muestra por muestra y `_to_wav()` la convierte en un `AudioStreamWAV` de 16 bits a 22 050 Hz (con `tanh` como limitador). Se sintetizan una sola vez (en el arranque, un efecto por frame) y quedan en caché.

| Efecto | Dónde suena |
|---|---|
| `click` / `hover` / `locked` | Botones (`CreamButton`): presionar, pasar el ratón, intentar abrir algo bloqueado |
| `pick` / `drop` | Agarrar una figura / soltarla; `pick` agudo al agarrar un bote de pintura |
| `paint` | Pintar una figura |
| `eat` → `happy` / `levelup` | El slime come (ñam) y, 0.42 s después, jingle de alegría o de subida de nivel |
| `reject` | El slime rechaza una figura |
| `pop` | Figura que desaparece, tocar al slime del menú, abrir el diálogo de confirmación |
| `whoosh` | Al pulsar Jugar y al elegir un nivel |
| `sparkle` | *(disponible, sin usar)* |

La mano fantasma del tutorial usa `pick`, `paint` y `eat` a −10 dB para no confundir con los sonidos reales.

**Música en bucle.** La constante `MUSIC` define las pistas `menu` (calmada, tipo caja de música) y `game` (más movida, con batería): compases de 4 tiempos con acordes, bajo, arpegio, melodía y percusión. `_compose()` las renderiza **en un hilo** (`WorkerThreadPool`) al arrancar el juego, y el `AudioStreamWAV` resultante tiene `loop_mode = LOOP_FORWARD`; las notas que pasan del final se enrollan al principio para que el bucle no tenga corte. `play_music()` cambia de pista con un fundido.

**Poner tu propia música o sonidos** (ver también `audio/README.md`):
- `audio/music/menu.ogg|mp3|wav` o `audio/music/game.ogg…` reemplazan las pistas procedurales y se ponen **en bucle solas** (`_loopable()` activa el bucle en una copia del stream).
- `audio/sfx/<nombre>.ogg|mp3|wav` reemplaza al efecto procedural con ese nombre.
- Cualquier pista nueva: `Sound.play_music("nombre")` busca `audio/music/nombre.*`; o directamente `Sound.play_music_stream(un_AudioStream)`.

| Función | Descripción |
|---|---|
| `play(sfx, pitch = 1.0, volume_db = 0.0)` | Reproduce un efecto. |
| `play_varied(sfx, spread = 0.06, volume_db = 0.0)` | Igual, con el tono un poco al azar (suena menos repetitivo). |
| `register_sfx(name, layers)` | Añade o reemplaza un efecto procedural con el formato de `SFX`. |
| `register_stream(name, stream)` | Usa un `AudioStream` tuyo como efecto. |
| `play_music(track)` / `play_music_stream(stream, id)` / `stop_music(fade)` | Música en bucle. Pedir la pista que ya suena no hace nada. |
| `set_music_volume(v)` / `set_sfx_volume(v)` | Volumen lineal 0–1 por bus; se guarda en `SaveData`. |
| `set_muted(v)` / `toggle_mute()` / `is_muted()` | Silencio general (bus `Master`); se guarda. El menú tiene un botón para esto. |

---

## Escenas: cómo funciona cada una

Todas las escenas con material propio usan `resource_local_to_scene = true` **y además** duplican el material en `_ready()`/`launch()`. Así, cada instancia tiene sus propios uniforms (si compartieran material, pintar una figura pintaría todas).

### `main_menu.tscn` — menú principal
Escena de arranque (`Node2D`, `main_menu.gd`). Instancia `Background` y `Slime` (`menu_slime.tscn`, en (905, 420), escala 1.35), un nodo `Decor` donde el script crea las figuras que flotan y un `Panel` (`ColorRect` con `menu_panel.gdshader`) con el `Title` (`animated_title.gd`), el subtítulo, los `Buttons` (4 `CreamButton`: Jugar/Continuar, Niveles, Cómo jugar, Salir), el `SoundButton` (interruptor de sonido) y el bloque `Help` (instrucciones + botón Volver), que se alterna con los botones.

### `menu_slime.tscn` — slime del menú
`Node2D` (`menu_slime.gd`) con un solo `Body` (`ColorRect` 340×340 con `monster.gdshader`). Sin colisión: la detección del ratón es por distancia.

### `cream_button.tscn` — botón crema
`ColorRect` (`cream_button.gd`, 380×80 por defecto, cursor de manita) con `menu_button.gdshader` (material local a la escena) y un `Label` hijo centrado que lleva el texto.

### `confirm_dialog.tscn` — confirmación
`Control` de pantalla completa (`confirm_dialog.gd`, oculto al inicio) con `Dim` (`ColorRect` oscuro que no captura el ratón; el clic lo recibe la raíz) y `Panel` (600×340, `menu_panel.gdshader` casi opaco, centrado por anclas) que contiene `Title`, `Message` y un `Buttons` (`HBoxContainer`) con `YesButton` y `NoButton` (instancias de `cream_button.tscn`). Está instanciada dentro de `hud.tscn`.

### `level_select.tscn` — menú de niveles
`Node2D` (`level_select.gd`) con `Background`, un `Panel` (`menu_panel.gdshader`, 1000×620) que contiene `Title`, `Subtitle`, un `Scroll` (`ScrollContainer` → `Margin` → `Grid` de 3 columnas, vacío en el editor: las tarjetas las crea el script), `BackButton` y `ResetButton` (`CreamButton`), y una `ConfirmLayer` (`CanvasLayer`, capa 10) con una instancia de `confirm_dialog.tscn`.

### `tutorial_ghost.tscn` — mano fantasma
`Node2D` (`tutorial_ghost.gd`) con tres nodos `Node2D` que llevan un `ColorRect` (`Body`, con `mouse_filter` en *ignore*): `ShapeGhost` (128×128, `shape.gdshader`, 75 % opaco), `BucketGhost` (90×90, `shape.gdshader`, 80 %) y `Hand` (220×220, `ghost_hand.gdshader`). El origen de `Hand` es la punta del dedo al señalar y el centro del puño al agarrar.

### `main.tscn` — escena principal del juego
Nodo raíz `Main` (`Node2D`, `main.gd`). Instancia `Background`, `Monster` (610, 229), `Palette` (1150, 136), `ShapeTray` (640, 620), `Eraser` (93, 287), `TutorialGhost` y `HUD`, más una `Camera2D` en (643, 360). Es la única escena que conoce a todas las demás: conecta el slime con el progreso y reparte los cambios de nivel. La bandeja se llena desde `Main`: con 3 figuras (nivel 1) quedan en x = 480, 640 y 800; con 5 (niveles 2 al 8, 10 y 11) en x = 320, 480, 640, 800 y 960; y con 2 (nivel 9, estrella y corazón) en x = 560 y 720.

### `background.tscn` — fondo
Un solo `ColorRect` de 1280×720 con `background.gdshader` y `mouse_filter = IGNORE` para no bloquear clics. No tiene script: todo es animación del shader (degradado ondulante, puntos que titilan y un piso oscuro desde el 80 % de la altura).

### `monster.tscn` — slime
`Area2D` (`monster.gd`, `input_pickable = false`) con:
- `Collision`: círculo de radio 140 — zona donde la figura "cuenta" como soltada sobre el slime.
- `Body`: `ColorRect` de 340×340 con `monster.gdshader` (el slime entero se dibuja aquí, **incluida la cara**; no hay nodos aparte para los ojos ni la boca).
- `AbsorbPoint`: `Marker2D` en (0, 20), hacia donde vuela la figura al ser comida.
- `RequestBubble`: instancia del globo, a la izquierda y un poco arriba (−205, −57).

### `request_bubble.tscn` — globo de petición
`Node2D` (`request_bubble.gd`) con dos `ColorRect`: `Bg` (200×200, `bubble.gdshader`) dibuja el globo con sus dos circulitos de cola, e `Item` (100×100, `shape.gdshader`) dibuja la figura pedida encima, reutilizando el mismo shader que las figuras reales.

### `shape.tscn` — figura
`Area2D` (`shape.gd`) con `Collision` (círculo r=52) y `Visual` (`ColorRect` de 128×128 con `shape.gdshader`). El script mueve y deforma `Visual` (no el `Area2D`), de modo que la zona de colisión se mantiene estable aunque el dibujo se estire y se incline. La misma escena sirve para las plantillas de la bandeja y para las figuras sueltas: lo único que cambia es `is_template`. El hover (cursor de manita, brillo y halo) solo se aplica a las plantillas.

### `shape_tray.tscn` — bandeja
`Node2D` (`shape_tray.gd`) con un `Board` (`ColorRect` + `tray.gdshader`) y sin figuras al inicio: `Main` la llena llamando a `set_allowed_shapes()` con las figuras del nivel. Su `shape_scene` apunta a `shape.tscn`.

### `paint_bucket.tscn` — bote de pintura
`Area2D` (`paint_bucket.gd`) con `Collision` (círculo r=45), `Visual` (`ColorRect` de 90×90 con **el mismo `shape.gdshader`** dibujando un círculo del color del bote) y `Label` (nombre del color, debajo). Su `Area2D` es pickable (a diferencia del slime y el borrador): es lo que el jugador agarra.

### `color_palette.tscn` — paleta
`Node2D` (`color_palette.gd`) con el tablero `Board` (`palette_board.gdshader`) y 4 instancias de `PaintBucket`, separadas 130 px en vertical: `Red` (mask 1), `Yellow` (2), `Blue` (4) y `Clean` (0).

### `eraser.tscn` — borrador
`Area2D` (`eraser.gd`, `input_pickable = false`) con `Collision` (círculo r=60), `Visual` (`ColorRect` de 130×130 con `eraser.gdshader`) y `Label` "Borrador". Solo sirve de destino de soltado.

### `hud.tscn` — interfaz
`CanvasLayer` (`hud.gd`) con `ScoreLabel` (arriba a la izquierda, fuente 30), `HintLabel` (arriba a la derecha, fuente 18, alineado a la derecha, oculto), `MenuButton` (`CreamButton` "Menú", abajo a la izquierda) y `ConfirmDialog` (instancia de `confirm_dialog.tscn`). El letrero de nivel se agrega por código en `_ready()`. Como es un `CanvasLayer`, no le afecta la cámara.

### `paint_burst.tscn` — estallido
`Node2D` (`paint_burst.gd`, `z_index = 5`) con un `ColorRect` de 260×260 y `paint_burst.gdshader`. Se instancia, se reproduce y se libera solo.

### `paint_drop.tscn` — gota
`Node2D` (`paint_drop.gd`, `z_index = 15`: por encima de las figuras y por debajo de un bote arrastrado, `z_index = 20`) con un `ColorRect` de 40×40 y `paint_drop.gdshader`. Se instancia, se lanza con `launch()` y se libera sola.

---

## Shaders y efectos visuales

Todos son `shader_type canvas_item`. La mayoría usa **campos de distancia con signo (SDF)**: una función que, para cada píxel, devuelve la distancia al borde de una figura (negativa dentro, positiva fuera). Con ella se obtiene el relleno (`1 - smoothstep(-aa, aa, d)`), el contorno (el mismo SDF desplazado) y el antialiasing automático (`aa = max(fwidth(d), 0.002)`) sin necesidad de texturas.

| Shader | Usado por | Propósito |
|---|---|---|
| `background.gdshader` | `background.tscn` | Fondo morado animado con degradado, puntos titilantes y piso. |
| `shape.gdshader` | `shape.tscn`, `paint_bucket.tscn`, `request_bubble.tscn` (`Item`) | Dibuja las 5 figuras con contorno, brillo, onda de pintura, resaltado y hover. |
| `monster.gdshader` | `monster.tscn`, `menu_slime.tscn` | El slime: silueta orgánica, respiración, aplastamiento, sombra y **cara** (ojos, boca, mejillas). |
| `bubble.gdshader` | `request_bubble.tscn` (`Bg`) | Globo de pensamiento. |
| `eraser.gdshader` | `eraser.tscn` | Goma rosa y azul inclinada con resalte al pasar una figura. |
| `paint_burst.gdshader` | `paint_burst.tscn` | Anillo expansivo + 10 chispas romboidales. |
| `paint_drop.gdshader` | `paint_drop.tscn` | Gota esférica con brillo. |
| `ghost_hand.gdshader` | `tutorial_ghost.tscn` (`Hand`) | Mano fantasma translúcida con brazo que se desvanece. `grab` mezcla la pose que señala con el puño. |
| `tray.gdshader` | `shape_tray.tscn` (`Board`) | Bandeja lila con un hueco por figura; crece con el número de casillas. |
| `palette_board.gdshader` | `color_palette.tscn` (`Board`) | Tabla de pintor de madera con un hueco por bote y el agujero del pulgar. |
| `menu_panel.gdshader` | `main_menu.tscn` (`Panel`), `confirm_dialog.tscn` (`Panel`) | Panel crema con borde, costura punteada, puntitos y sombra. |
| `menu_button.gdshader` | `cream_button.tscn` | Botón crema con grosor, brillo en el hover y hundimiento al presionar. |
| `title_letter.gdshader` | `animated_title.gd` (una por letra) | Recolorea el relleno de cada letra del título con colores cambiantes. |

### `background.gdshader`
**Uniforms:** `color_a` (morado oscuro `0.10, 0.08, 0.20`) y `color_b` (morado medio `0.24, 0.13, 0.40`).
1. **Degradado ondulante:** mezcla `color_a` → `color_b` según `UV.y`, perturbado por `0.05 * sin(UV.x * 6 + TIME * 0.5)`, de modo que la frontera de color "respira".
2. **Puntos que titilan:** divide la pantalla en una cuadrícula de 16×9 celdas; en el centro de cada una dibuja un puntito (`smoothstep` sobre la distancia al centro) cuyo brillo oscila con `sin(TIME + id.x * 3.1 + id.y * 1.7)`: la fase depende de la celda, así que no parpadean todos a la vez. Aportan un 5 % de luz.
3. **Piso:** desde `UV.y = 0.80` mezcla el color hacia `color_a * 0.55` con un corte casi duro (`smoothstep(0.80, 0.81, ...)`).

### `shape.gdshader`
**Uniforms:** `shape_type` (0 círculo, 1 cuadrado, 2 triángulo, 3 estrella, 4 corazón), `fill_color`, `old_color`, `wave` (0–1), `outline_color`, `outline` (grosor, 0.045), `selected` (0–1), `hover` (0–1; lo anima `shape.gd`).
- **SDFs:** `sd_circle`, `sd_box` (cuadrado con esquinas redondeadas, radio 0.06), `sd_triangle`, `sd_star5` (estrella de 5 puntas) y `sd_heart`, estas tres basadas en las fórmulas de Inigo Quilez. Las coordenadas se voltean en Y (`q = (p.x, -p.y)`) para que las figuras queden derechas, y cada una se desplaza/escala para quedar centrada y del mismo tamaño visual.
- **Onda de color:** el color nuevo se revela como un círculo que crece desde el centro: `reach = wave * 0.8`; el píxel muestra `fill_color` si está dentro del radio y `old_color` si no, con un borde suave de 0.1 (`smoothstep`). Con `wave >= 1.0` se salta el cálculo y muestra `fill_color` directo.
- **Contorno:** `inner` es el mismo SDF desplazado `outline` hacia dentro; la franja entre `inner` y la silueta es el contorno. Con `selected = 1`, el contorno se vuelve blanco (resaltado cuando un bote está cerca); el hover lo aclara hasta un 80 % (`max(selected, hover * 0.8)`).
- **Brillo:** una mancha de luz suave arriba a la izquierda (`shine`) suma 0.14 al color; además, un **destello** triangular durante la pintura (`0.35 * (1 - abs(wave * 2 - 1))`, máximo cuando `wave = 0.5`).
- **Hover:** con `hover > 0` el relleno se ilumina un 10 % y aparece un **halo blanco** justo fuera de la silueta (`glow = hover * 0.5 * (1 - smoothstep(0, 0.06, max(d, 0)))`, el mismo SDF visto desde fuera). El alfa final es `max(alpha, glow)` y el color se mezcla con blanco solo en proporción al halo (`alpha / max(a2, 0.001)`), para no ensuciar el antialiasing de los bordes cuando `hover = 0`.
- Se reutiliza tal cual para los botes de pintura (siempre `shape_type = 0`) y para la figura dentro del globo.

### `monster.gdshader`
**Uniforms:** `body_color`, `excite` (0–1: se agita), `squish` (−1 estirado … 1 aplastado), `idle_squish` (0.05) e `idle_speed` (2.4).
- **Silueta:** `slime_sd` une dos elipses (una angosta arriba, una ancha abajo) con `smin` (mínimo suave, `k = 0.5`) para dar forma de gominola con la punta redondeada y recorta la base con `smax` contra la línea del piso `FLOOR_Y = 0.64` (`k = 0.12`) para que el fondo quede plano. `ell_sd` es una aproximación barata del SDF de una elipse.
- **Squish que conserva el volumen:** `sy = clamp(1 − 0.32·squish + idle, 0.6, 1.4)` y `sx = 1 / sqrt(sy)`. La transformación está **anclada al piso** (`FLOOR_Y`), así el slime se aplasta contra el suelo sin despegarse. El latido constante `idle` es `idle_squish · sin(TIME · idle_speed)` y se suma un temblor rápido (`0.06 · excite · sin(TIME · 10)`); además la silueta ondula horizontalmente con `excite`.
- **Capas:** contorno claro (`d − 0.045`), borde (`rim`, el color mezclado un 42 % con blanco), relleno interior (más pequeño y desplazado, con degradado de arriba a abajo) y un **puntito blanco con halo** arriba como brillo.
- **Sombra:** una elipse suave en el piso, con alfa 0.25 y ancho proporcional a `sx`, que se compone con premultiplicación manual de alfa al final.
- **Cara:** se dibuja encima del relleno, en las mismas coordenadas deformadas `q`, así que **se aplasta y se estira junto con el cuerpo**. La controla `slime_face.gd` con estos uniforms (todos con un valor por defecto que equivale a la cara `IDLE`):

| Uniform | Rango | Efecto |
|---|---|---|
| `eye_open` | 0–1 | 0 = ojo reducido a una rayita (cerrado); 1 = ojo ovalado abierto. |
| `eye_happy` | 0–1 | Mezcla hacia el ojo feliz en arco `^`. |
| `eye_size` | ≈1–1.45 | Escala de los ojos. |
| `shine` | ≈1–2 | Tamaño de los brillos del ojo (alto = ojos llorosos/brillantes). |
| `brow` | −1 a 1 | Inclina el párpado: −1 triste (cae el lado externo), +1 enojado (cae el interno). |
| `blink` | 0–1 | Parpadeo; multiplica a `eye_open`. |
| `look` | vec2 | Desplaza ojos, mejillas y boca hacia donde mira. |
| `mouth_curve` | −1 a 1 | −1 ceño, 0 recta, 1 sonrisa. |
| `mouth_open` | 0–1 | 0 = línea; más = se abre entre dos curvas (aparece el interior rojo y, bien abierta, la lengua). |
| `mouth_width` | ≈0.45–1.15 | Ancho (0.45 da la "o" de sorpresa). |
| `blush` | 0–1 | Opacidad de las mejillas rosadas. |
| `tears` | 0–1 | Opacidad de las lágrimas (dos gotas que nacen bajo los ojos, caen y se desvanecen). |
| `sparkle` | 0–1 | Opacidad de tres destellos de cuatro puntas que titilan alrededor del slime (se dibujan en `p`, fuera del cuerpo, y no se deforman). |

  - **Colores de la cara:** ojos y boca son una versión oscura del color del cuerpo (`body_color × 0.26`, como en Slime Rancher); si el cuerpo ya es oscuro (p. ej. marrón) se acercan a un casi negro según su luminancia. La lengua es el color del cuerpo aclarado un 30 %.
  - `eye_face(e, side)` devuelve la máscara del ojo y la de sus brillos: un óvalo vertical (`ell_sd`) que se aplana al cerrar, recortado por un plano inclinado (`brow`) y mezclado con un arco (distancia a una parábola) según `eye_happy`; los brillos son un punto blanco grande arriba a la izquierda (crece con `shine`) y uno chico abajo a la derecha.
  - `tear_drop(e, side, ph)` dibuja una gota que sube su `t = fract(TIME · 0.7 + ph)` hacia abajo y se encoge y desvanece.
  - `star4(p, r)` es el destello de cuatro puntas (curva tipo astroide).
  - `mouth_face(m)` calcula la distancia a un **segmento curvo** (la parábola `top` entre las comisuras) que se estira hasta una segunda curva `bot` al abrir la boca, formando una "D": el borde de arriba se aplana al abrir (`mix(0.09, 0.045, mouth_open)`) y el de abajo es redondo. El grosor de la línea es el radio restado a esa distancia; la lengua es una elipse en el fondo recortada por el interior de la boca.
- Todos los colores salen de `body_color` (aclarado para el borde y el fondo pálido, oscurecido un 10 % para la parte inferior), por eso al cambiar de color solo hay que tocar un uniform.

### `bubble.gdshader`
**Uniforms:** `bubble_color` (blanco), `outline_color` (morado casi negro).
Un rectángulo redondeado centrado en (0, −0.12) con semitamaño (0.34, 0.22) y radio 0.12, más dos círculos pequeños (r = 0.07 y 0.045) abajo a la derecha que forman la cola del globo (hacia el slime). Se combinan con `min` (unión de SDF). El contorno se logra con un segundo `smoothstep` desplazado 0.02.

### `eraser.gdshader`
**Uniform:** `hover` (0–1).
Un rectángulo redondeado rotado −0.4 rad (la rotación se aplica a las coordenadas, no al nodo). Se divide en dos bandas verticales (rosa a la izquierda, azul a la derecha, corte en `q.x = 0.10`) separadas por una línea blanca fina; una luz suave en la parte superior le da volumen. Con `hover` sube un 25 % hacia blanco y el contorno pasa de morado oscuro a blanco.

### `paint_burst.gdshader`
**Uniforms:** `progress` (0–1, lo anima `paint_burst.gd`), `burst_color`.
- **Easing:** `e = 1 − (1 − progress)³` (salida cúbica) para que la expansión sea rápida al inicio y frene.
- **Anillo:** radio de 0.4 a 0.9, con grosor y opacidad que se reducen con `fade = 1 − progress`.
- **Chispas:** un bucle de 10 rombos (distancia L1: `|dx| + |dy|`), colocados cada 36° (`0.6283` rad) con un desfase de 0.3 rad; se alejan del centro con `e` y se encogen con `fade`. Se alternan entre blanco y `burst_color` según la paridad del índice (`mod(fi, 2.0)`), y la distancia final alterna también (0.65 / 0.85).

### `paint_drop.gdshader`
**Uniform:** `drop_color`.
Un círculo de radio 0.38 con un degradado radial (más oscuro, ×0.78, hacia el borde) y un brillo blanco pequeño arriba a la izquierda, en (−0.12, −0.12), que lo hace parecer una gota de pintura brillante.

---

## Técnicas de animación usadas

**Suavizado exponencial (independiente de los FPS).** En lugar de `lerp(a, b, 0.2)`, se usa `lerp(a, b, 1.0 − exp(−k · delta))`: da el mismo resultado visual a 30 o a 144 FPS. Se usa en el seguimiento del ratón (`k = 24` en figuras, `30` en botes), en `excite` del slime (`k = 10`) en `hover` del borrador (`k = 12`) y en el hover de las figuras de la bandeja (`k = 14`).

**Resortes subamortiguados.** Para la sensación de gelatina, `Shape` y `PaintBucket` integran a mano (Euler semiimplícito):

```
vel += ((objetivo − valor) * rigidez − vel * amortiguación) * dt
valor += vel * dt
```

| Resorte | Rigidez | Amortiguación | Objetivo |
|---|---|---|---|
| Inclinación (`_sway`) | 170 | 7 | proporcional a la velocidad en X (máx. ±0.45 rad en figuras, ±0.5 en botes) |
| Estiramiento (`_stretch`, solo figuras) | 190 | 8 | proporcional a `|vx| − |vy|` (máx. ±0.2) |
| Levantada (`_lift`) | 220 | 12 | 0.12 al arrastrar figuras, `0.10 × _hover` sobre una plantilla, 0.25 con botes, 0 en reposo |

Como la amortiguación es baja respecto a la rigidez, el valor **sobrepasa y oscila** antes de asentarse: ese temblor es la gelatina. Los golpes (al agarrar, soltar o pintar) se aplican sumando impulsos directamente a `*_vel`. `dt` se limita a `0.033` para que un salto de frame no haga explotar el resorte. Estos resortes solo modifican el `ColorRect` visual, nunca el `Area2D`, así la colisión no se deforma.

**Hover.** El feedback de las plantillas combina tres cosas sobre el mismo `visual`: el resorte `_lift` (crece con rebote), un meneo senoidal pequeño y un salto vertical de 8 px, todos escalados por `_hover` (0–1, suavizado exponencial). En el shader, `_hover` ilumina la figura y dibuja el halo. Al soltar el cursor, `_hover` baja a 0 y el resorte hace que la figura regrese con el mismo rebote.

**Caras por parámetros continuos.** La cara no cambia de dibujo: cada estado de ánimo (`SlimeFace.Mood`) es una tabla de ocho números y cada frame los uniforms se acercan a ella con el mismo suavizado exponencial (`k = 12`). Por eso al pasar de *excitado* a *feliz* los ojos se curvan y la boca se abre gradualmente en vez de saltar. Los gestos temporales se encadenan con `play([[mood, segundos], ...])` y el parpadeo y la mirada son capas aparte (`blink`, `look`) que se suman a cualquier estado.

**Tweens.** Se usan para animaciones de un solo disparo: apariciones con `TRANS_BACK` (rebote al entrar), sacudidas con `TRANS_ELASTIC`, y `tween_method` para animar uniforms de shaders (`wave`, `progress`, `body_color`).

---

## Cambios recientes y notas conocidas

**Cambios recientes**
- **Cara del slime con shaders:** `monster.gdshader` dibuja ojos, mejillas y boca (uniforms `eye_*`, `mouth_*`, `brow`, `blink`, `look`, `blush`) y la nueva clase `SlimeFace` (`scripts/slime_face.gd`) elige y anima la cara según la acción: emocionado con una figura encima, masticando y feliz al comer, festejo al subir de nivel, triste al rechazar, sorprendido al tocarlo en el menú y con sueño tras 14 s sin actividad. Parpadea y sigue el ratón con la mirada. `Monster` y `MenuSlime` la usan; `Main` llama a `monster.celebrate()` al subir de nivel.
- **Menú de niveles y guardado:** nueva escena `level_select.tscn` (+ `level_select.gd`) con una tarjeta por nivel de `GameData.STAGES` (superados con ★, actual con brillo, el resto bloqueados) y la clase estática `SaveData` que guarda en `user://shapes_save.cfg` el nivel más alto alcanzado. *Jugar* pasa a *Continuar*; `CreamButton` ganó `disabled` y `emphasized`.
- **Sistema de sonido procedural:** nuevo autoload `Sound` (`sound_manager.gd`) con 13 efectos y 2 pistas de música en bucle generados por código (sin archivos), buses `Music`/`SFX`, volumen y silencio guardados, y la posibilidad de reemplazarlos o añadir los tuyos en `audio/`. Los sonidos están conectados a botones, figuras, botes, slime, menú y tutorial.
- **Tutorial con mano fantasma:** nueva escena `tutorial_ghost.tscn` (+ `tutorial_ghost.gd` y `ghost_hand.gdshader`). Al empezar cada nivel demuestra cómo cumplir la petición: agarra la figura de la bandeja, la pinta con los botes necesarios (se ve cómo se mezclan los colores) y se la lleva al slime. Se corta con el primer clic y reaparece como ayuda a los 15 s sin clics. Para esto se añadieron `Monster.request_changed` / `is_busy()`, `ShapeTray.slot_position()`, `ColorPalette.bucket_position()` y `HUD.is_dialog_open()`; `GameData` admite `"tutorial": false` por nivel y `Main` el export `tutorial`.
- **Slime estilo Slime Rancher:** silueta de gominola con brillo lateral, ojos ovalados oscuros con dos brillos, boca en "D" con lengua y colores de cara derivados del color del cuerpo. Las expresiones son más exageradas (ojos llorosos, lágrimas, destellos de fiesta) y se controlan con los nuevos uniforms `shine`, `tears` y `sparkle`.
- **Confirmación al volver al menú:** nueva escena `confirm_dialog.tscn` (+ `confirm_dialog.gd`) dentro del HUD. El botón **Menú** y la tecla Esc ya no cambian de escena directamente: llaman a `HUD.request_exit()` y solo **Sí, salir** vuelve al menú.
- **Once niveles en `GameData.STAGES`:** se añadieron *Nuevas formas*, *Naranja*, *Verde*, *Morado*, *Marrón*, *Estrellas y corazones* y *Maestro de colores* (antes eran 4). Ahora el marrón sí se pide y el nivel 9 quita figuras de la bandeja.
- **La bandeja ofrece solo las figuras del nivel:** `ShapeTray` ya no crea las 5 figuras en `_ready()`; `set_allowed_shapes()` (llamada desde `Main._apply_stage`) las crea, quita y centra según `STAGES[n].shapes`, y `_on_shape_left` solo repone tipos permitidos.
- **Feedback de hover en las figuras de la bandeja:** nuevo uniform `hover` en `shape.gdshader` (iluminación y halo), resorte de levantada, meneo y saltito en `shape.gd::_update_jelly()`, y cursor de manita.

**Notas conocidas**

- **`HintLabel` está oculto en `hud.tscn`** (`visible = false`) y `HUD.set_hint()` solo cambia el texto, sin mostrarlo, así que las pistas de cada nivel (`hint` en `STAGES`) hoy no se ven en pantalla. El texto por defecto de la escena además describe un flujo anterior ("Toca una figura para pintarla"). Para activarlo basta con quitar `visible = false` o llamar a `show()`.
- **`food_rejected` no tiene ningún receptor.** El slime la emite al rechazar (y pone su cara triste él mismo, sin usar la señal), pero ningún otro script la escucha: es un buen punto de enganche para sonido o un contador de errores.
- **El marrón (7)** se obtiene mezclando los tres primarios y solo se pide en los niveles 8, 9 y 11. Si el slime se come una figura marrón se vuelve marrón, y su cara se oscurece automáticamente para seguir viéndose.
- **Las pistas de los niveles nuevos tampoco se ven** mientras `HintLabel` siga oculto (ver la primera nota): el letrero de inicio solo muestra el nombre del nivel.
- **El tutorial fantasma solo demuestra la petición actual:** no enseña el bote "Limpiar" ni el borrador (si una figura se pinta mal, el jugador debe descubrirlo). La mano se detiene con cualquier clic izquierdo, incluso uno fuera de las figuras.
- **El guardado solo recuerda el nivel alcanzado**, no los aciertos dentro del nivel (al continuar empieza ese nivel de nuevo desde 0). Si eliminas o reordenas niveles en `GameData`, el índice guardado se ajusta al rango, pero puede apuntar a otro nivel.
- **Los volúmenes y las notas de `SFX`/`MUSIC` son un punto de partida** y se ajustan en `sound_manager.gd`. La música procedural tarda un par de segundos en generarse al abrir el juego (corre en un hilo), así que el primer segundo del menú puede estar en silencio. Los sonidos de la mano fantasma, del hover y del tutorial son suaves a propósito.
- **Al iniciar, el slime hace dos peticiones seguidas:** una en `Monster._ready()` y otra cuando `Main._ready()` aplica el nivel. Es inocuo (la segunda sustituye a la primera antes del primer frame).
- **El texto del borrador** (`"Borrador"`) está escrito directamente en `eraser.tscn`, a diferencia de los botes, cuyo rótulo sale de `GameData`.
- **El ancho del letrero de nivel** (`1280`) está fijo en `hud.gd`; con otra resolución base habría que cambiarlo o anclarlo.
- **Los límites de arrastre** usan `get_viewport_rect()`, que no considera la posición de la `Camera2D` (643, 360, 3 px a la derecha del centro). El margen de 50 px lo absorbe sin problemas.
- `request_bubble.gd` está indentado con espacios; el resto de scripts usa tabulaciones. Funciona (cada archivo es coherente consigo mismo), pero conviene unificar.
- El proyecto declara `Jolt Physics` como motor 3D, pero no hay ningún nodo 3D: el ajuste no tiene efecto.
- **El hover solo se aplica a las plantillas de la bandeja** y cambia el cursor global con `Input.set_default_cursor_shape`. Si el cursor pasa directo de una figura a otra, puede quedarse un instante en flecha entre las dos (el orden de `mouse_exited` / `mouse_entered` no está garantizado). Para que también ocurra con figuras sueltas, quita la condición `is_template` en `_update_jelly()` y `_on_mouse_entered()`.
- **El halo del hover puede recortarse en las puntas de la estrella**, porque el `Visual` mide 128×128 y la estrella ocupa casi todo. Si se nota, reduce el ancho del halo (`0.06` → `0.04`) en `shape.gdshader`.
- **`set_allowed_shapes()` soporta que un nivel quite figuras** (las plantillas sobrantes desaparecen con `vanish()`): el nivel 9 (*Estrellas y corazones*) lo usa por primera vez al pasar de 5 figuras a 2, y el 10 vuelve a ofrecer las 5.
