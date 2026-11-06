shader_type canvas_item;
// Iconos dibujados con distancias con signo (SDF). Un solo shader para todos los iconos de
// los menús: `icon` elige cuál se dibuja y `tint` es el color del contorno / trazo principal.
//  0 jugar   1 niveles   2 ayuda   3 salir   4 sonido sí   5 sonido no   6 atrás   7 casa
//  8 palomita   9 tache   10 bote de basura   11 candado   12 estrella   13 flecha
//  14 slime   15 brillos (limpiar)

uniform int icon = 0;
uniform vec4 tint : source_color = vec4(0.07, 0.12, 0.38, 1.0);

const vec4 C_GREEN = vec4(0.20, 0.75, 0.35, 1.0);
const vec4 C_RED = vec4(0.92, 0.22, 0.24, 1.0);
const vec4 C_YELLOW = vec4(1.0, 0.84, 0.18, 1.0);
const vec4 C_PURPLE = vec4(0.62, 0.32, 0.86, 1.0);
const vec4 C_SKY = vec4(0.55, 0.85, 1.0, 1.0);
const vec4 C_WHITE = vec4(1.0, 1.0, 1.0, 1.0);

float sd_box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sd_rbox(vec2 p, vec2 b, float r) {
    return sd_box(p, b - vec2(r)) - r;
}

