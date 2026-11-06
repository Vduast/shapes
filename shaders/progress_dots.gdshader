shader_type canvas_item;
// Fila de bolitas de progreso: las primeras `filled` están llenas (doradas).
// El script pasa el tamaño del ColorRect (rect_size) y cuántas bolitas hay (count).

uniform vec2 rect_size = vec2(300.0, 44.0);
uniform float count = 5.0;
uniform float filled = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 px = UV * rect_size;
    float cell = rect_size.x / max(count, 1.0);
    float idx = floor(px.x / cell);
    vec2 c = vec2((idx + 0.5) * cell, rect_size.y * 0.5);
    float r = min(cell, rect_size.y) * 0.5 - 3.0;
    float d = length(px - c) - r;
    float aa = max(fwidth(d), 0.0001);

    float lit = step(idx + 0.5, filled);
    vec3 fill_col = mix(vec3(0.13, 0.09, 0.30), vec3(1.0, 0.84, 0.18), lit);
    // brillito arriba a la izquierda en las llenas
    float shine = (1.0 - smoothstep(0.0, 2.0, length(px - c - vec2(-r * 0.35, -r * 0.35)) - r * 0.18)) * lit;
    fill_col = mix(fill_col, vec3(1.0), shine * 0.8);

    float a_out = 1.0 - smoothstep(-aa, aa, d);
    float a_in = 1.0 - smoothstep(-aa, aa, d + 4.0);
    vec3 col = mix(outline_color.rgb, fill_col, a_in);
    COLOR = vec4(col, a_out * mix(0.9, 1.0, lit));
}
