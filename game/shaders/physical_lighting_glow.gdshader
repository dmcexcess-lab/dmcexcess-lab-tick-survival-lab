shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float glow_strength = 0.46;
uniform float scatter_strength = 0.0;
uniform float wetness = 0.0;
uniform float outer_glow_strength = 0.22;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec4 center = texture(TEXTURE, UV);

    vec4 n1 = texture(TEXTURE, UV - vec2(0.0, px.y));
    vec4 e1 = texture(TEXTURE, UV + vec2(px.x, 0.0));
    vec4 s1 = texture(TEXTURE, UV + vec2(0.0, px.y));
    vec4 w1 = texture(TEXTURE, UV - vec2(px.x, 0.0));
    vec4 ne = texture(TEXTURE, UV + vec2(px.x, -px.y));
    vec4 se = texture(TEXTURE, UV + vec2(px.x, px.y));
    vec4 sw = texture(TEXTURE, UV + vec2(-px.x, px.y));
    vec4 nw = texture(TEXTURE, UV + vec2(-px.x, -px.y));

    vec4 n2 = texture(TEXTURE, UV - vec2(0.0, px.y * 2.0));
    vec4 e2 = texture(TEXTURE, UV + vec2(px.x * 2.0, 0.0));
    vec4 s2 = texture(TEXTURE, UV + vec2(0.0, px.y * 2.0));
    vec4 w2 = texture(TEXTURE, UV - vec2(px.x * 2.0, 0.0));

    float inner_alpha = (
        center.a * 0.34
        + (n1.a + e1.a + s1.a + w1.a) * 0.105
        + (ne.a + se.a + sw.a + nw.a) * 0.06
    );
    vec3 inner_color = (
        center.rgb * max(center.a, 0.02) * 0.34
        + (n1.rgb * max(n1.a, 0.02) + e1.rgb * max(e1.a, 0.02)
        + s1.rgb * max(s1.a, 0.02) + w1.rgb * max(w1.a, 0.02)) * 0.105
        + (ne.rgb * max(ne.a, 0.02) + se.rgb * max(se.a, 0.02)
        + sw.rgb * max(sw.a, 0.02) + nw.rgb * max(nw.a, 0.02)) * 0.06
    ) / max(inner_alpha, 0.02);

    float outer_alpha = (n2.a + e2.a + s2.a + w2.a) * 0.25;
    vec3 outer_color = (
        n2.rgb * max(n2.a, 0.02)
        + e2.rgb * max(e2.a, 0.02)
        + s2.rgb * max(s2.a, 0.02)
        + w2.rgb * max(w2.a, 0.02)
    ) / max(n2.a + e2.a + s2.a + w2.a, 0.02);

    float core = clamp(center.a * 1.10, 0.0, 1.0);
    float inner_halo = clamp(center.a * 0.72 + inner_alpha * 0.52, 0.0, 1.0);
    float outer_halo = clamp(outer_alpha * outer_glow_strength, 0.0, 1.0);
    float scatter = inner_halo * scatter_strength * 0.24;

    vec4 reflection_source = texture(TEXTURE, UV - vec2(0.0, px.y * 2.0));
    float reflection = reflection_source.a * wetness * 0.15;

    float local_energy = inner_halo * glow_strength + outer_halo + scatter;
    vec3 color_energy = (
        inner_color * local_energy
        + outer_color * outer_halo
        + center.rgb * core * 0.12
        + reflection_source.rgb * reflection
    );
    float alpha = clamp(local_energy + core * 0.08 + reflection, 0.0, 1.0);
    COLOR = vec4(color_energy, alpha);
}
