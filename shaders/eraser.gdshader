shader_type canvas_item;

uniform float hover : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 p = UV - 0.5;
    float a = -0.4;
    vec2 q = vec2(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y);

    vec2 b = abs(q) - vec2(0.40, 0.22) + vec2(0.07);
    float d = length(max(b, 0.0)) + min(max(b.x, b.y), 0.0) - 0.07;

    float aa = max(fwidth(d), 0.002);
    float alpha = 1.0 - smoothstep(-aa, aa, d);
    float inner = 1.0 - smoothstep(-aa, aa, d + 0.035);

    vec3 pink = vec3(1.0, 0.55, 0.70);
    vec3 blue = vec3(0.25, 0.50, 0.95);
    float band = smoothstep(0.10, 0.11, q.x);
    vec3 col = mix(pink, blue, band);

    float line = 1.0 - smoothstep(0.005, 0.015, abs(q.x - 0.105));
    col = mix(col, vec3(1.0), line * 0.8);
    col += 0.2 * clamp(-q.y * 3.0, 0.0, 1.0);

    col = mix(col, vec3(1.0), hover * 0.25);
    vec3 outc = mix(vec3(0.12, 0.06, 0.18), vec3(1.0), hover);
    col = mix(outc, col, inner);

    COLOR = vec4(col, alpha);
}