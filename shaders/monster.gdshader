shader_type canvas_item;
// Slime estilo "gominola": silueta de gota, borde claro, brillo arriba y una cara grande
// y expresiva (ojos ovalados con brillos, boca en D con lengua, mejillas, lágrimas y
// destellos). La cara la anima slime_face.gd a través de los uniforms de abajo.

uniform vec4 body_color : source_color = vec4(0.87, 0.27, 0.41, 1.0);
uniform float excite : hint_range(0.0, 1.0) = 0.0;   // se agita cuando hay una figura cerca
uniform float squish : hint_range(-1.0, 1.0) = 0.0;  // 1 = aplastado, -1 = estirado
uniform float idle_squish = 0.05;                    // fuerza del latido constante
uniform float idle_speed = 2.4;                      // velocidad del latido

// ---- Cara (los nombres coinciden con SlimeFace.PRESETS) ----
uniform float eye_open : hint_range(0.0, 1.0) = 1.0;    // 0 = rayita (cerrado), 1 = abierto
uniform float eye_happy : hint_range(0.0, 1.0) = 0.0;   // 1 = ojos felices en arco (^ ^)
uniform float eye_size = 1.0;                           // escala de los ojos
uniform float shine = 1.0;                              // tamaño de los brillos (>1 = ojos llorosos/brillantes)
uniform float brow : hint_range(-1.0, 1.0) = 0.0;       // -1 = triste, 1 = enojado (párpado inclinado)
uniform float blink : hint_range(0.0, 1.0) = 0.0;       // parpadeo (lo dispara el script)
uniform vec2 look = vec2(0.0);                          // hacia dónde mira (-1..1)
uniform float mouth_curve : hint_range(-1.0, 1.0) = 0.6; // -1 = ceño, 1 = sonrisa
uniform float mouth_open : hint_range(0.0, 1.0) = 0.18; // 0 = línea, 1 = bien abierta
uniform float mouth_width = 0.75;                       // ancho de la boca
uniform float blush : hint_range(0.0, 1.0) = 0.0;       // mejillas rosadas
uniform float tears : hint_range(0.0, 1.0) = 0.0;       // lágrimas que caen
uniform float sparkle : hint_range(0.0, 1.0) = 0.0;     // destellos alrededor (fiesta)

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

// Silueta de gominola: punta redondeada arriba, panza ancha y base casi plana
float slime_sd(vec2 q) {
    float top = ell_sd(q - vec2(0.0, -0.10), vec2(0.50, 0.52));
    float bot = ell_sd(q - vec2(0.0, 0.25), vec2(0.76, 0.41));
    float d = smin(top, bot, 0.5);
    return smax(d, q.y - FLOOR_Y, 0.12);
}

float fill(float d, float aa) {
    return 1.0 - smoothstep(-aa, aa, d);
}

// Ojo. e = coordenadas relativas al centro del ojo, side = -1 (izquierdo) o 1 (derecho).
// Devuelve x = máscara del ojo, y = máscara de los brillos.
vec2 eye_face(vec2 e, float side) {
    float op = clamp(eye_open * (1.0 - blink), 0.0, 1.0);
    float sz = eye_size;

    // Ojo ovalado y vertical: se aplana hasta ser una rayita al cerrarse
    vec2 r = vec2(mix(0.085, 0.058, op), mix(0.014, 0.108, op)) * sz;
    float d = ell_sd(e, r);

    // Párpado inclinado: brow > 0 baja el lado interno (enojado), brow < 0 el externo (triste)
    float lid_side = (brow > 0.0 ? -side : side) * e.x;
    float thr = -0.32 + abs(brow) * (0.27 + 1.2 * lid_side);
    d = max(d, thr - e.y);

    // Ojo feliz: arco hacia arriba (^)
    float hw = 0.095 * sz;
    float x = clamp(e.x, -hw, hw);
    float u = x / hw;
    float yc = (-0.035 + 0.075 * u * u) * sz;
    float dh = length(vec2(e.x - x, e.y - yc)) - 0.022 * sz;

    float aa1 = max(fwidth(d), 0.002);
    float aa2 = max(fwidth(dh), 0.002);
    float round_m = fill(d, aa1);
    float eye_m = mix(round_m, fill(dh, aa2), eye_happy);

    // Brillos: uno grande arriba a la izquierda y uno chiquito abajo a la derecha
    float big_r = min(0.024 * sz * shine, 0.05);
    float sh1 = fill(length(e - vec2(-0.018, -0.048) * sz) - big_r, aa1);
    float sh2 = fill(length(e - vec2(0.016, 0.050) * sz) - 0.012 * sz * min(shine, 1.5), aa1);
    float sh = max(sh1, sh2) * round_m * op * (1.0 - eye_happy);
    return vec2(eye_m, sh);
}

