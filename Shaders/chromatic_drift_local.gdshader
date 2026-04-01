shader_type canvas_item;

uniform float intensity : hint_range(0.0, 5.0) = 1.5;
uniform float drift_speed : hint_range(0.0, 3.0) = 0.6;
uniform float tear_strength : hint_range(0.0, 0.05) = 0.008;
uniform float line_wobble : hint_range(0.0, 0.02) = 0.003;
uniform float noise_scale : hint_range(1.0, 200.0) = 48.0;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    float t = TIME * drift_speed;

    vec2 uv = UV;

    // Subtle horizontal line wobble: feels like scan instability
    float wobble = sin(uv.y * 90.0 + t * 2.3) * line_wobble * intensity;
    uv.x += wobble;

    // Occasional local tearing bands
    float band = floor(uv.y * 18.0 + t * 0.7);
    float band_noise = hash(band + floor(t * 3.0));
    if (band_noise > 0.82) {
        uv.x += (band_noise - 0.82) * tear_strength * 20.0 * intensity;
    }

    // Organic channel drift, stronger in "noisier" local regions
    float local_noise = hash2(floor(uv * noise_scale) + floor(t * 2.0));
    vec2 r_off = vec2(
        sin(t * 1.3 + uv.y * 7.0 + local_noise * 3.0) * 0.004,
        cos(t * 0.9 + local_noise * 5.0) * 0.0015
    ) * intensity;

    vec2 b_off = vec2(
        cos(t * 1.1 + uv.x * 6.0 + local_noise * 4.0) * 0.0035,
        sin(t * 1.7 + local_noise * 6.0) * 0.0015
    ) * intensity;

    vec4 base = texture(TEXTURE, uv);
    float r = texture(TEXTURE, uv + r_off).r;
    float g = base.g;
    float b = texture(TEXTURE, uv + b_off).b;

    // Tiny brightness flutter to make it feel electronically unstable
    float flicker = 1.0 + (hash(floor(t * 24.0)) - 0.5) * 0.06 * intensity;

    COLOR = vec4(vec3(r, g, b) * flicker, base.a);
}