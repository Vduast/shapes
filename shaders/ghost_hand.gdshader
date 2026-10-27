shader_type canvas_item;
// Mano fantasma del tutorial: translucida, con contorno suave, un brazo que se desvanece
// hacia abajo y un brillo alrededor. Dos poses mezcladas con `grab`:
//   grab = 0 -> mano que señala (dedo estirado)   grab = 1 -> puño que sostiene algo
// El origen del nodo es la "punta del dedo" al señalar y el centro del puño al agarrar.

uniform float grab : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.45, 0.55, 0.95, 1.0);

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float sd_capsule(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sd_round_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
    // h: coordenadas de la mano. El puño queda centrado en el origen cuando grab = 1.
    vec2 h = (UV - vec2(0.2, 0.12)) * 1.6 + grab * vec2(0.15, 0.40);

    // Dedo índice (se encoge al agarrar), palma, pulgar, nudillos y brazo
    float d = sd_capsule(h, vec2(0.0, mix(0.0, 0.32, grab)), vec2(0.03, 0.40), 0.085);
    d = smin(d, sd_round_box(h - vec2(0.16, 0.50), vec2(0.21, 0.19), 0.10), 0.06);
    d = smin(d, sd_capsule(h, vec2(0.33, 0.50), vec2(0.48, 0.37), 0.075), 0.05);
    d = smin(d, length(h - vec2(0.07, 0.37)) - 0.08 * grab, 0.05);
    d = smin(d, length(h - vec2(0.17, 0.35)) - 0.08 * grab, 0.05);
    d = smin(d, length(h - vec2(0.27, 0.37)) - 0.07 * grab, 0.05);
    d = smin(d, sd_capsule(h, vec2(0.20, 0.62), vec2(0.30, 1.25), 0.11), 0.10);

    float aa = max(fwidth(d), 0.002);
    float inside = 1.0 - smoothstep(-aa, aa, d);
    float ring = inside * smoothstep(-0.03 - aa, -0.03 + aa, d);   // contorno hacia adentro

    // Se desvanece hacia el brazo, como una estela de fantasma
    float fade = 1.0 - smoothstep(0.55, 1.15, h.y);

    // Relleno blanco con un toque azulado abajo y un brillo suave arriba a la izquierda
    vec3 body = mix(fill_color.rgb, vec3(0.80, 0.88, 1.0), smoothstep(0.2, 0.9, h.y));
    body += vec3(0.10) * (1.0 - smoothstep(0.0, 0.5, length(h - vec2(0.0, 0.25))));
    vec3 col = mix(body, outline_color.rgb, ring * 0.8);

    // Resplandor por fuera
    float glow = (1.0 - smoothstep(0.0, 0.14, max(d, 0.0))) * (1.0 - inside) * 0.35;

    float a = (inside * 0.88 + glow) * fade;
    COLOR = vec4(mix(vec3(1.0), col, inside), a);
}