// Lágrima que nace bajo el ojo, cae y se desvanece. ph desfasa un ojo del otro.
float tear_drop(vec2 e, float side, float ph) {
    float t = fract(TIME * 0.7 + ph);
    vec2 c = vec2(side * 0.015, 0.10 + t * 0.30);
    float d = length(e - c) - 0.034 * (1.0 - 0.5 * t);
    return fill(d, 0.008) * (1.0 - t * t);
}

// Boca. m = coordenadas relativas al centro de la boca.
// Una curva con grosor (sonrisa o ceño); con mouth_open > 0 se abre hacia abajo formando
// una "D" (borde de arriba casi recto, borde de abajo redondo).
// Devuelve x = forma completa, y = interior (sin el borde), z = lengua.
vec3 mouth_face(vec2 m) {
    float w = 0.20 * mouth_width;
    float cx = clamp(m.x, -w, w);
    float prof = 1.0 - (cx / w) * (cx / w);
    float curve = mouth_curve * mix(0.09, 0.045, mouth_open);
    float top = curve * prof;
    float bot = top + mouth_open * 0.30 * prof;
    float dy = max(top - m.y, m.y - bot);
    float dx = abs(m.x - cx);
    float d = length(vec2(dx, max(dy, 0.0))) + (dx > 0.0 ? 0.0 : min(dy, 0.0)) - 0.018;

    float aa = max(fwidth(d), 0.002);
    float shape_m = fill(d, aa);
    float inner_m = fill(d + 0.03, aa);

    // Lengua: aparece cuando la boca está bien abierta
    float bot0 = curve + mouth_open * 0.30;
    float dt = ell_sd(m - vec2(0.0, bot0 - 0.07), vec2(0.11 * mouth_width, 0.055));
    float tongue = fill(dt, max(fwidth(dt), 0.002)) * inner_m * smoothstep(0.35, 0.65, mouth_open);
    return vec3(shape_m, inner_m, tongue);
}

