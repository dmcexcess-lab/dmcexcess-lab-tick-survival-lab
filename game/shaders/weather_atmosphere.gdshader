shader_type canvas_item;
render_mode unshaded;

uniform sampler2D exposure_mask : filter_nearest, repeat_disable;
uniform vec2 mask_uv_origin = vec2(0.0);
uniform vec2 mask_uv_scale = vec2(1.0);

uniform float precipitation : hint_range(0.0, 1.0) = 0.0;
uniform float fog_density : hint_range(0.0, 1.0) = 0.0;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.0;
uniform float presentation_seed = 1.0;
uniform float rain_pixel_size = 2.0;
uniform float rain_fps = 14.0;
uniform float fog_pixel_size = 2.0;
uniform float fog_fps = 4.0;
uniform vec4 rain_color : source_color = vec4(0.72, 0.82, 0.92, 0.68);
uniform vec4 storm_rain_color : source_color = vec4(0.64, 0.76, 0.90, 0.78);
uniform vec4 fog_color : source_color = vec4(0.76, 0.79, 0.80, 0.085);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345 + presentation_seed * 0.0001);
    return fract(p.x * p.y);
}

float rain_layer(vec2 screen_px) {
    if (precipitation < 0.04) {
        return 0.0;
    }

    float px = max(1.0, rain_pixel_size);
    float frame = floor(TIME * rain_fps);
    float fall_speed = mix(2.0, 5.0, precipitation);
    vec2 wind = wind_direction * wind_strength;
    vec2 shifted = screen_px / px;
    shifted.y += frame * fall_speed;
    shifted.x -= frame * wind.x * 0.85;

    vec2 cell = floor(shifted);
    vec2 local = fract(shifted);
    float row_seed = hash21(vec2(cell.x, floor(cell.y / 5.0)) + vec2(presentation_seed * 0.001, 0.0));
    float density = mix(0.018, 0.070, precipitation);
    if (row_seed > density) {
        return 0.0;
    }

    float streak_len = 1.0 + step(0.52, hash21(cell + vec2(17.0, 29.0)));
    float phase = mod(cell.y + floor(hash21(cell + 4.0) * 5.0), 5.0);
    float in_streak = 1.0 - step(streak_len, phase);
    float narrow = 1.0 - step(0.78, local.x);
    return in_streak * narrow;
}

float fog_layer(vec2 screen_px) {
    if (fog_density < 0.08) {
        return 0.0;
    }

    float px = max(1.0, fog_pixel_size);
    float frame = floor(TIME * fog_fps);
    vec2 wind = wind_direction * max(0.12, wind_strength);
    vec2 coarse = screen_px / (px * vec2(8.0, 4.0));
    coarse -= vec2(frame * wind.x * 0.10, frame * wind.y * 0.05);
    vec2 cell = floor(coarse);
    vec2 local = fract(coarse);

    float n0 = hash21(cell + vec2(presentation_seed * 0.002, 41.0));
    float n1 = hash21(cell + vec2(73.0, 19.0));
    float threshold = mix(0.88, 0.56, fog_density);
    float present = step(threshold, n0);
    float soft_block = 1.0 - step(0.88 + n1 * 0.08, local.x);
    return present * soft_block;
}

void fragment() {
    vec2 screen_px = SCREEN_UV / max(SCREEN_PIXEL_SIZE, vec2(0.000001));
    vec2 mask_uv = mask_uv_origin + SCREEN_UV * mask_uv_scale;
    float exposed = 0.0;
    if (all(greaterThanEqual(mask_uv, vec2(0.0))) && all(lessThanEqual(mask_uv, vec2(1.0)))) {
        exposed = texture(exposure_mask, mask_uv).r;
    }

    float rain = rain_layer(screen_px) * exposed;
    float fog = fog_layer(screen_px);

    vec4 rain_tint = mix(rain_color, storm_rain_color, smoothstep(0.76, 1.0, precipitation));
    vec4 out_color = vec4(0.0);
    if (fog > 0.0) {
        out_color = fog_color * vec4(1.0, 1.0, 1.0, fog * fog_density);
    }
    if (rain > 0.0) {
        float rain_alpha = rain_tint.a * rain;
        out_color.rgb = mix(out_color.rgb, rain_tint.rgb, rain_alpha);
        out_color.a = max(out_color.a, rain_alpha);
    }
    COLOR = out_color;
}
