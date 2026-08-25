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
uniform vec4 leaf_color : source_color = vec4(0.54, 0.42, 0.18, 0.92);
uniform vec4 paper_color : source_color = vec4(0.82, 0.80, 0.72, 0.90);
uniform vec4 dust_color : source_color = vec4(0.62, 0.53, 0.40, 0.52);
uniform vec4 lightning_color : source_color = vec4(0.76, 0.87, 1.0, 1.0);

uniform vec4 debris0 = vec4(-1.0);
uniform vec4 debris1 = vec4(-1.0);
uniform vec4 debris2 = vec4(-1.0);
uniform float debris_kind0 = 0.0;
uniform float debris_kind1 = 0.0;
uniform float debris_kind2 = 0.0;

uniform float lightning_active = 0.0;
uniform float lightning_seed = 1.0;
uniform float lightning_intensity = 0.0;
uniform float lightning_start_time = 0.0;
uniform float lightning_duration = 0.32;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345 + presentation_seed * 0.0001);
    return fract(p.x * p.y);
}

float seeded_hash(float seed_value, float salt) {
    return hash21(vec2(seed_value * 0.00031 + salt * 0.173, salt * 0.619));
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float denom = max(dot(ba, ba), 0.0001);
    float h = clamp(dot(pa, ba) / denom, 0.0, 1.0);
    return length(pa - ba * h);
}

// P3B: sparse jittered macro-cells replace the old five-row rain bands.
// Each larger patch can host one independently phased streak, while a still
// coarser hash biases nearby patches together. The 2 px pixel-art scale stays
// intact without exposing a repeating horizontal lattice.
float rain_layer(vec2 screen_px) {
    if (precipitation < 0.04) {
        return 0.0;
    }

    float px = max(1.0, rain_pixel_size);
    float frame = floor(TIME * rain_fps);
    float fall_step = floor(mix(2.0, 4.0, precipitation) + 0.5);
    vec2 wind = wind_direction * wind_strength;
    vec2 shifted = floor(screen_px / px);
    shifted.y -= frame * fall_step;
    shifted.x -= floor(frame * wind.x * 0.55);

    float macro_w = floor(mix(16.0, 10.0, precipitation) + 0.5);
    float macro_h = floor(mix(24.0, 15.0, precipitation) + 0.5);
    vec2 macro_size = vec2(macro_w, macro_h);
    vec2 macro_cell = floor(shifted / macro_size);
    vec2 local = shifted - macro_cell * macro_size;

    vec2 cluster_cell = floor((macro_cell + vec2(1.0, 2.0)) / vec2(4.0, 3.0));
    float cluster_bias = hash21(cluster_cell + vec2(presentation_seed * 0.0017, 61.0));
    float candidate_hash = hash21(macro_cell + vec2(presentation_seed * 0.0031, 23.0));
    float candidate_chance = clamp(
        mix(0.14, 0.62, precipitation) + (cluster_bias - 0.5) * 0.28,
        0.05,
        0.82
    );
    if (candidate_hash > candidate_chance) {
        return 0.0;
    }

    float detail_hash = hash21(macro_cell + vec2(47.0, presentation_seed * 0.0023 + 11.0));
    float anchor_x = floor(fract(detail_hash * 7.13) * macro_w);
    float anchor_y = floor(fract(detail_hash * 13.71) * macro_h);
    float streak_seed = fract(detail_hash * 17.17);
    float streak_len = 1.0 + step(0.72, streak_seed);
    float phase_y = mod(local.y - anchor_y + macro_h, macro_h);
    float dx = abs(local.x - anchor_x);
    dx = min(dx, macro_w - dx);

    float in_streak = 1.0 - step(streak_len, phase_y);
    float one_weather_pixel_wide = 1.0 - step(0.5, dx);
    float brightness = mix(0.42, 1.0, fract(detail_hash * 31.31));
    return in_streak * one_weather_pixel_wide * brightness;
}

