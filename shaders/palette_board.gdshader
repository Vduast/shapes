shader_type canvas_item;
// Paleta de pintor: tabla de madera clara con un hueco para cada bote de pintura
// y el agujero para el pulgar. Las posiciones de los huecos las calcula
// color_palette.gd a partir de donde estén los botes, así que no hay que
// tocar nada aquí si los mueves en el editor.
// Trabaja en píxeles: el script le pasa el tamaño del ColorRect (rect_size).

uniform vec2 rect_size = vec2(188.0, 648.0);
uniform float pad = 14.0;                // margen reservado para la sombra
uniform float radius = 72.0;
uniform vec2 well_first = vec2(0.0, -240.0);   // centro del primer hueco (relativo al centro de la tabla)
uniform vec2 well_step = vec2(0.0, 130.0);     // separación entre huecos
uniform int well_count = 4;
uniform float well_radius = 50.0;
uniform vec2 hole_pos = vec2(0.0, 258.0);      // agujero del pulgar
uniform float hole_radius = 20.0;
uniform vec4 wood_color : source_color = vec4(0.97, 0.82, 0.58, 1.0);
uniform vec4 outline_color : source_color = vec4(0.07, 0.12, 0.38, 1.0);   // azul oscuro
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

    float d = sd_round_box(p, hs, min(radius, hs.x));
    float a_out = 1.0 - smoothstep(-aa, aa, d);
    float in_body = 1.0 - smoothstep(-aa, aa, d + ow);

    // Madera: vetas suaves + luz arriba
    vec3 wood = wood_color.rgb;
    float grain = sin(p.y * 0.30 + sin(p.x * 0.05) * 3.0);
    wood *= 1.0 - 0.035 * grain * grain;
    wood = mix(wood, vec3(1.0), 0.22 * (1.0 - smoothstep(-hs.y, -hs.y + 40.0, p.y)));

    vec3 col = outline_color.rgb;
    col = mix(col, wood, in_body);

    // Un hueco por bote, un poco hundido
    for (int i = 0; i < 6; i++) {
        if (i >= well_count) {
            break;
        }
        vec2 c = well_first + well_step * float(i);
        float dd = length(p - c) - well_radius;
        float m = (1.0 - smoothstep(-aa, aa, dd)) * in_body;
        float top = clamp((c.y - p.y) / well_radius, -1.0, 1.0);   // +1 arriba, -1 abajo
        vec3 wc = wood * (0.84 - 0.08 * max(top, 0.0) + 0.06 * max(-top, 0.0));
        col = mix(col, wc, m);
    }

    // Agujero del pulgar: contorno azul y transparente por dentro
    float dh = length(p - hole_pos) - hole_radius;
    float hole_ring = 1.0 - smoothstep(-aa, aa, dh - ow);
    float hole_cut = 1.0 - smoothstep(-aa, aa, dh);
    col = mix(col, outline_color.rgb, hole_ring * a_out);
    float alpha = a_out * (1.0 - hole_cut);

    // Sombra suave por fuera
    float ds = sd_round_box(p - vec2(0.0, 6.0), hs, min(radius, hs.x));
    float shadow = (1.0 - smoothstep(-pad * 0.5, pad, ds)) * shadow_color.a * (1.0 - a_out);

    COLOR = vec4(mix(shadow_color.rgb, col, a_out), alpha + shadow);
}
