shader_type canvas_item;
render_mode unshaded, blend_mul;

void fragment() {
    vec4 sample = texture(TEXTURE, UV);
    float luminance = clamp(sample.a, 0.0, 1.0);
    vec3 tint = clamp(sample.rgb, vec3(0.0), vec3(1.0));
    vec3 darkness_floor = vec3(0.055, 0.065, 0.10);
    vec3 multiplier = mix(darkness_floor, tint, luminance);
    COLOR = vec4(multiplier, 1.0);
}
