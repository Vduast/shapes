shader_type canvas_item;
// Bandeja de figuras: borde crema, fondo lila y un hueco (cuna) para cada figura.
// slot_count es float a propósito: shape_tray.gd lo anima (3 -> 5) para que la
// bandeja crezca y aparezcan los huecos nuevos con suavidad.
// Trabaja en píxeles: el script le pasa el tamaño del ColorRect (rect_size).

uniform vec2 rect_size = vec2(852.0, 188.0);
uniform float pad = 14.0;               // margen reservado para la sombra
uniform float radius = 40.0;
uniform float rim_width = 16.0;
uniform float slot_count = 5.0;
uniform float slot_spacing = 160.0;
uniform float slot_radius = 56.0;
uniform vec4 outline_color : source_color = vec4(0.07, 0.12, 0.38, 1.0);   // azul oscuro
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.74, 1.0);        // crema
uniform vec4 floor_color : source_color = vec4(0.72, 0.65, 0.93, 1.0);     // lila
uniform vec4 shadow_color : source_color = vec4(0.04, 0.02, 0.14, 0.40);

float sd_round_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
    vec2 p = (UV - 0.5) * rect_size;
    vec2 hs = rect_size * 0.5 - vec2(pad);
    float aa = 1.0;
    float ow = 4.0;

    float d = sd_round_box(p, hs, radius);
    float a_out = 1.0 - smoothstep(-aa, aa, d);
    float in_body = 1.0 - smoothstep(-aa, aa, d + ow);

    float d_floor = sd_round_box(p, hs - vec2(rim_width), radius - rim_width * 0.6);
    float floor_out = 1.0 - smoothstep(-aa, aa, d_floor);
    float floor_in = 1.0 - smoothstep(-aa, aa, d_floor + 3.0);

    // Borde: luz arriba, un poco más oscuro abajo
    vec3 rim = rim_color.rgb;
    rim = mix(rim, vec3(1.0), 0.35 * (1.0 - smoothstep(-hs.y, -hs.y + 14.0, p.y)));
    rim *= mix(1.0, 0.88, smoothstep(0.0, hs.y, p.y));

    // Fondo lila con rayitas diagonales y sombra interior arriba
    vec3 fl = floor_color.rgb + vec3(0.03) * step(0.5, fract((p.x - p.y) / 40.0));
    float depth = clamp(-d_floor / 18.0, 0.0, 1.0);
    float inner_sh = (1.0 - depth) * mix(1.0, 0.45, smoothstep(-hs.y, hs.y, p.y));
    fl *= 1.0 - 0.18 * inner_sh;

    vec3 col = outline_color.rgb;
    col = mix(col, rim, in_body);
    col = mix(col, outline_color.rgb, floor_out);
    col = mix(col, fl, floor_in);

    // Un hueco por figura
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float w = clamp(slot_count - fi, 0.0, 1.0);
        vec2 c = vec2((fi - (slot_count - 1.0) * 0.5) * slot_spacing, 0.0);
        float dd = length(p - c) - slot_radius * w;
        float m = (1.0 - smoothstep(-aa, aa, dd)) * floor_in;
        float top = clamp((c.y - p.y) / slot_radius, -1.0, 1.0);   // +1 arriba, -1 abajo
        vec3 dc = fl * (0.82 - 0.07 * max(top, 0.0) + 0.05 * max(-top, 0.0));
        col = mix(col, dc, m);
    }

    // Sombra suave solo por fuera
    float ds = sd_round_box(p - vec2(0.0, 6.0), hs, radius);
    float shadow = (1.0 - smoothstep(-pad * 0.5, pad, ds)) * shadow_color.a * (1.0 - a_out);

    COLOR = vec4(mix(shadow_color.rgb, col, a_out), a_out + shadow);
}
