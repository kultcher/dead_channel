// currently unused

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 5.0) = 1.2;
uniform float drift_speed : hint_range(0.0, 3.0) = 0.7;
uniform float tear_strength : hint_range(0.0, 0.05) = 0.01;
uniform float wobble_strength : hint_range(0.0, 0.03) = 0.004;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.08;
uniform float overlay_alpha : hint_range(0.0, 1.0) = 1.0;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    float t = TIME * drift_speed;
    vec2 uv = SCREEN_UV;

    // Global sideways instability
    uv.x += sin(uv.y * 70.0 + t * 2.0) * wobble_strength * intensity;

    // Intermittent horizontal tearing regions
    float row = floor(uv.y * 28.0 + floor(t * 2.5));
    float row_noise = hash(row);
    if (row_noise > 0.88) {
        uv.x += (row_noise - 0.88) * tear_strength * 25.0 * intensity;
    }

    // Localized noise-based desync
    float n = hash2(floor(uv * 60.0) + floor(t * 3.0));

    vec2 r_off = vec2(
        sin(t * 1.4 + uv.y * 8.0 + n * 6.0) * 0.0045,
        0.0
    ) * intensity;

    vec2 b_off = vec2(
        cos(t * 1.2 + uv.x * 7.0 + n * 5.0) * 0.004,
        0.0
    ) * intensity;

    vec4 base = texture(screen_texture, uv);
    float r = texture(screen_texture, uv + r_off).r;
    float g = base.g;
    float b = texture(screen_texture, uv + b_off).b;

    vec3 col = vec3(r, g, b);

    // Mild scanline darkening
    float scan = sin(SCREEN_UV.y * 900.0) * 0.5 + 0.5;
    col *= 1.0 - (scan * scanline_strength * intensity);

    // Slight unstable flicker
    float flicker = 1.0 + (hash(floor(t * 20.0)) - 0.5) * 0.08 * intensity;
    col *= flicker;

    COLOR = vec4(col, overlay_alpha);
}