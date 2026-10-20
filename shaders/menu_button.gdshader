shader_type canvas_item;
// Botón de juguete: cara crema, "grosor" más oscuro debajo y contorno azul oscuro.
// hover: se ilumina y pasa un brillo diagonal. press: la cara se hunde.
// Trabaja en píxeles: el script le pasa el tamaño del ColorRect (rect_size).

uniform vec2 rect_size = vec2(380.0, 80.0);
uniform vec4 fill_color : source_color = vec4(1.0, 0.94, 0.78, 1.0);     // crema
uniform vec4 slab_color : source_color = vec4(0.90, 0.74, 0.50, 1.0);    // crema oscuro
uniform vec4 outline_color : source_color = vec4(0.07, 0.12, 0.38, 1.0); // azul oscuro
uniform float hover : hint_range(0.0, 1.0) = 0.0;
uniform float press : hint_range(0.0, 1.0) = 0.0;
uniform float radius = 28.0;
uniform float outline_width = 4.0;

float sd_round_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
    vec2 p = (UV - 0.5) * rect_size;
    p.y -= press * 4.0;                       // al presionar, todo baja un poco
    vec2 hs = rect_size * 0.5 - vec2(6.0);
    float aa = 1.0;
    float lift = mix(15.0, 7.0, press);       // cuánto se ve el grosor de abajo

    // Base (grosor) con su contorno
    float d_slab = sd_round_box(p, hs, min(radius, hs.y));
    float a_out = 1.0 - smoothstep(-aa, aa, d_slab);
    float in_slab = 1.0 - smoothstep(-aa, aa, d_slab + outline_width);

    // Cara: misma silueta, pero sube "lift" píxeles
    vec2 hf = vec2(hs.x, hs.y - lift * 0.5);
    float d_face = sd_round_box(p - vec2(0.0, -lift * 0.5), hf, min(radius, hf.y));
    float face_out = 1.0 - smoothstep(-aa, aa, d_face);
    float face_in = 1.0 - smoothstep(-aa, aa, d_face + outline_width);

    // Color de la cara: degradado suave + más claro con hover
    float t = clamp((p.y + hs.y) / (2.0 * hf.y), 0.0, 1.0);
    vec3 face_col = mix(fill_color.rgb, fill_color.rgb * vec3(0.97, 0.93, 0.88), t);
    face_col = mix(face_col, vec3(1.0, 0.99, 0.93), hover * 0.6);

    // Reflejo alargado arriba
    vec2 gp = p - vec2(0.0, -hs.y + 15.0);
    float stripe = 1.0 - smoothstep(0.0, 1.5, sd_round_box(gp, vec2(hs.x - 36.0, 3.5), 3.5));
    face_col = mix(face_col, vec3(1.0), stripe * 0.75);

    // Brillo diagonal que cruza el botón mientras tiene el ratón encima
    float sweep = fract(TIME * 0.6);
    float diag = (p.x + p.y * 0.6) / rect_size.x + 0.5;
    float band = 1.0 - smoothstep(0.0, 0.10, abs(diag - (sweep * 1.6 - 0.3)));
    face_col += vec3(0.20) * band * hover;

    vec3 col = outline_color.rgb;
    col = mix(col, slab_color.rgb, in_slab);
    col = mix(col, outline_color.rgb, face_out);
    col = mix(col, face_col, face_in);

    COLOR = vec4(col, a_out);
}
