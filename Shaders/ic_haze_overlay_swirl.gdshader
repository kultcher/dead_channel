shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 haze_tint : source_color = vec4(0.92, 0.88, 1.0, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.75;

uniform float distortion_strength : hint_range(0.0, 0.1) = 0.01;
uniform float distortion_scale : hint_range(1.0, 30.0) = 5.0;
uniform float drift_speed : hint_range(0.0, 4.0) = 4.0;

uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.5;
uniform float shimmer_density : hint_range(1.0, 40.0) = 3.0;

uniform float edge_softness : hint_range(0.01, 1.0) = 1.0;
uniform float center_fade : hint_range(0.0, 1.0) = 0.1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float radius = length(centered_uv) * 2.0;
	float radial_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, radius);

	vec2 drift_a = vec2(TIME * drift_speed * 0.14, -TIME * drift_speed * 0.09);
	vec2 drift_b = vec2(-TIME * drift_speed * 0.08, TIME * drift_speed * 0.12);
	float field_a = noise(UV * distortion_scale + drift_a);
	float field_b = noise(UV * (distortion_scale * 1.7) + drift_b);

	vec2 offset = vec2(field_a - 0.5, field_b - 0.5) * distortion_strength;
	vec2 sample_uv = clamp(UV + offset, vec2(0.0), vec2(1.0));
	vec4 tex = texture(TEXTURE, sample_uv);

	float shimmer = sin((UV.y + field_a * 0.35 + TIME * 0.22) * shimmer_density * 6.28318) * 0.5 + 0.5;
	shimmer = mix(1.0 - shimmer_strength, 1.0, shimmer);

	float veil = mix(1.0 - center_fade, 1.0, radial_mask);
	float alpha = tex.a * radial_mask * veil * alpha_strength * shimmer;
	vec3 color = haze_tint.rgb * (0.85 + field_b * 0.25);

	COLOR = vec4(color * alpha, alpha);
}