// P3B fog uses staggered coarse rows and small diamond-like pixel clouds.
// It remains deliberately low-frequency and cheap, but no longer presents as
// aligned rectangular tiles when the 2 px base pixel is visible.
float fog_layer(vec2 screen_px) {
    if (fog_density < 0.08) {
        return 0.0;
    }

    float px = max(1.0, fog_pixel_size);
    float frame = floor(TIME * fog_fps);
    vec2 wind = wind_direction * max(0.12, wind_strength);
    vec2 shifted = floor(screen_px / px);
    shifted -= floor(vec2(frame * wind.x * 0.40, frame * wind.y * 0.22));

    float fog_row = floor(shifted.y / 10.0);
    float row_jitter = (hash21(vec2(fog_row, presentation_seed * 0.0019 + 71.0)) - 0.5) * 14.0;
    vec2 coarse = vec2(shifted.x + row_jitter, shifted.y) / vec2(18.0, 10.0);
    vec2 cell = floor(coarse);
    vec2 local = fract(coarse);

    float presence_hash = hash21(cell + vec2(presentation_seed * 0.002, 41.0));
    float threshold = mix(0.95, 0.50, fog_density);
    if (presence_hash < threshold) {
        return 0.0;
    }

    float shape_hash = hash21(cell + vec2(73.0, 19.0));
    vec2 center = vec2(
        0.50 + (fract(shape_hash * 7.7) - 0.5) * 0.18,
        0.50 + (fract(shape_hash * 13.3) - 0.5) * 0.18
    );
    vec2 radius = vec2(
        0.38 + fract(shape_hash * 17.9) * 0.10,
        0.32 + fract(shape_hash * 23.1) * 0.10
    );
    vec2 normalized_delta = abs(local - center) / radius;
    float cloud = 1.0 - step(1.0, normalized_delta.x + normalized_delta.y);
    float strength = mix(0.45, 1.0, presence_hash);
    return cloud * strength;
}

vec4 debris_layer(vec2 screen_px, vec2 screen_size, vec4 data, float kind) {
    if (data.z < 0.5 || data.x < 0.0 || data.y < 0.0) {
        return vec4(0.0);
    }
    vec2 center = vec2(data.x, data.y) * screen_size;
    vec2 half_size = vec2(2.0, 1.0);
    vec4 tint = leaf_color;
    if (kind > 1.5) {
        half_size = vec2(3.0, 1.0);
        tint = dust_color;
    } else if (kind > 0.5) {
        half_size = vec2(2.0, 2.0);
        tint = paper_color;
    }
    vec2 delta = abs(screen_px - center);
    float inside = (1.0 - step(half_size.x, delta.x)) * (1.0 - step(half_size.y, delta.y));
    return tint * inside;
}

vec4 lightning_layer(vec2 screen_px, vec2 screen_size) {
    if (lightning_active < 0.5 || lightning_duration <= 0.0) {
        return vec4(0.0);
    }
    float age = TIME - lightning_start_time;
    if (age < 0.0 || age > lightning_duration) {
        return vec4(0.0);
    }
    float envelope = clamp(1.0 - age / lightning_duration, 0.0, 1.0);
    float flash_alpha = 0.14 * lightning_intensity * envelope;
    vec4 result = vec4(lightning_color.rgb, flash_alpha);

    float x = screen_size.x * (0.20 + 0.60 * seeded_hash(lightning_seed, 11.0));
    vec2 previous = vec2(x, -4.0);
    float bolt = 0.0;
    for (int i = 1; i <= 7; i++) {
        float fi = float(i);
        float y = screen_size.y * 0.68 * fi / 7.0;
        float jitter = (seeded_hash(lightning_seed, 31.0 + fi * 17.0) * 2.0 - 1.0) * 8.0;
        x = clamp(x + jitter, 4.0, screen_size.x - 4.0);
        vec2 next_point = vec2(x, y);
        bolt = max(bolt, 1.0 - step(2.0, segment_distance(screen_px, previous, next_point)));
        previous = next_point;
    }
    if (bolt > 0.0) {
        result.rgb = lightning_color.rgb;
        result.a = max(result.a, 0.88 * envelope);
    }
    return result;
}

vec4 over(vec4 under_color, vec4 over_color) {
    float a = over_color.a + under_color.a * (1.0 - over_color.a);
    if (a <= 0.0001) {
        return vec4(0.0);
    }
    vec3 rgb = (over_color.rgb * over_color.a + under_color.rgb * under_color.a * (1.0 - over_color.a)) / a;
    return vec4(rgb, a);
}

void fragment() {
    vec2 screen_size = vec2(1.0) / max(SCREEN_PIXEL_SIZE, vec2(0.000001));
    vec2 screen_px = SCREEN_UV * screen_size;
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
        out_color = over(out_color, vec4(fog_color.rgb, fog_color.a * fog * fog_density));
    }
    if (rain > 0.0) {
        out_color = over(out_color, vec4(rain_tint.rgb, rain_tint.a * rain));
    }
    out_color = over(out_color, debris_layer(screen_px, screen_size, debris0, debris_kind0));
    out_color = over(out_color, debris_layer(screen_px, screen_size, debris1, debris_kind1));
    out_color = over(out_color, debris_layer(screen_px, screen_size, debris2, debris_kind2));
    out_color = over(out_color, lightning_layer(screen_px, screen_size));
    COLOR = out_color;
}
