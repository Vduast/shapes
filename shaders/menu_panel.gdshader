shader_type canvas_item;
// Contenedor semitransparente del menú: borde crema grueso con "costura",
// puntitos que se desplazan despacio, brillo arriba y sombra suave por fuera.
// Trabaja en píxeles: el script le pasa el tamaño del ColorRect (rect_size).

uniform vec2 rect_size = vec2(500.0, 580.0);
uniform float radius = 42.0;
uniform float pad = 14.0;            // margen interno reservado para la sombra
uniform float border_width = 7.0;
uniform vec4 fill_color : source_color = vec4(1.0, 0.96, 0.88, 0.55);
uniform vec4 border_color : source_color = vec4(1.0, 0.97, 0.86, 0.95);
uniform vec4 shadow_color : source_color = vec4(0.04, 0.02, 0.14, 0.45);

float sd_round_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
    vec2 p = (UV - 0.5) * rect_size;          // píxeles, centrado, Y hacia abajo
    vec2 hs = rect_size * 0.5 - vec2(pad);
    float d = sd_round_box(p, hs, radius);
    float aa = 1.0;

    float inside = 1.0 - smoothstep(-aa, aa, d);

    // Sombra suave, solo por fuera del panel
    float ds = sd_round_box(p - vec2(0.0, 6.0), hs, radius);
    float shadow = (1.0 - smoothstep(-pad * 0.5, pad, ds)) * shadow_color.a * (1.0 - inside);

    // Relleno traslúcido con puntitos (filas desfasadas) y brillo arriba
    vec2 g = p / 46.0 + vec2(TIME * 0.04, TIME * 0.025);
    g.x += 0.5 * mod(floor(g.y), 2.0);
    vec2 f = fract(g) - 0.5;
    float dots = 1.0 - smoothstep(0.13, 0.17, length(f));
    float gloss = 1.0 - smoothstep(0.0, 140.0, p.y + hs.y);

    vec3 fill_rgb = fill_color.rgb + vec3(0.07) * dots + vec3(0.10) * gloss;
    float fill_a = clamp(fill_color.a + 0.04 * dots + 0.10 * gloss, 0.0, 1.0);
    vec4 panel = vec4(fill_rgb, fill_a);

    // Borde crema
    float ring = inside * smoothstep(-border_width - aa, -border_width + aa, d);
    panel = mix(panel, border_color, ring);

    // Costura punteada, un poco más adentro del borde
    vec2 q = abs(p);
    float along = ((hs.y - q.y) < (hs.x - q.x)) ? p.x : p.y;
    float dash = step(0.5, fract(along / 22.0));
    float line_d = abs(d + border_width + 10.0);
    float stitch = (1.0 - smoothstep(1.0, 2.2, line_d)) * dash * inside * (1.0 - ring);
    panel = mix(panel, vec4(border_color.rgb, 0.85), stitch);

    float a = inside * panel.a + shadow;
    COLOR = vec4(mix(shadow_color.rgb, panel.rgb, inside), a);
}
