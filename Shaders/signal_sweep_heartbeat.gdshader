shader_type canvas_item;
render_mode unshaded;

// Shared sweep position in screen space, normalized across the viewport.
uniform float sweep_position : hint_range(0.0, 1.0) = 0.5;

// Width/shape of the sweep band.
uniform float sweep_width : hint_range(0.001, 0.25) = 0.045;
uniform float sweep_softness : hint_range(0.001, 0.25) = 0.08;
uniform float leading_edge_bias : hint_range(0.1, 4.0) = 1.6;
uniform float trailing_falloff : hint_range(0.1, 4.0) = 1.1;

// Visual response.
uniform float brightness_boost : hint_range(0.0, 2.0) = 0.45;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.65;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.55;
uniform vec4 glow_tint : source_color = vec4(0.72, 0.96, 1.0, 1.0);

// Tiny bit of breakup so it feels less like a perfect gradient wipe.
uniform float breakup_strength : hint_range(0.0, 1.0) = 0.18;
uniform float breakup_scale : hint_range(1.0, 80.0) = 18.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec4 base = COLOR;

	float dx = SCREEN_UV.x - sweep_position;
	float dist = abs(dx);

	float core = 1.0 - smoothstep(sweep_width, sweep_width + sweep_softness, dist);

	float lead = 1.0 - smoothstep(0.0, sweep_width + sweep_softness, max(dx, 0.0));
	lead = pow(max(lead, 0.0), leading_edge_bias);

	float trail = 1.0 - smoothstep(0.0, (sweep_width + sweep_softness) * 1.4, max(-dx, 0.0));
	trail = pow(max(trail, 0.0), trailing_falloff);

	float band = max(core, lead * trail);

	float breakup = hash(floor(SCREEN_UV * breakup_scale));
	breakup = mix(1.0, 0.75 + breakup * 0.5, breakup_strength);
	band *= breakup;

	float center_profile = 1.0 - smoothstep(0.0, sweep_width + sweep_softness, dist);
	float rim = smoothstep(0.35, 1.0, center_profile) - smoothstep(0.72, 1.0, center_profile);
	rim = max(rim, 0.0) * rim_strength;

	vec3 lit = base.rgb * (1.0 + band * brightness_boost);
	lit += glow_tint.rgb * (band * glow_strength + rim * 0.45);

	COLOR = vec4(lit, base.a);
}
