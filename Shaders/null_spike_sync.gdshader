shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float band_density : hint_range(8.0, 240.0, 1.0) = 80.0;
uniform float stretch_amount : hint_range(0.0, 1.0, 0.001) = 0.08;
uniform float jitter_speed : hint_range(0.0, 20.0, 0.01) = 3.0;
uniform float glow_strength : hint_range(0.0, 2.0, 0.01) = 0.6;
uniform vec4 glow_tint : source_color = vec4(0.75, 1.0, 1.0, 1.0);

float hash11(float n) {
	return fract(sin(n) * 43758.5453123);
}

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	vec4 source = textureLod(screen_texture, screen_uv, 0.0);

	float time_step = floor(TIME * jitter_speed * 6.0);
	float band_id = floor(UV.y * band_density + time_step * 0.17);
	float band_noise = hash11(band_id + time_step * 0.31);

	float luminance = max(source.r, max(source.g, source.b));
	float signal_mask = smoothstep(0.04, 0.52, luminance);
	float row_variation = 0.75 + band_noise * 1.45;
	float local_noise = hash12(vec2(floor(UV.y * band_density), floor(UV.x * 64.0) + time_step));
	float line_gate = smoothstep(0.18, 0.95, hash12(vec2(band_id, time_step * 0.13)));

	vec3 streak_rgb = vec3(0.0);
	float streak_energy = 0.0;
	for (int i = 1; i <= 7; i++) {
		float t = float(i) / 7.0;
		float sample_variation = mix(0.85, 1.65, hash12(vec2(band_id, float(i) + local_noise * 10.0)));
		float reach = stretch_amount * intensity * row_variation * sample_variation * t;
		float y_jitter = (hash12(vec2(float(i) * 17.0, band_id + time_step)) - 0.5) * 0.006 * intensity;
		vec2 offset = vec2(reach, y_jitter);

		vec3 sample_left = textureLod(screen_texture, screen_uv - offset, 0.0).rgb;
		vec3 sample_right = textureLod(screen_texture, screen_uv + offset, 0.0).rgb;
		float left_mask = smoothstep(0.06, 0.64, max(sample_left.r, max(sample_left.g, sample_left.b)));
		float right_mask = smoothstep(0.06, 0.64, max(sample_right.r, max(sample_right.g, sample_right.b)));
		float weight = (1.0 - t) * mix(0.55, 1.15, line_gate);

		streak_rgb += sample_left * left_mask * weight;
		streak_rgb += sample_right * right_mask * weight;
		streak_energy += (left_mask + right_mask) * weight;
	}

	float directional_bias = hash11(band_id * 1.37 + time_step * 0.19);
	vec3 tint_mix = mix(glow_tint.rgb, vec3(1.0, 0.96, 0.78), directional_bias * 0.3);
	streak_rgb *= tint_mix * (1.2 + intensity * 0.8);
	vec3 glow = tint_mix * signal_mask * glow_strength * (0.4 + intensity * 0.9);
	float blend = clamp(intensity * (0.38 + streak_energy * 0.8), 0.0, 1.0);
	vec3 final_rgb = max(source.rgb, streak_rgb * blend + glow);

	COLOR = vec4(final_rgb, 1.0);
}
