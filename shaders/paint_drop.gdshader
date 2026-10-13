shader_type canvas_item;

uniform vec4 drop_color : source_color = vec4(1.0);

void fragment() {
    vec2 p = UV - 0.5;
    float d = length(p) - 0.38;
    float aa = max(fwidth(d), 0.002);
    float a = 1.0 - smoothstep(-aa, aa, d);

    vec3 col = drop_color.rgb;
    col = mix(col * 0.78, col, smoothstep(0.4, -0.2, length(p)));

    float hl = 1.0 - smoothstep(0.0, 0.05, length(p - vec2(-0.12, -0.12)) - 0.06);
    col = mix(col, vec3(1.0), hl * 0.85);

    COLOR = vec4(col, a);
}