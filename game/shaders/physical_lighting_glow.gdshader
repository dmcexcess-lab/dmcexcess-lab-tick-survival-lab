shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float glow_strength = 0.42;
uniform float scatter_strength = 0.0;
uniform float wetness = 0.0;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec4 center = texture(TEXTURE, UV);
    vec4 north = texture(TEXTURE, UV - vec2(0.0, px.y));
    vec4 east = texture(TEXTURE, UV + vec2(px.x, 0.0));
    vec4 south = texture(TEXTURE, UV + vec2(0.0, px.y));
    vec4 west = texture(TEXTURE, UV - vec2(px.x, 0.0));

    float blur_alpha = (
        center.a * 0.46
        + north.a * 0.135
        + east.a * 0.135
        + south.a * 0.135
        + west.a * 0.135
    );
    vec3 blur_color = (
        center.rgb * max(center.a, 0.02) * 0.46
        + north.rgb * max(north.a, 0.02) * 0.135
        + east.rgb * max(east.a, 0.02) * 0.135
        + south.rgb * max(south.a, 0.02) * 0.135
        + west.rgb * max(west.a, 0.02) * 0.135
    ) / max(blur_alpha, 0.02);

    float halo = clamp(center.a * 0.78 + blur_alpha * 0.42, 0.0, 1.0);
    float scatter = halo * scatter_strength * 0.24;

    vec4 reflection_source = texture(TEXTURE, UV - vec2(0.0, px.y * 2.0));
    float reflection = reflection_source.a * wetness * 0.15;
    vec3 reflection_color = reflection_source.rgb;

    float local_energy = halo * glow_strength + scatter;
    vec3 color_energy = blur_color * local_energy + reflection_color * reflection;
    float alpha = clamp(local_energy + reflection, 0.0, 1.0);
    COLOR = vec4(color_energy, alpha);
}