// Destello de cuatro puntas
float star4(vec2 p, float r) {
    p = abs(p);
    float d = (pow(p.x / r, 0.5) + pow(p.y / r, 0.5) - 1.0) * r * 0.5;
    return 1.0 - smoothstep(-0.01, 0.01, d);
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
    float rim_m = fill(d_out, aa);                                    // borde más oscuro
    float inner_m = fill(slime_sd(q - vec2(0.0, 0.035)) + 0.075, aa); // relleno (más bajo y más chico)

    // ---- Colores a partir de body_color ----
    vec3 body = body_color.rgb;
    vec3 pale = mix(vec3(1.0), body, 0.06);
    vec3 rim = mix(body, vec3(1.0), 0.42);
    vec3 c_top = mix(body, vec3(1.0), 0.12);
    vec3 c_bot = body * 0.86;
    float g = smoothstep(-0.55, 0.62, q.y);
    vec3 inner_col = mix(c_top, c_bot, g);

    // ---- Puntito blanco con halo en la punta ----
    vec2 dp = q - vec2(-0.03, -0.50);
    float halo = fill(ell_sd(dp, vec2(0.105, 0.075)), aa);
    float dot_m = fill(length(dp) - 0.05, aa);
    vec3 halo_col = mix(rim, vec3(1.0), 0.2);

    vec3 col = pale;
    col = mix(col, rim, rim_m);
    col = mix(col, inner_col, inner_m);
    col = mix(col, halo_col, halo * rim_m);
    col = mix(col, vec3(1.0), dot_m * rim_m);

    // Brillo suave en el costado izquierdo (volumen de gelatina)
    float gl = 1.0 - smoothstep(0.0, 1.0, length((q - vec2(-0.34, -0.10)) / vec2(0.14, 0.26)));
    col = mix(col, vec3(1.0), gl * 0.18 * inner_m);

    // ---- Cara: en el espacio q, así se deforma junto con el cuerpo ----
    // Los ojos y la boca son una versión oscura del color del cuerpo (como en Slime Rancher);
    // si el cuerpo ya es oscuro se acercan al casi negro para no perderse.
    float lum = dot(body, vec3(0.299, 0.587, 0.114));
    vec3 fcol = mix(body * 0.26, vec3(0.03, 0.01, 0.04), 1.0 - smoothstep(0.2, 0.4, lum));
    vec3 tongue_col = mix(body, vec3(1.0), 0.30);
    vec2 gaze = look * vec2(0.04, 0.03);

    // Mejillas
    float bl = fill(ell_sd(q - vec2(-0.50, 0.24) - gaze * 0.5, vec2(0.085, 0.05)), aa);
    float br = fill(ell_sd(q - vec2(0.50, 0.24) - gaze * 0.5, vec2(0.085, 0.05)), aa);
    col = mix(col, vec3(1.0, 0.50, 0.60), max(bl, br) * 0.6 * blush * inner_m);

    // Ojos (anchos de separación, como en las gominolas de Slime Rancher)
    vec2 e_l = q - vec2(-0.36, 0.06) - gaze;
    vec2 e_r = q - vec2(0.36, 0.06) - gaze;
    vec2 fl = eye_face(e_l, -1.0);
    vec2 fr = eye_face(e_r, 1.0);
    col = mix(col, fcol, max(fl.x, fr.x));
    col = mix(col, vec3(1.0), max(fl.y, fr.y));

    // Lágrimas
    float tr = max(tear_drop(e_l, -1.0, 0.0), tear_drop(e_r, 1.0, 0.35));
    col = mix(col, vec3(0.65, 0.88, 1.0), tr * tears * inner_m);

    // Boca
    vec3 mo = mouth_face(q - vec2(0.0, 0.20) - gaze * 0.6);
    col = mix(col, fcol, mo.x);
    col = mix(col, tongue_col, mo.z);

    // ---- Sombra suave en el piso ----
    float sh = (1.0 - smoothstep(-0.05, 0.05, ell_sd(p - vec2(0.0, 0.70), vec2(0.80 * sx, 0.11)))) * 0.25;

    float a = outer_m + sh * (1.0 - outer_m);
    vec3 outc = (col * outer_m + body * 0.2 * sh * (1.0 - outer_m)) / max(a, 0.001);

    // ---- Destellos de fiesta alrededor del slime (en p: no se deforman) ----
    float tw1 = 0.65 + 0.35 * sin(TIME * 6.0);
    float tw2 = 0.65 + 0.35 * sin(TIME * 6.0 + 2.1);
    float tw3 = 0.65 + 0.35 * sin(TIME * 6.0 + 4.2);
    float stars = max(star4(p - vec2(-0.74, -0.50), 0.11 * tw1),
                  max(star4(p - vec2(0.76, -0.36), 0.08 * tw2),
                      star4(p - vec2(0.52, -0.74), 0.06 * tw3))) * sparkle;
    a = max(a, stars);
    outc = mix(outc, vec3(1.0, 0.94, 0.50), stars * (1.0 - outer_m));

    COLOR = vec4(outc, a);
}
