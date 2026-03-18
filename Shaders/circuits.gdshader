shader_type canvas_item;

uniform vec4 base_tint : source_color = vec4(0.20, 0.85, 1.00, 1.0);
uniform vec4 hot_tint  : source_color = vec4(0.85, 1.00, 1.00, 1.0);

uniform float base_glow : hint_range(0.0, 4.0) = 0.65;
uniform float pulse_strength : hint_range(0.0, 4.0) = 0.25;
uniform float shimmer_strength : hint_range(0.0, 2.0) = 0.35;
uniform float alpha_boost : hint_range(0.0, 3.0) = 1.0;

uniform float band_scale_1 = 9.0;
uniform float band_scale_2 = 15.0;
uniform float speed_1 = 0.45;
uniform float speed_2 = -0.32;
uniform float surge_speed = 1.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Use the visible trace brightness as the mask.
	float trace = tex.a * dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	trace = smoothstep(0.08, 0.9, trace);

	float t = TIME;

	// Two large moving bands in different directions.
	float band1 = sin((UV.x + UV.y * 0.65) * band_scale_1 - t * speed_1 * 6.28318);
	float band2 = sin((UV.x * -0.8 + UV.y) * band_scale_2 - t * speed_2 * 6.28318);

	band1 = smoothstep(0.35, 1.0, band1);
	band2 = smoothstep(0.55, 1.0, band2);

	// Small local variation so the whole board does not pulse uniformly.
	vec2 cell = floor(UV * vec2(24.0, 14.0));
	float local_offset = hash(cell);
	float local_flicker = sin(t * (2.0 + local_offset * 3.0) + local_offset * 10.0) * 0.5 + 0.5;
	local_flicker = smoothstep(0.65, 1.0, local_flicker);

	// Rare stronger sweep.
	float surge = sin((UV.x * 0.35 + UV.y * 1.15) * 6.0 - t * surge_speed * 6.28318);
	surge = smoothstep(0.82, 1.0, surge);

	// Fine shimmer to keep thin lines alive.
	float shimmer = sin((UV.x * 140.0 + UV.y * 90.0) + t * 7.0 + local_offset * 20.0) * 0.5 + 0.5;
	shimmer = pow(shimmer, 6.0) * shimmer_strength;

	float energy = 0.0;
	energy += band1 * 0.55;
	energy += band2 * 0.45;
	energy += local_flicker * 0.35;
	energy += surge * 0.8;
	energy += shimmer;

	energy *= trace;

	vec3 color = mix(base_tint.rgb, hot_tint.rgb, clamp(energy * 0.85, 0.0, 1.0));
	color *= trace * (base_glow + energy * pulse_strength);

	float alpha = tex.a * trace * (alpha_boost + energy * 0.8);

	COLOR = vec4(color, alpha);
}
