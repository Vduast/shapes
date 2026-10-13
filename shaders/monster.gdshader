shader_type canvas_item;

uniform vec4 body_color : source_color = vec4(0.87, 0.27, 0.41, 1.0);
uniform float excite : hint_range(0.0, 1.0) = 0.0;   // se agita cuando hay una figura cerca
uniform float squish : hint_range(-1.0, 1.0) = 0.0;  // 1 = aplastado, -1 = estirado
uniform float idle_squish = 0.05;                    // fuerza del latido constante
uniform float idle_speed = 2.4;                      // velocidad del latido

const float FLOOR_Y = 0.64;

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

float ell_sd(vec2 p, vec2 r) {
    return (length(p / r) - 1.0) * min(r.x, r.y);
}

// Silueta de huevito: arriba más angosto, abajo ancho y casi plano
float slime_sd(vec2 q) {
    float top = ell_sd(q - vec2(0.0, -0.02), vec2(0.60, 0.58));
    float bot = ell_sd(q - vec2(0.0, 0.26), vec2(0.78, 0.40));
    float d = smin(top, bot, 0.35);
    return smax(d, q.y - FLOOR_Y, 0.12);
}

float fill(float d, float aa) {
    return 1.0 - smoothstep(-aa, aa, d);
}

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;

    // ---- Squish arriba/abajo anclado al piso, conserva volumen ----
    float idle = idle_squish * sin(TIME * idle_speed) + 0.06 * excite * sin(TIME * 10.0);
    float sy = clamp(1.0 - 0.32 * squish + idle, 0.6, 1.4);
    float sx = 1.0 / sqrt(sy);

    vec2 q = vec2(p.x / sx, FLOOR_Y + (p.y - FLOOR_Y) / sy);
    q.x += 0.012 * excite * sin(q.y * 9.0 + TIME * 8.0);

    // ---- Máscaras ----
    float d_out = slime_sd(q);
    float aa = max(fwidth(d_out), 0.002);
    float outer_m = fill(d_out - 0.045, aa);                          // contorno claro
    float rim_m = fill(d_out, aa);                                    // borde rosa claro
    float inner_m = fill(slime_sd(q - vec2(0.0, 0.035)) + 0.075, aa); // relleno (más bajo y más chico)

    // ---- Colores a partir de body_color ----
    vec3 body = body_color.rgb;
    vec3 pale = mix(vec3(1.0), body, 0.06);
    vec3 rim = mix(body, vec3(1.0), 0.42);
    vec3 c_top = mix(body, vec3(1.0), 0.10);
    vec3 c_bot = body * 0.90;
    float g = smoothstep(-0.55, 0.62, q.y);
    vec3 inner_col = mix(c_top, c_bot, g);

    // ---- Puntito blanco con halo arriba ----
    vec2 dp = q - vec2(-0.03, -0.50);
    float halo = fill(ell_sd(dp, vec2(0.105, 0.075)), aa);
    float dot_m = fill(length(dp) - 0.05, aa);
    vec3 halo_col = mix(rim, vec3(1.0), 0.2);

    vec3 col = pale;
    col = mix(col, rim, rim_m);
    col = mix(col, inner_col, inner_m);
    col = mix(col, halo_col, halo * rim_m);
    col = mix(col, vec3(1.0), dot_m * rim_m);

    // ---- Sombra suave en el piso ----
    float sh = (1.0 - smoothstep(-0.05, 0.05, ell_sd(p - vec2(0.0, 0.70), vec2(0.80 * sx, 0.11)))) * 0.25;

    float a = outer_m + sh * (1.0 - outer_m);
    vec3 outc = (col * outer_m + body * 0.2 * sh * (1.0 - outer_m)) / max(a, 0.001);

    COLOR = vec4(outc, a);
}