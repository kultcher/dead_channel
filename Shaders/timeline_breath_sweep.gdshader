shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// Shared sweep position in normalized screen space.
uniform float sweep_position : hint_range(0.0, 1.0) = 0.5;

// Band shape.
uniform float sweep_width : hint_range(0.001, 0.25) = 0.06;
uniform float sweep_softness : hint_range(0.001, 0.3) = 0.1;
uniform float vertical_influence : hint_range(0.0, 2.0) = 0.75;

// Distortion strength.
uniform float expand_strength_x : hint_range(0.0, 0.08) = 0.012;
uniform float expand_strength_y : hint_range(0.0, 0.08) = 0.004;
uniform float edge_falloff : hint_range(0.1, 4.0) = 1.6;

// Optional polish.
uniform float center_soften : hint_range(0.0, 1.0) = 0.2;
uniform float brightness_boost : hint_range(0.0, 1.0) = 0.04;
uniform float shimmer_strength : hint_range(0.0, 0.1) = 0.012;
uniform float shimmer_scale : hint_range(1.0, 120.0) = 28.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	float dx = screen_uv.x - sweep_position;
	float abs_dx = abs(dx);

	float band = 1.0 - smoothstep(sweep_width, sweep_width + sweep_softness, abs_dx);
	band = pow(max(band, 0.0), edge_falloff);

	float center_mask = 1.0 - smoothstep(0.0, sweep_width, abs_dx);
	band *= mix(1.0, 1.0 - center_mask * 0.5, center_soften);

	float local_y = UV.y * 2.0 - 1.0;
	float vertical_mask = 1.0 - smoothstep(1.0 / max(vertical_influence, 0.001), 1.0, abs(local_y));

	float signed_push = sign(dx);
	float x_offset = signed_push * expand_strength_x * band * vertical_mask;
	float y_offset = -local_y * expand_strength_y * band;

	vec2 distorted_uv = screen_uv + vec2(x_offset, y_offset * .25);
	vec4 col = textureLod(screen_texture, distorted_uv, 0.0);

	float shimmer = hash(floor(screen_uv * shimmer_scale) + vec2(TIME * 8.0, 0.0)) - 0.5;
	col.rgb += band * brightness_boost;
	col.rgb += shimmer * shimmer_strength * band;

	COLOR = col;
}