float sd_seg(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sd_tri(vec2 p, vec2 a, vec2 b, vec2 c) {
    vec2 e0 = b - a;
    vec2 e1 = c - b;
    vec2 e2 = a - c;
    vec2 v0 = p - a;
    vec2 v1 = p - b;
    vec2 v2 = p - c;
    vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                     vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                 vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

// Estrella de n puntas (iq). m más grande = puntas más finas. Apunta hacia arriba.
float sd_star(vec2 p, float r, float n, float m) {
    float an = 3.141593 / n;
    float en = 3.141593 / m;
    vec2 acs = vec2(cos(an), sin(an));
    vec2 ecs = vec2(cos(en), sin(en));
    float bn = mod(atan(p.x, p.y), 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
    return length(p) * sign(p.x);
}

float sparkle(vec2 p) {
    float f = pow(abs(p.x), 0.55) + pow(abs(p.y), 0.55);
    return (f - 0.9) * 0.35;
}

// Pinta una capa (d < 0 = dentro) con color c encima de lo que ya hay
void layer(inout vec4 o, float d, vec4 c) {
    float aa = max(fwidth(d), 0.0001);
    float a = (1.0 - smoothstep(-aa, aa, d)) * c.a;
    float na = a + o.a * (1.0 - a);
    o.rgb = (c.rgb * a + o.rgb * o.a * (1.0 - a)) / max(na, 0.0001);
    o.a = na;
}

// Forma con contorno (tint) y relleno de color
void filled(inout vec4 o, float d, vec4 fill) {
    layer(o, d, tint);
    layer(o, d + 0.085, fill);
}

float speaker(vec2 p) {
    float body = sd_rbox(p - vec2(-0.58, 0.0), vec2(0.17, 0.21), 0.04);
    float c1 = sd_tri(p, vec2(-0.45, -0.22), vec2(0.02, -0.62), vec2(0.02, 0.62));
    float c2 = sd_tri(p, vec2(-0.45, -0.22), vec2(0.02, 0.62), vec2(-0.45, 0.22));
    return min(body, min(c1, c2));
}

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    vec4 o = vec4(0.0);

    if (icon == 0) {
        // JUGAR: triángulo verde
        float d = sd_tri(p, vec2(-0.30, -0.52), vec2(-0.30, 0.52), vec2(0.52, 0.0)) - 0.16;
        filled(o, d, C_GREEN);
    } else if (icon == 1) {
        // NIVELES: cuadrícula 3x3, el del centro dorado
        vec2 c = clamp(floor(p / 0.62 + 0.5), -1.0, 1.0);
        float d = sd_rbox(p - c * 0.62, vec2(0.25), 0.08);
        if (abs(c.x) + abs(c.y) < 0.5) {
            filled(o, d, C_YELLOW);
        } else {
            layer(o, d, tint);
        }
    } else if (icon == 2) {
        // AYUDA: signo de interrogación
        vec2 a = p - vec2(0.0, -0.28);
        float ring = abs(length(a) - 0.36) - 0.085;
        ring = max(ring, -sd_box(a - vec2(-0.5, 0.5), vec2(0.5)));
        float stem = sd_seg(p, vec2(0.0, 0.10), vec2(0.0, 0.28), 0.085);
        float dot_ = length(p - vec2(0.0, 0.64)) - 0.115;
        layer(o, min(min(ring, stem), dot_), tint);
    } else if (icon == 3) {
        // SALIR: símbolo de apagado
        float ring = abs(length(p) - 0.52) - 0.1;
        ring = max(ring, -sd_box(p - vec2(0.0, -0.6), vec2(0.2, 0.45)));
        float stem = sd_seg(p, vec2(0.0, -0.74), vec2(0.0, -0.08), 0.1);
        layer(o, min(ring, stem), tint);
    } else if (icon == 4) {
        // SONIDO SÍ: bocina con ondas
        vec2 c = vec2(0.02, 0.0);
        float w = min(abs(length(p - c) - 0.42), abs(length(p - c) - 0.72)) - 0.07;
        float wedge = max(abs(p.y) - (p.x - c.x), c.x - p.x + 0.02);
        layer(o, min(speaker(p), max(w, wedge)), tint);
    } else if (icon == 5) {
        // SONIDO NO: bocina con una X roja
        layer(o, speaker(p), tint);
        float x = min(sd_seg(p, vec2(0.25, -0.32), vec2(0.78, 0.32), 0.09),
                      sd_seg(p, vec2(0.25, 0.32), vec2(0.78, -0.32), 0.09));
        layer(o, x, C_RED);
    } else if (icon == 6) {
        // ATRÁS: flecha a la izquierda
        float d = min(sd_seg(p, vec2(-0.65, 0.0), vec2(0.7, 0.0), 0.1),
                      min(sd_seg(p, vec2(-0.68, 0.0), vec2(-0.1, -0.6), 0.1),
                          sd_seg(p, vec2(-0.68, 0.0), vec2(-0.1, 0.6), 0.1)));
        layer(o, d, tint);
    } else if (icon == 7) {
        // CASA
        float roof = sd_tri(p, vec2(-0.8, -0.02), vec2(0.8, -0.02), vec2(0.0, -0.78));
        float body = sd_rbox(p - vec2(0.0, 0.36), vec2(0.56, 0.42), 0.06);
        float door = sd_rbox(p - vec2(0.0, 0.50), vec2(0.16, 0.28), 0.05);
        layer(o, min(roof, max(body, -door)), tint);
    } else if (icon == 8) {
        // PALOMITA verde
        float d = min(sd_seg(p, vec2(-0.6, 0.05), vec2(-0.2, 0.5), 0.14),
                      sd_seg(p, vec2(-0.2, 0.5), vec2(0.66, -0.46), 0.14));
        filled(o, d, C_GREEN);
    } else if (icon == 9) {
        // TACHE roja
        float d = min(sd_seg(p, vec2(-0.55, -0.55), vec2(0.55, 0.55), 0.14),
                      sd_seg(p, vec2(-0.55, 0.55), vec2(0.55, -0.55), 0.14));
        filled(o, d, C_RED);
    } else if (icon == 10) {
        // BOTE DE BASURA
        float body = sd_rbox(p - vec2(0.0, 0.2), vec2(0.46, 0.52), 0.1);
        float slits = min(sd_rbox(p - vec2(0.0, 0.22), vec2(0.05, 0.3), 0.03),
                          min(sd_rbox(p - vec2(-0.2, 0.22), vec2(0.05, 0.3), 0.03),
                              sd_rbox(p - vec2(0.2, 0.22), vec2(0.05, 0.3), 0.03)));
        body = max(body, -slits);
        float lid = sd_rbox(p - vec2(0.0, -0.46), vec2(0.64, 0.1), 0.05);
        float handle = sd_rbox(p - vec2(0.0, -0.68), vec2(0.2, 0.1), 0.05);
        layer(o, min(body, min(lid, handle)), tint);
    } else if (icon == 11) {
        // CANDADO
        float ring = abs(length(p - vec2(0.0, -0.14)) - 0.32) - 0.1;
        ring = max(ring, p.y + 0.12);
        float body = sd_rbox(p - vec2(0.0, 0.3), vec2(0.52, 0.42), 0.1);
        float key = min(length(p - vec2(0.0, 0.24)) - 0.1, sd_seg(p, vec2(0.0, 0.24), vec2(0.0, 0.48), 0.05));
        layer(o, min(ring, max(body, -key)), tint);
    } else if (icon == 12) {
        // ESTRELLA dorada
        float d = sd_star(vec2(p.x, -p.y), 0.74, 5.0, 3.3) - 0.07;
        filled(o, d, C_YELLOW);
    } else if (icon == 13) {
        // FLECHA a la derecha (se mece sola)
        vec2 q = vec2(-p.x + sin(TIME * 4.0) * 0.07, p.y);
        float d = min(sd_seg(q, vec2(-0.65, 0.0), vec2(0.7, 0.0), 0.1),
                      min(sd_seg(q, vec2(-0.68, 0.0), vec2(-0.1, -0.6), 0.1),
                          sd_seg(q, vec2(-0.68, 0.0), vec2(-0.1, 0.6), 0.1)));
        layer(o, d, tint);
    } else if (icon == 14) {
        // SLIME contento
        vec2 q = p - vec2(0.0, 0.12);
        float d = sd_rbox(q, vec2(0.86, 0.6), 0.58);
        filled(o, d, C_PURPLE);
        layer(o, length(q - vec2(-0.3, -0.04)) - 0.09, tint);
        layer(o, length(q - vec2(0.3, -0.04)) - 0.09, tint);
        float smile = abs(length(q - vec2(0.0, 0.02)) - 0.2) - 0.05;
        layer(o, max(smile, -(q.y - 0.04)), tint);
        layer(o, length((q - vec2(-0.45, -0.32)) * vec2(1.0, 1.6)) - 0.1, vec4(1.0, 1.0, 1.0, 0.8));
    } else if (icon == 15) {
        // BRILLOS (limpiar)
        float d1 = sparkle((p - vec2(-0.1, 0.1)) * 1.15) / 1.15;
        float d2 = sparkle((p - vec2(0.58, -0.58)) * 2.8) / 2.8;
        float d = min(d1, d2);
        layer(o, d, tint);
        layer(o, d + 0.05, C_SKY);
    }

    COLOR = o;
}
