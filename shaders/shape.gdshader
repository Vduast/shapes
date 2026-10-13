shader_type canvas_item;

uniform int shape_type = 0; // 0 circulo 1 cuadrado 2 triangulo 3 estrella 4 corazon
uniform vec4 fill_color : source_color = vec4(1.0);
uniform vec4 old_color : source_color = vec4(1.0);
uniform float wave : hint_range(0.0, 1.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.08, 0.06, 0.14, 1.0);
uniform float outline : hint_range(0.0, 0.2) = 0.045;
uniform float selected : hint_range(0.0, 1.0) = 0.0;
uniform float hover : hint_range(0.0, 1.0) = 0.0;

float dot2(vec2 v) { return dot(v, v); }

float sd_circle(vec2 p, float r) { return length(p) - r; }

float sd_box(vec2 p, vec2 b, float round_r) {
    vec2 d = abs(p) - b + vec2(round_r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - round_r;
}

float sd_triangle(vec2 p, float r) {
    float k = 1.7320508;
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

float sd_star5(vec2 p, float r, float rf) {
    vec2 k1 = vec2(0.809016994375, -0.587785252292);
    vec2 k2 = vec2(-0.809016994375, -0.587785252292);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float sd_heart(vec2 p) {
    p.x = abs(p.x);
    if (p.y + p.x > 1.0)
        return sqrt(dot2(p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    return sqrt(min(dot2(p - vec2(0.0, 1.0)),
                    dot2(p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}

void fragment() {
    vec2 p = UV - 0.5;
    vec2 q = vec2(p.x, -p.y);
    float d;

    if (shape_type == 0) {
        d = sd_circle(p, 0.40);
    } else if (shape_type == 1) {
        d = sd_box(p, vec2(0.36), 0.06);
    } else if (shape_type == 2) {
        d = sd_triangle(q + vec2(0.0, 0.02), 0.31);
    } else if (shape_type == 3) {
        d = sd_star5(q + vec2(0.0, 0.05), 0.46, 0.45);
    } else {
        d = sd_heart(vec2(q.x, q.y + 0.45) * 1.3) / 1.3;
    }

    float aa = max(fwidth(d), 0.002);
    float alpha = 1.0 - smoothstep(-aa, aa, d);
    float inner = 1.0 - smoothstep(-aa, aa, d + outline);

    // Onda de color: el color nuevo se expande desde el centro
    float reach = wave * 0.8;
    float reveal = (wave >= 1.0) ? 1.0 : 1.0 - smoothstep(reach - 0.1, reach, length(p));
    vec3 base = mix(old_color.rgb, fill_color.rgb, reveal);

    vec3 oc = mix(outline_color.rgb, vec3(1.0), max(selected, hover * 0.8));
    vec3 col = mix(oc, base, inner);

    float shine = clamp(1.0 - length(p - vec2(-0.12, -0.12)) * 2.2, 0.0, 1.0);
    col += 0.14 * shine * inner;

    // Destello mientras se pinta
    col += 0.35 * (1.0 - abs(wave * 2.0 - 1.0)) * inner;

    // Iluminación y halo al pasar el mouse
    col += 0.10 * hover * inner;
    float glow = hover * 0.5 * (1.0 - smoothstep(0.0, 0.06, max(d, 0.0)));
    float a2 = max(alpha, glow);
    vec3 rgb = mix(vec3(1.0), col, alpha / max(a2, 0.001));

    COLOR = vec4(rgb, a2);
}