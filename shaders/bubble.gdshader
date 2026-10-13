shader_type canvas_item;
// Globo de pensamiento: rectángulo redondeado + 2 circulitos.

uniform vec4 bubble_color : source_color = vec4(1.0);
uniform vec4 outline_color : source_color = vec4(0.1, 0.05, 0.15, 1.0);

void fragment() {
    vec2 p = UV - 0.5;
    vec2 q = abs(p - vec2(0.0, -0.12)) - vec2(0.34, 0.22);
    float box = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.12;
    float c1 = length(p - vec2(0.0, 0.33)) - 0.07;
    float c2 = length(p - vec2(0.08, 0.44)) - 0.045;
    float d = min(box, min(c1, c2));

    float aa = max(fwidth(d), 0.002);
    float alpha = 1.0 - smoothstep(-aa, aa, d);
    float inner = 1.0 - smoothstep(-aa, aa, d + 0.02);
    COLOR = vec4(mix(outline_color.rgb, bubble_color.rgb, inner), alpha);
}
