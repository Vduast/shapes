# SHAPES

Juego educativo 2D para niños desarrollado con **Godot Engine 4.7 (GDScript)**. Un slime con un globo de pensamiento **pide una figura** (círculo, cuadrado, triángulo, estrella o corazón) y, según el nivel, también un **color**. El jugador arrastra la figura hasta el slime; en los niveles avanzados primero tiene que **pintarla con botes de pintura de colores primarios y mezclarlos** (rojo + amarillo = naranja, etc.). Todo el dibujo del juego es **procedural**: no hay una sola imagen, cada figura, el slime, los botes, el borrador, los globos y los efectos se dibujan con **shaders** (campos de distancia con signo, SDF) sobre `ColorRect`.

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
   - [shape.gd](#shapegd)
   - [shape_tray.gd](#shape_traygd)
   - [paint_bucket.gd](#paint_bucketgd)
   - [color_palette.gd](#color_palettegd)
   - [eraser.gd](#erasergd)
   - [request_bubble.gd](#request_bubblegd)
   - [paint_burst.gd](#paint_burstgd)
   - [paint_drop.gd](#paint_dropgd)
   - [hud.gd](#hudgd)
9. [Escenas: cómo funciona cada una](#escenas-cómo-funciona-cada-una)
10. [Shaders y efectos visuales](#shaders-y-efectos-visuales)
11. [Técnicas de animación usadas](#técnicas-de-animación-usadas)
12. [Notas conocidas](#notas-conocidas)

---

## Descripción general

SHAPES es un juego de arrastrar y soltar con cuatro niveles progresivos:

- Un **slime** (`Monster`) en el centro de la pantalla muestra en un globo de pensamiento la figura (y el color) que quiere comer.
- Una **bandeja** (`ShapeTray`) en la parte inferior ofrece las 5 figuras, siempre disponibles: al sacar una, la bandeja repone otra igual.
- Una **paleta** (`Palette`) a la derecha con 3 botes de pintura (rojo, amarillo, azul) y un bote de "Limpiar". Se activa a partir del nivel 2.
- Un **borrador** (`Eraser`) a la izquierda para deshacerse de las figuras que sobran.
- Un **HUD** con el nivel, el progreso, una pista y un letrero grande que anuncia cada nivel nuevo.
- Mucho "juice" (sensación de gelatina): resortes que inclinan y estiran las figuras al moverlas, gotas de pintura que escurren, estallidos de chispas y un slime que respira, se agita y se aplasta al comer.

> **Nota de arquitectura:** el proyecto no usa texturas ni sprites. Cada `ColorRect` lleva un `ShaderMaterial` que calcula la forma con matemáticas en el fragmento. Los datos del juego (colores, niveles, peticiones) viven en una clase estática, `GameData`, que no es un nodo ni un autoload: se usa como `GameData.STAGES`, `GameData.mask_to_color(...)`, etc. desde cualquier script.

---

## Cómo se juega

| Nivel | Nombre | Qué pide el slime | Paleta | Aciertos para pasar |
|---|---|---|---|---|
| 1 | Formas | Solo la forma (círculo, cuadrado o triángulo), cualquier color | No | 5 |
| 2 | Colores primarios | Forma (las 5) + color primario (rojo, amarillo o azul) | Sí | 6 |
| 3 | Mezclas | Forma + cualquier color, incluidos naranja, verde y morado | Sí | 6 |
| 4 | ¡Todo junto! | Igual que el 3, sin fin | Sí | ∞ (el HUD muestra ★ con los aciertos) |

1. Mira lo que pide el globo del slime.
2. Si pide un color: arrastra un **bote de pintura** sobre una figura suelta para pintarla (los colores se **mezclan**). El bote regresa solo a su lugar.
3. Arrastra la figura hasta el slime y suéltala encima. Si coincide, se la come y cambia de color; si no, la rechaza y la figura sale despedida.
4. Para borrar una figura o repintarla desde cero: suéltala sobre el **borrador**, o usa el bote **Limpiar** (vuelve la figura a blanco).
5. Las figuras sueltas desaparecen solas tras 45 s sin tocarlas (parpadean durante los últimos 6 s).

---

## Tecnología utilizada

| Componente | Detalle |
|---|---|
| Motor | Godot Engine 4.7 (renderer Forward+) |
| Lenguaje | GDScript |
| Dibujo | Shaders `canvas_item` sobre `ColorRect` (SDF analíticos: sin texturas ni sprites) |
| Interacción | `Area2D` con `input_pickable` + detección de solapamientos (`get_overlapping_areas()`) |
| Animación | `Tween` + resortes subamortiguados calculados a mano en `_process` |
| Plugins de editor | `script-ide` (solo editor, no forma parte del juego) |
| Alcance | Sin red, sin audio y sin autoloads; el proyecto no incluye presets de exportación |

---

## Estructura del proyecto

```
shapes/
├── scenes/                  # Escenas (.tscn)
│   ├── main.tscn            #   Escena principal: ensambla todo
│   ├── background.tscn      #   Fondo animado (ColorRect + shader)
│   ├── monster.tscn         #   Slime que pide y come figuras
│   ├── request_bubble.tscn  #   Globo de pensamiento con la figura pedida
│   ├── shape.tscn           #   Figura arrastrable (plantilla de la bandeja y figuras sueltas)
│   ├── shape_tray.tscn      #   Bandeja que reparte y repone figuras
│   ├── color_palette.tscn   #   Contenedor de los 4 botes de pintura
│   ├── paint_bucket.tscn    #   Bote de pintura individual
│   ├── eraser.tscn          #   Borrador
│   ├── hud.tscn             #   Interfaz (nivel, progreso, pista)
│   ├── paint_burst.tscn     #   Efecto: anillo + chispas
│   └── paint_drop.tscn      #   Efecto: gota de pintura
├── scripts/                 # Lógica en GDScript (un .gd por escena + game_data.gd)
├── shaders/                 # 8 shaders .gdshader (todo el arte del juego)
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
| Escena principal | `res://scenes/main.tscn` |
| Versión de Godot | `4.7` (Forward Plus) |
| Resolución base | `1280 x 720` |
| Modo de estiramiento | `canvas_items`, aspecto `expand` (la interfaz se escala con la ventana) |
| Plugin de editor habilitado | `script-ide` |
| Motor de física 3D | `Jolt Physics` (no se usa: el juego es 2D) |
| Driver de renderizado (Windows) | `d3d12` |

El proyecto **no define autoloads, grupos globales, acciones de entrada ni buses de audio**. Todo el input es de ratón y se procesa dentro de cada `Area2D`.

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
├── Palette             (Node2D, color_palette.gd)  pos (1101, 136)
│   ├── Red / Yellow / Blue / Clean   (instancias de PaintBucket, cada 130 px hacia abajo)
├── ShapeTray           (Node2D, shape_tray.gd)     pos (640, 620)
├── Eraser              (Area2D, eraser.gd)         pos (93, 287)
├── HUD                 (CanvasLayer, hud.gd)
└── Camera2D                                        pos (643, 360)
```

### Ciclo de una jugada

1. `Main._ready()` activa el orden de picking del viewport, conecta `Monster.food_accepted` y aplica el nivel inicial.
2. El `Monster` elige una petición al azar con `GameData.random_request()` y la muestra en su `RequestBubble`.
3. El jugador saca una `Shape` de la bandeja. Al moverla más de 8 px deja de ser plantilla y emite `left_tray`; la `ShapeTray` crea una nueva del mismo tipo.
4. (Niveles 2+) El jugador arrastra un `PaintBucket` sobre la figura. Al soltarlo, el bote llama a `shape.paint(mask)`: el color se **mezcla con OR de bits** y se anima una onda de color.
5. Al soltar la figura, `Shape._end_drag()` revisa qué `Area2D` tiene debajo:
   - si es el slime → `Monster.try_eat(shape)`;
   - si es el borrador → `Eraser.erase_shape(shape)`.
6. Si el slime la acepta: se la come, cambia de color, emite `food_accepted` y `Main` suma progreso. Si el progreso alcanza la meta del nivel, sube de nivel (letrero, confeti y paleta con animación).
7. Al terminar de comer, el slime pide otra cosa distinta de la anterior.

### Comunicación entre escenas

Las escenas se hablan por **señales hacia arriba** y **llamadas a métodos hacia abajo**. Además, para no acoplar clases, se usa *duck typing*: cada objeto pregunta `has_method("...")` sobre lo que tiene encima en lugar de comprobar su tipo.

| Quién pregunta | Método que busca (`has_method`) | Qué descubre |
|---|---|---|
| `Monster._process` | `get_eaten` | Hay una figura encima → se emociona (`excite`) |
| `Eraser._process` | `is_dragging` | Hay una figura arrastrándose encima → se resalta |
| `PaintBucket._find_target` | `can_paint` | Figuras pintables cercanas (imán y resaltado) |
| `Shape._end_drag` | `try_eat` / `erase_shape` | Soltó la figura sobre el slime / sobre el borrador |

| Señal | Emisor | Receptor |
|---|---|---|
| `food_accepted(shape_type, mask)` | `Monster` | `Main._on_food_accepted` (avanza progreso y niveles) |
| `food_rejected(shape_type, mask)` | `Monster` | *(nadie conectado por ahora)* |
| `left_tray(shape)` | `Shape` | `ShapeTray._on_shape_left` (repone la figura, con `bind(type)`) |

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

`ANY_COLOR = -1` es el valor especial de `wanted_mask` que significa "el slime acepta cualquier color; solo importa la forma". El marrón se puede fabricar pero **nunca se pide** (no aparece en ninguna lista `masks`).

**Definición de niveles (`STAGES`):**

| Campo | Significado |
|---|---|
| `name` | Nombre mostrado en el letrero de nivel |
| `hint` | Texto de ayuda para el HUD |
| `shapes` | Tipos de figura que puede pedir (índices de `ShapeType`: 0 círculo, 1 cuadrado, 2 triángulo, 3 estrella, 4 corazón) |
| `masks` | Colores que puede pedir (vacío = cualquier color) |
| `goal` | Aciertos para pasar al siguiente nivel (`0` = nivel final, infinito) |
| `palette` | Si se muestran los botes de pintura |

---

## Documentación de scripts y funciones

### `game_data.gd`
**Clase:** `GameData` — **Hereda de:** `RefCounted`. Repositorio estático de datos y reglas del juego; no se instancia.

**Enum y constantes**
- `ShapeType { CIRCLE, SQUARE, TRIANGLE, STAR, HEART }` — los 5 tipos de figura (coinciden con el `shape_type` de `shape.gdshader`).
- `RED = 1`, `YELLOW = 2`, `BLUE = 4`, `ANY_COLOR = -1`.
- `COLORS` / `NAMES` — diccionarios `máscara → Color` y `máscara → nombre en español`.
- `STAGES` — array con la configuración de los 4 niveles (ver tabla anterior).

| Función | Descripción |
|---|---|
| `mask_to_color(mask)` | Devuelve el `Color` de una máscara; si no existe, el blanco (`COLORS[0]`). |
| `mask_to_name(mask)` | Devuelve el nombre en español de la máscara, o `"?"`. |
| `random_request(stage, last = {})` | Elige una petición `{shape, mask}` al azar según el nivel (con `clampi` sobre el índice). Si el nivel no tiene `masks`, usa `ANY_COLOR`. Intenta hasta **12 veces** no repetir la petición anterior (`last`); si no lo logra, se queda con la última. |

---

### `main.gd`
**Hereda de:** `Node2D` — Director del juego: progreso, niveles y celebración.

**Exportado:** `start_stage` (0–3) — nivel con el que empieza; útil para probar un nivel directamente desde el Inspector.

**Variables:** `stage` (nivel actual), `progress` (aciertos en el nivel). Referencias a `$Monster`, `$Palette` y `$HUD`.

| Función | Descripción |
|---|---|
| `_ready()` | Llama a `randomize()`, activa el orden y el "solo el primero" del picking del viewport, conecta `monster.food_accepted` y aplica el nivel inicial (limitado con `clampi`). |
| `_apply_stage(celebrate)` | Configura el nivel actual: `monster.set_stage(stage, not celebrate)`, `palette.set_enabled(cfg.palette, celebrate)`, la pista del HUD y el progreso. Con `celebrate = true` (cambio de nivel) además muestra el letrero `¡Nivel N!  Nombre` y lanza el confeti. En un cambio de nivel el slime **no** cambia de petición al instante: la nueva llega cuando termina de comer. |
| `_update_hud()` | Envía al HUD nivel, aciertos y meta. |
| `_on_food_accepted(...)` | Suma 1 al progreso. Si la meta es mayor que 0, se alcanzó y no es el último nivel, sube de nivel y reinicia el progreso; si no, solo actualiza el HUD. |
| `_confetti()` | Instancia 6 `PaintBurst` en círculo (radio 170 px) alrededor del slime, uno por cada color [rojo, amarillo, azul, naranja, verde, morado], con escala 1.3. |

---

### `monster.gd`
**Clase:** `Monster` — **Hereda de:** `Area2D`. El slime: pide, acepta/rechaza figuras y se anima a través de su shader.

**Señales:** `food_accepted(shape_type, mask)`, `food_rejected(shape_type, mask)`.

**Exportado:** `start_color` (por defecto `Color(0.35, 0.75, 0.85)`) — color inicial del cuerpo.

**Estado:** `wanted_shape`, `wanted_mask`, `stage`; internos `_excite`, `_squish`, `_busy`, `_current_color`, `_last_request`.

| Función | Descripción |
|---|---|
| `_ready()` | Duplica el material del cuerpo (para que cada slime tenga el suyo), aplica `start_color` y hace la primera petición. |
| `_process(delta)` | Si no está ocupado, detecta con `get_overlapping_areas()` si hay una figura encima (`has_method("get_eaten")`) y suaviza `_excite` hacia 1 o 0 (`lerp` exponencial, factor 10). Cada frame envía `excite` y `squish` al shader. |
| `set_stage(value, refresh)` | Cambia el nivel; con `refresh = true` pide algo nuevo de inmediato. |
| `new_request()` | Pide una petición con `GameData.random_request(stage, _last_request)` y la muestra en el globo. Si acepta cualquier color, la figura del globo se dibuja en blanco. |
| `try_eat(shape)` | Punto de entrada que llama la figura al soltarse encima. Si está ocupado devuelve `false`. Compara forma y color (`ANY_COLOR` ignora el color). Acepta (`_accept`) o rechaza (`_reject`) y devuelve el resultado. |
| `_accept(shape)` | Se marca ocupado, ordena a la figura volar al `AbsorbPoint` (`get_eaten`), cambia de color si la figura estaba pintada (una figura blanca no cambia el color del slime), emite `food_accepted`, y anima: `_excite` a 1 y bajando en 0.7 s, y `_squish` 1.0 → −0.6 → 0 (aplasta, estira y rebote elástico). Al final (~0.87 s) llama a `_finish_eating()`. |
| `_finish_eating()` | Libera el estado ocupado y pide una nueva petición (ya con el nivel nuevo, si cambió). |
| `_reject(shape)` | Emite `food_rejected` y hace un gesto de "no" con `_squish` (0.5 → −0.3 → 0, ~0.46 s) mientras está ocupado. |
| `_change_color(to)` | Interpola el color del cuerpo del color actual al nuevo en 0.5 s con `tween_method`. |
| `_set_body_color(c)` | Escribe el uniform `body_color` del shader. |

---

### `shape.gd`
**Clase:** `Shape` — **Hereda de:** `Area2D`. La figura arrastrable. Es el script más complejo: arrastre, pintura, ciclo de vida y el efecto gelatina.

**Señal:** `left_tray(shape)` — se emite cuando una plantilla sale de la bandeja.

**Constantes:** `BURST` (escena del estallido), `WARNING_TIME = 6.0` (segundos de parpadeo antes de desaparecer).

**Exportados:** `shape_type` (enum: Círculo, Cuadrado, Triángulo, Estrella, Corazón), `lifetime` (45 s; 0 = nunca desaparece) y `jelly` (0 = rígida, 1 = normal, 2 = exagerada).

**Estado:** `color_mask` (0–7), `is_template` (`true` mientras está en la bandeja: no se puede pintar). Internos de arrastre (`_dragging`, `_moved`, `_vanishing`, `_grab_offset`, `_press_mouse`) y de gelatina (`_sway`, `_stretch`, `_lift`, `_tremor` con sus velocidades).

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
| `_ready()` | Duplica el material, centra el pivote del visual y guarda su posición base. |
| `_refresh()` | Envía tipo y color al shader (`shape_type`, `fill_color`, `old_color`, `wave = 1`). |
| `_input_event(...)` / `_input(event)` | Pulsar sobre la figura inicia el arrastre; soltar el botón izquierdo en cualquier parte lo termina (por eso va en `_input`, para no perder el "soltar" si el cursor se sale). |
| `_process(delta)` | Actualiza la gelatina. Si se arrastra: tras mover **más de 8 px** deja de ser plantilla y emite `left_tray`; sigue al ratón con retraso suave (`lerp` exponencial, factor 24), limitada a la pantalla menos 50 px de margen. Si está suelta: cuenta `_idle`, parpadea (alpha 0.5–1) los últimos 6 s y llama a `vanish()` al agotarse. |
| `_update_jelly(delta)` | Calcula la velocidad real de la figura y mueve **solo el dibujo** (`visual`) con 3 resortes subamortiguados: inclinación (según velocidad X), estiramiento (horizontal vs. vertical) y "levantada" (crece al agarrarla), más un temblor sinusoidal que se apaga tras soltarla. Ver [Técnicas de animación](#técnicas-de-animación-usadas). |
| `_start_drag()` | Guarda el desplazamiento entre el cursor y el centro, sube `z_index` a 10, da un saltito y se mueve al final de la lista de hijos (se dibuja por encima). |
| `_end_drag()` | Si solo fue un clic (sin mover) no hace nada. Si se movió: golpecito de gelatina y revisa los `Area2D` solapados — el primero con `try_eat` (slime) la ofrece; si la rechaza la empuja lejos (`_push_away`); el primero con `erase_shape` (borrador) la borra. |
| `_push_away(center)` | Si el slime la rechaza, la lanza 240 px en dirección contraria al slime (limitada a pantalla) con `TRANS_BACK`. |
| `_touch()` | Reinicia el temporizador de vida y restaura el alpha. |
| `_spawn_burst(color)` | Instancia un `PaintBurst` en la posición de la figura. |
| `_kill_tween()` | Detiene el `Tween` activo para que no se pisen animaciones. |

---

### `shape_tray.gd`
**Clase:** `ShapeTray` — **Hereda de:** `Node2D`. Reparte las 5 figuras plantilla y las repone al sacarlas.

**Exportados:** `shape_scene` (`PackedScene` de `shape.tscn`), `spacing` (170 px entre figuras), `shape_lifetime` (45 s; se pasa a cada figura).

| Función | Descripción |
|---|---|
| `_ready()` | Crea una figura por cada valor de `GameData.ShapeType` (5), sin animación. |
| `_spawn(type, animate)` | Instancia una figura, la centra horizontalmente según su índice (`(type - centro) * spacing`), le asigna `lifetime`, la configura con `setup(type, 0)`, conecta su señal `left_tray` con `bind(type)` y, si `animate`, la hace aparecer escalando de 0 a 1 en 0.3 s (`TRANS_BACK`). |
| `_on_shape_left(_shape, type)` | Repone una figura nueva del mismo tipo cuando el jugador saca una de la bandeja. |

> La bandeja siempre ofrece los 5 tipos, aunque en el nivel 1 solo se piden círculo, cuadrado y triángulo.

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
**Hereda de:** `Node2D`. Contenedor de los 4 botes; solo controla su visibilidad.

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
**Clase:** `HUD` — **Hereda de:** `CanvasLayer`. Interfaz superpuesta.

| Función | Descripción |
|---|---|
| `_ready()` | Crea **por código** un `Label` grande (fuente 56, blanco con contorno morado oscuro de 14 px, centrado, 1280×90 en (0, 230), ignora el ratón, transparente) para anunciar cada nivel. |
| `set_progress(level, done, goal)` | Si hay meta, muestra `Nivel N   hechos/meta`; en el nivel final (meta 0) muestra `Nivel N   ★ hechos`. |
| `set_hint(text)` | Cambia el texto de la pista (`HintLabel`). |
| `show_banner(text)` | Muestra el letrero: alpha 1, escala 0.4 → 1 en 0.4 s (`TRANS_BACK`), se mantiene 1.6 s y se desvanece en 0.5 s. |

---

## Escenas: cómo funciona cada una

Todas las escenas con material propio usan `resource_local_to_scene = true` **y además** duplican el material en `_ready()`/`launch()`. Así, cada instancia tiene sus propios uniforms (si compartieran material, pintar una figura pintaría todas).

### `main.tscn` — escena principal
Nodo raíz `Main` (`Node2D`, `main.gd`). Instancia `Background`, `Monster` (610, 229), `Palette` (1101, 136), `ShapeTray` (640, 620), `Eraser` (93, 287) y `HUD`, más una `Camera2D` en (643, 360). Es la única escena que conoce a todas las demás: conecta el slime con el progreso y reparte los cambios de nivel. Las 5 figuras de la bandeja quedan en x = 300, 470, 640, 810 y 980.

### `background.tscn` — fondo
Un solo `ColorRect` de 1280×720 con `background.gdshader` y `mouse_filter = IGNORE` para no bloquear clics. No tiene script: todo es animación del shader (degradado ondulante, puntos que titilan y un piso oscuro desde el 80 % de la altura).

### `monster.tscn` — slime
`Area2D` (`monster.gd`, `input_pickable = false`) con:
- `Collision`: círculo de radio 140 — zona donde la figura "cuenta" como soltada sobre el slime.
- `Body`: `ColorRect` de 340×340 con `monster.gdshader` (el slime entero se dibuja aquí).
- `AbsorbPoint`: `Marker2D` en (0, 20), hacia donde vuela la figura al ser comida.
- `RequestBubble`: instancia del globo, a la izquierda y un poco arriba (−205, −57).

### `request_bubble.tscn` — globo de petición
`Node2D` (`request_bubble.gd`) con dos `ColorRect`: `Bg` (200×200, `bubble.gdshader`) dibuja el globo con sus dos circulitos de cola, e `Item` (100×100, `shape.gdshader`) dibuja la figura pedida encima, reutilizando el mismo shader que las figuras reales.

### `shape.tscn` — figura
`Area2D` (`shape.gd`) con `Collision` (círculo r=52) y `Visual` (`ColorRect` de 128×128 con `shape.gdshader`). El script mueve y deforma `Visual` (no el `Area2D`), de modo que la zona de colisión se mantiene estable aunque el dibujo se estire y se incline. La misma escena sirve para las plantillas de la bandeja y para las figuras sueltas: lo único que cambia es `is_template`.

### `shape_tray.tscn` — bandeja
`Node2D` (`shape_tray.gd`) sin hijos al inicio; en `_ready()` crea las 5 figuras. Su `shape_scene` apunta a `shape.tscn`.

### `paint_bucket.tscn` — bote de pintura
`Area2D` (`paint_bucket.gd`) con `Collision` (círculo r=45), `Visual` (`ColorRect` de 90×90 con **el mismo `shape.gdshader`** dibujando un círculo del color del bote) y `Label` (nombre del color, debajo). Su `Area2D` es pickable (a diferencia del slime y el borrador): es lo que el jugador agarra.

### `color_palette.tscn` — paleta
`Node2D` (`color_palette.gd`) con 4 instancias de `PaintBucket`, separadas 130 px en vertical: `Red` (mask 1), `Yellow` (2), `Blue` (4) y `Clean` (0).

### `eraser.tscn` — borrador
`Area2D` (`eraser.gd`, `input_pickable = false`) con `Collision` (círculo r=60), `Visual` (`ColorRect` de 130×130 con `eraser.gdshader`) y `Label` "Borrador". Solo sirve de destino de soltado.

### `hud.tscn` — interfaz
`CanvasLayer` (`hud.gd`) con `ScoreLabel` (arriba a la izquierda, fuente 30) y `HintLabel` (arriba a la derecha, fuente 18, alineado a la derecha). El letrero de nivel se agrega por código en `_ready()`. Como es un `CanvasLayer`, no le afecta la cámara.

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
| `shape.gdshader` | `shape.tscn`, `paint_bucket.tscn`, `request_bubble.tscn` (`Item`) | Dibuja las 5 figuras con contorno, brillo, onda de pintura y resaltado. |
| `monster.gdshader` | `monster.tscn` | El slime: silueta orgánica, respiración, aplastamiento y sombra. |
| `bubble.gdshader` | `request_bubble.tscn` (`Bg`) | Globo de pensamiento. |
| `eraser.gdshader` | `eraser.tscn` | Goma rosa y azul inclinada con resalte al pasar una figura. |
| `paint_burst.gdshader` | `paint_burst.tscn` | Anillo expansivo + 10 chispas romboidales. |
| `paint_drop.gdshader` | `paint_drop.tscn` | Gota esférica con brillo. |

### `background.gdshader`
**Uniforms:** `color_a` (morado oscuro `0.10, 0.08, 0.20`) y `color_b` (morado medio `0.24, 0.13, 0.40`).
1. **Degradado ondulante:** mezcla `color_a` → `color_b` según `UV.y`, perturbado por `0.05 * sin(UV.x * 6 + TIME * 0.5)`, de modo que la frontera de color "respira".
2. **Puntos que titilan:** divide la pantalla en una cuadrícula de 16×9 celdas; en el centro de cada una dibuja un puntito (`smoothstep` sobre la distancia al centro) cuyo brillo oscila con `sin(TIME + id.x * 3.1 + id.y * 1.7)`: la fase depende de la celda, así que no parpadean todos a la vez. Aportan un 5 % de luz.
3. **Piso:** desde `UV.y = 0.80` mezcla el color hacia `color_a * 0.55` con un corte casi duro (`smoothstep(0.80, 0.81, ...)`).

### `shape.gdshader`
**Uniforms:** `shape_type` (0 círculo, 1 cuadrado, 2 triángulo, 3 estrella, 4 corazón), `fill_color`, `old_color`, `wave` (0–1), `outline_color`, `outline` (grosor, 0.045), `selected` (0–1).
- **SDFs:** `sd_circle`, `sd_box` (cuadrado con esquinas redondeadas, radio 0.06), `sd_triangle`, `sd_star5` (estrella de 5 puntas) y `sd_heart`, estas tres basadas en las fórmulas de Inigo Quilez. Las coordenadas se voltean en Y (`q = (p.x, -p.y)`) para que las figuras queden derechas, y cada una se desplaza/escala para quedar centrada y del mismo tamaño visual.
- **Onda de color:** el color nuevo se revela como un círculo que crece desde el centro: `reach = wave * 0.8`; el píxel muestra `fill_color` si está dentro del radio y `old_color` si no, con un borde suave de 0.1 (`smoothstep`). Con `wave >= 1.0` se salta el cálculo y muestra `fill_color` directo.
- **Contorno:** `inner` es el mismo SDF desplazado `outline` hacia dentro; la franja entre `inner` y la silueta es el contorno. Con `selected = 1`, el contorno se vuelve blanco (resaltado cuando un bote está cerca).
- **Brillo:** una mancha de luz suave arriba a la izquierda (`shine`) suma 0.14 al color; además, un **destello** triangular durante la pintura (`0.35 * (1 - abs(wave * 2 - 1))`, máximo cuando `wave = 0.5`).
- Se reutiliza tal cual para los botes de pintura (siempre `shape_type = 0`) y para la figura dentro del globo.

### `monster.gdshader`
**Uniforms:** `body_color`, `excite` (0–1: se agita), `squish` (−1 estirado … 1 aplastado), `idle_squish` (0.05) e `idle_speed` (2.4).
- **Silueta:** `slime_sd` une dos elipses (una angosta arriba, una ancha abajo) con `smin` (mínimo suave, `k = 0.35`) y recorta la base con `smax` contra la línea del piso `FLOOR_Y = 0.64` (`k = 0.12`) para que el fondo quede plano. `ell_sd` es una aproximación barata del SDF de una elipse.
- **Squish que conserva el volumen:** `sy = clamp(1 − 0.32·squish + idle, 0.6, 1.4)` y `sx = 1 / sqrt(sy)`. La transformación está **anclada al piso** (`FLOOR_Y`), así el slime se aplasta contra el suelo sin despegarse. El latido constante `idle` es `idle_squish · sin(TIME · idle_speed)` y se suma un temblor rápido (`0.06 · excite · sin(TIME · 10)`); además la silueta ondula horizontalmente con `excite`.
- **Capas:** contorno claro (`d − 0.045`), borde (`rim`, el color mezclado un 42 % con blanco), relleno interior (más pequeño y desplazado, con degradado de arriba a abajo) y un **puntito blanco con halo** arriba como brillo.
- **Sombra:** una elipse suave en el piso, con alfa 0.25 y ancho proporcional a `sx`, que se compone con premultiplicación manual de alfa al final.
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

**Suavizado exponencial (independiente de los FPS).** En lugar de `lerp(a, b, 0.2)`, se usa `lerp(a, b, 1.0 − exp(−k · delta))`: da el mismo resultado visual a 30 o a 144 FPS. Se usa en el seguimiento del ratón (`k = 24` en figuras, `30` en botes), en `excite` del slime (`k = 10`) y en `hover` del borrador (`k = 12`).

**Resortes subamortiguados.** Para la sensación de gelatina, `Shape` y `PaintBucket` integran a mano (Euler semiimplícito):

```
vel += ((objetivo − valor) * rigidez − vel * amortiguación) * dt
valor += vel * dt
```

| Resorte | Rigidez | Amortiguación | Objetivo |
|---|---|---|---|
| Inclinación (`_sway`) | 170 | 7 | proporcional a la velocidad en X (máx. ±0.45 rad en figuras, ±0.5 en botes) |
| Estiramiento (`_stretch`, solo figuras) | 190 | 8 | proporcional a `|vx| − |vy|` (máx. ±0.2) |
| Levantada (`_lift`) | 220 | 12 | 0.12 al arrastrar figuras, 0.25 con botes, 0 en reposo |

Como la amortiguación es baja respecto a la rigidez, el valor **sobrepasa y oscila** antes de asentarse: ese temblor es la gelatina. Los golpes (al agarrar, soltar o pintar) se aplican sumando impulsos directamente a `*_vel`. `dt` se limita a `0.033` para que un salto de frame no haga explotar el resorte. Estos resortes solo modifican el `ColorRect` visual, nunca el `Area2D`, así la colisión no se deforma.

**Tweens.** Se usan para animaciones de un solo disparo: apariciones con `TRANS_BACK` (rebote al entrar), sacudidas con `TRANS_ELASTIC`, y `tween_method` para animar uniforms de shaders (`wave`, `progress`, `body_color`).

---

## Notas conocidas

- **`HintLabel` está oculto en `hud.tscn`** (`visible = false`) y `HUD.set_hint()` solo cambia el texto, sin mostrarlo, así que las pistas de cada nivel (`hint` en `STAGES`) hoy no se ven en pantalla. El texto por defecto de la escena además describe un flujo anterior ("Toca una figura para pintarla"). Para activarlo basta con quitar `visible = false` o llamar a `show()`.
- **`food_rejected` no tiene ningún receptor.** El slime la emite al rechazar, pero ningún script la escucha: es un buen punto de enganche para sonido o un contador de errores.
- **La bandeja siempre ofrece las 5 figuras**, aunque en el nivel 1 solo se pidan círculo, cuadrado y triángulo.
- **El marrón (7)** se puede obtener mezclando los tres primarios, pero nunca se pide; esas figuras solo sirven para limpiarlas.
- **Al iniciar, el slime hace dos peticiones seguidas:** una en `Monster._ready()` y otra cuando `Main._ready()` aplica el nivel. Es inocuo (la segunda sustituye a la primera antes del primer frame).
- **El texto del borrador** (`"Borrador"`) está escrito directamente en `eraser.tscn`, a diferencia de los botes, cuyo rótulo sale de `GameData`.
- **El ancho del letrero de nivel** (`1280`) está fijo en `hud.gd`; con otra resolución base habría que cambiarlo o anclarlo.
- **Los límites de arrastre** usan `get_viewport_rect()`, que no considera la posición de la `Camera2D` (643, 360, 3 px a la derecha del centro). El margen de 50 px lo absorbe sin problemas.
- `request_bubble.gd` está indentado con espacios; el resto de scripts usa tabulaciones. Funciona (cada archivo es coherente consigo mismo), pero conviene unificar.
- El proyecto declara `Jolt Physics` como motor 3D, pero no hay ningún nodo 3D: el ajuste no tiene efecto.
