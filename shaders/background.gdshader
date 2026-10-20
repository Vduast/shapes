


shader_type canvas_item;
// Fondo con degradado, puntitos que parpadean y un piso.

uniform vec4 color_a : source_color = vec4(0.10, 0.08, 0.20, 1.0);
uniform vec4 color_b : source_color = vec4(0.24, 0.13, 0.40, 1.0);

void fragment() {
    vec2 uv = UV;
    float g = clamp(uv.y + 0.05 * sin(uv.x * 6.0 + TIME * 0.5), 0.0, 1.0);
    vec3 col = mix(color_a.rgb, color_b.rgb, g);

    vec2 gp = uv * vec2(16.0, 9.0);
    vec2 id = floor(gp);
    vec2 f = fract(gp) - 0.5;
    float dots = (1.0 - smoothstep(0.04, 0.08, length(f)))
               * (0.5 + 0.5 * sin(TIME + id.x * 3.1 + id.y * 1.7));
    col += 0.05 * dots;

    float floor_m = smoothstep(0.80, 0.81, uv.y);
    col = mix(col, color_a.rgb * 0.55, floor_m);

    COLOR = vec4(col, 1.0);
}
