shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burst_color : source_color = vec4(1.0);

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    float r = length(p);
    float fade = 1.0 - progress;
    float e = 1.0 - pow(1.0 - progress, 3.0);

    // Anillo que se expande
    float ring_r = mix(0.4, 0.9, e);
    float ring_w = 0.08 * fade + 0.01;
    float ring = 1.0 - smoothstep(ring_w * 0.5, ring_w, abs(r - ring_r));

    vec3 col = burst_color.rgb;
    float a = ring * fade;

    // Chispas en forma de rombo
    for (int i = 0; i < 10; i++) {
        float fi = float(i);
        float ang = fi * 0.6283 + 0.3;
        float dist = mix(0.4, 0.65 + 0.2 * mod(fi, 2.0), e);
        vec2 c = dist * vec2(cos(ang), sin(ang));
        float s = (0.07 + 0.03 * mod(fi, 3.0)) * fade;
        vec2 dd = abs(p - c);
        float spark = 1.0 - smoothstep(-0.01, 0.01, dd.x + dd.y - s);
        vec3 sc = (mod(fi, 2.0) < 1.0) ? vec3(1.0) : burst_color.rgb;
        col = mix(col, sc, spark);
        a = max(a, spark * fade);
    }

    COLOR = vec4(col, a);
}