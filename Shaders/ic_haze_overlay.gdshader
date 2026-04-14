shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform vec4 haze_tint : source_color = vec4(0.66, 0.9, 1.0, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.12;

uniform float distortion_strength : hint_range(0.0, 0.08) = 0.08;
uniform float distortion_scale : hint_range(1.0, 40.0) = 40.0;
uniform float drift_speed : hint_range(0.0, 4.0) = 0.65;
uniform float black_reject_threshold : hint_range(0.0, 0.5) = 0.50;
uniform float black_reject_softness : hint_range(0.001, 0.5) = 0.5;

uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.08;
uniform float shimmer_density : hint_range(1.0, 40.0) = 1.0;
uniform float edge_softness : hint_range(0.01, 1.0) = 0.01;
uniform float edge_boost : hint_range(0.0, 1.0) = 0.18;

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
	vec4 mask_tex = texture(TEXTURE, UV);
	vec2 centered_uv = UV - vec2(0.5);
	float radius = length(centered_uv) * 2.0;
	float radial_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, radius);

	vec2 drift_a = vec2(TIME * drift_speed * 0.18, -TIME * drift_speed * 0.11);
	vec2 drift_b = vec2(-TIME * drift_speed * 0.09, TIME * drift_speed * 0.15);
	float field_a = noise(UV * distortion_scale + drift_a);
	float field_b = noise(UV * (distortion_scale * 1.8) + drift_b);

	vec2 offset = vec2(field_a - 0.5, field_b - 0.5) * distortion_strength * radial_mask;
	vec2 screen_uv = SCREEN_UV;
	vec4 base = textureLod(screen_texture, screen_uv, 0.0);
	vec4 warped = textureLod(screen_texture, screen_uv + offset, 0.0);

	float base_luma = dot(base.rgb, vec3(0.2126, 0.7152, 0.0722));
	float warped_luma = dot(warped.rgb, vec3(0.2126, 0.7152, 0.0722));
	float visible_factor = smoothstep(
		black_reject_threshold,
		black_reject_threshold + black_reject_softness,
		max(base_luma, warped_luma)
	);

	float shimmer = sin((UV.y + field_a * 0.32 + TIME * 0.2) * shimmer_density * 6.28318) * 0.5 + 0.5;
	shimmer = mix(1.0 - shimmer_strength, 1.0, shimmer);

	float edge = smoothstep(0.62, 1.0, radius) * (1.0 - smoothstep(1.0, 1.08, radius));
	float tint_mix = (alpha_strength + edge * edge_boost) * radial_mask * mask_tex.a * shimmer * visible_factor;
	vec3 refracted = mix(base.rgb, warped.rgb, visible_factor);
	vec3 tinted = refracted + haze_tint.rgb * tint_mix * 0.35;
	float alpha = radial_mask * mask_tex.a;

	COLOR = vec4(tinted * alpha, alpha);
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
