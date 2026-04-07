// Adapted from the original movAX13h "I/O" style shader.
// Tuned for a single, subtle horizontal data lane that can sit behind the timeline.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 stream_color : source_color = vec4(0.12, 0.72, 0.95, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.78, 0.96, 1.0, 1.0);

uniform float overall_alpha : hint_range(0.0, 1.0) = 0.18;
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.14;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.18;
uniform float speed : hint_range(0.0, 4.0) = 0.55;
uniform float lane_fill : hint_range(0.0, 1.0) = 0.08;
uniform float center_bias : hint_range(0.0, 1.0) = 0.2;

uniform float lane_center : hint_range(0.0, 1.0) = 0.5;
uniform float lane_height : hint_range(0.01, 1.0) = 0.18;
uniform float lane_softness : hint_range(0.001, 0.5) = 0.12;
uniform float lane_jitter : hint_range(0.0, 1.0) = 0.08;
uniform float vertical_center_bias : hint_range(0.0, 1.0) = 0.25;

uniform int num_blocks = 42;
uniform vec2 block_size = vec2(0.175, 0.118);
uniform float edge_softness : hint_range(0.001, 0.1) = 0.014;
uniform float trail_strength : hint_range(0.0, 1.0) = 0.28;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.025;

float rand(float x) {
	return fract(sin(x) * 4358.5453123);
}

float rand2(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5357);
}

float box(vec2 p, vec2 b, float r) {
	return length(max(abs(p) - b, 0.0)) - r;
}

float remap_center_bias(float t, float bias) {
	float centered = t * 2.0 - 1.0;
	float curved = sign(centered) * pow(abs(centered), 1.0 + bias * 2.5);
	return curved * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = UV;
	float lane_distance = abs(uv.y - lane_center);
	float lane_mask = 1.0 - smoothstep(lane_height, lane_height + lane_softness, lane_distance);

	float edge_fade = smoothstep(0.0, 0.08, uv.x) * smoothstep(0.0, 0.08, 1.0 - uv.x);
	float pulse = 0.82 + sin(TIME * 1.35) * pulse_strength;

	float lane_core = pow(lane_mask, 1.8);
	vec3 color = stream_color.rgb * ambient_strength * lane_mask * edge_fade * pulse;
	float alpha = overall_alpha * lane_fill * lane_core * edge_fade;

	for (int i = 0; i < 64; i++) {
		if (i >= num_blocks) {
			break;
		}
		float fi = float(i);
		float z = mix(0.35, 1.0, rand(fi * 1.173));
		float vertical_spread = remap_center_bias(rand(fi * 2.417), vertical_center_bias) - 0.5;
		float lane_offset = vertical_spread * lane_jitter;
		float tick_time = TIME * speed * z + fi * 0.137;
		float travel = fract(tick_time + rand(fi * 4.913));
		float spread_travel = remap_center_bias(travel, center_bias);

		vec2 pos = vec2(1.12 - spread_travel * 1.24, lane_center + lane_offset);
		vec2 scaled_size = block_size * vec2(
			0.75 + z * 1.35,
			0.85 + rand(fi * 7.731) * 1.45
		);

		float outer_box = box(uv - pos, scaled_size, edge_softness);
		float inner_box = box(uv - pos, scaled_size - vec2(edge_softness * 2.2, edge_softness * 2.2), edge_softness * 0.5);
		float block = smoothstep(0.012, 0.0, outer_box) * z;
		float outline = smoothstep(0.012, 0.0, outer_box) - smoothstep(0.012, 0.0, inner_box);
		float shine = smoothstep(0.03, -0.002, outer_box) * z * pulse;

		vec2 trail_pos = uv - vec2(pos.x + scaled_size.x * (1.15 + z * 1.7), pos.y);
		float trail = smoothstep(
			0.018,
			0.0,
			box(trail_pos, vec2(scaled_size.x * 1.65, scaled_size.y * 0.34), edge_softness * 0.7)
		);
		trail *= trail_strength * z * (1.0 - spread_travel);

		float energy = (block * 0.34 + outline * 0.95 + shine * 0.35 + trail * 0.55) * lane_mask * edge_fade;
		vec3 block_color = mix(stream_color.rgb, highlight_color.rgb, clamp(outline * 1.4 + shine * 0.4, 0.0, 1.0));
		color += block_color * energy;
		alpha += (block * 0.25 + outline * 0.9 + shine * 0.22 + trail * 0.4) * overall_alpha * lane_mask * edge_fade;
	}

	float grain = (rand2(uv * vec2(320.0, 90.0) + TIME * 0.2) - 0.5) * grain_strength;
	color += grain * lane_mask * 0.35;

	COLOR = vec4(color, clamp(alpha, 0.0, overall_alpha));
}
