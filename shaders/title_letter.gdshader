shader_type canvas_item;
// Letras del título. El Label se dibuja con relleno blanco y contorno azul oscuro;
// aquí solo se recolorea el relleno y el contorno se deja tal cual.

uniform float offset = 0.0;       // desfase por letra (lo asigna animated_title.gd)
uniform float speed = 0.35;       // velocidad con la que cambian los colores
uniform float rainbow : hint_range(0.0, 1.0) = 1.0;                    // 0 = un solo color
uniform vec4 fixed_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);   // color si rainbow = 0

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
    // Relleno = casi blanco; contorno = azul oscuro (luminosidad baja)
    float is_fill = step(0.6, dot(COLOR.rgb, vec3(0.3333333)));

    float h = fract(offset + TIME * speed * 0.2);
    vec3 col = mix(fixed_color.rgb, hsv2rgb(vec3(h, 0.65, 1.0)), rainbow);
    col *= 0.94 + 0.06 * sin(TIME * 5.0 + offset * 20.0);   // titileo suave

    COLOR.rgb = mix(COLOR.rgb, col, is_fill);
}
