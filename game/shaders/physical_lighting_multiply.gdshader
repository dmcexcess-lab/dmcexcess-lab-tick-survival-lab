shader_type canvas_item;
render_mode unshaded, blend_mul;

float edge_weight(float center_value, float neighbor_value) {
    float delta = abs(center_value - neighbor_value);
    return 1.0 - smoothstep(0.12, 0.34, delta);
}

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec4 center = texture(TEXTURE, UV);
    vec4 north = texture(TEXTURE, UV - vec2(0.0, px.y));
    vec4 east = texture(TEXTURE, UV + vec2(px.x, 0.0));
    vec4 south = texture(TEXTURE, UV + vec2(0.0, px.y));
    vec4 west = texture(TEXTURE, UV - vec2(px.x, 0.0));

    float wn = 0.28 * edge_weight(center.a, north.a);
    float we = 0.28 * edge_weight(center.a, east.a);
    float ws = 0.28 * edge_weight(center.a, south.a);
    float ww = 0.28 * edge_weight(center.a, west.a);
    float weight = 1.0 + wn + we + ws + ww;

    float luminance = (
        center.a
        + north.a * wn
        + east.a * we
        + south.a * ws
        + west.a * ww
    ) / weight;
    vec3 tint = (
        center.rgb
        + north.rgb * wn
        + east.rgb * we
        + south.rgb * ws
        + west.rgb * ww
    ) / weight;

    float perceptual = pow(clamp(luminance, 0.0, 1.0), 0.52);
    vec3 darkness_floor = vec3(0.055, 0.065, 0.10);
    vec3 lit_tint = mix(vec3(1.0), clamp(tint, vec3(0.0), vec3(1.0)), 0.42);
    vec3 multiplier = mix(darkness_floor, lit_tint, perceptual);
    COLOR = vec4(clamp(multiplier, vec3(0.0), vec3(1.0)), 1.0);
}
