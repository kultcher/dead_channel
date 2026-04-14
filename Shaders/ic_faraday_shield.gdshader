shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 shield_tint : source_color = vec4(0.80, 0.0, 1.0, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.62;

uniform float rim_width : hint_range(0.01, 0.5) = 0.26;
uniform float rim_softness : hint_range(0.001, 0.5) = 0.22;
uniform float center_fade : hint_range(0.0, 1.0) = 0.78;

uniform float pulse_speed : hint_range(0.0, 8.0) = 2.8;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.38;

uniform float swirl_scale : hint_range(1.0, 40.0) = 30.0;
uniform float swirl_strength : hint_range(0.0, 1.0) = 0.58;
uniform float scanline_density : hint_range(0.0, 120.0) = 20.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.56;

uniform float particle_density : hint_range(1.0, 120.0) = 22.0;
uniform float particle_speed : hint_range(0.0, 8.0) = 1.3;
uniform float particle_size : hint_range(0.001, 0.2) = 0.2;
uniform float particle_strength : hint_range(0.0, 1.0) = 0.36;

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
	vec4 tex = texture(TEXTURE, UV);

	vec2 centered_uv = UV - vec2(0.5);
	float radius = length(centered_uv) * 2.0;
	float radial_mask = 1.0 - smoothstep(1.0, 1.0 + rim_softness, radius);

	float rim_outer = 1.0 - smoothstep(1.0 - rim_width, 1.0, radius);
	float rim_inner = 1.0 - smoothstep(max(0.0, 1.0 - rim_width - rim_softness), 1.0 - rim_width, radius);
	float rim = clamp(rim_outer - rim_inner, 0.0, 1.0);

	float t = TIME * pulse_speed;
	float pulse = 0.86 + sin(t + radius * 8.0) * pulse_strength;

	float swirl = noise(UV * swirl_scale + vec2(TIME * 0.35, -TIME * 0.22));
	swirl = mix(0.82, 1.12, swirl) * swirl_strength + (1.0 - swirl_strength);

	float scanlines = sin((UV.y + TIME * 0.18) * scanline_density * 6.28318) * 0.5 + 0.5;
	scanlines = mix(1.0, scanlines, scanline_strength);

	vec2 particle_uv = vec2(UV.x, fract(UV.y + TIME * particle_speed));
	vec2 particle_cell = floor(particle_uv * particle_density);
	vec2 particle_local = fract(particle_uv * particle_density) - 0.5;
	float particle_pick = step(0.93, hash(particle_cell));
	float particle = 1.0 - smoothstep(particle_size, particle_size + 0.02, length(particle_local));
	particle *= particle_pick * particle_strength;

	float interior = radial_mask * (1.0 - center_fade);
	float shield = (interior + rim * 0.95) * pulse * swirl * scanlines;
	shield += particle * radial_mask;
	shield = clamp(shield, 0.0, 1.0);

	vec3 color = shield_tint.rgb * (0.6 + rim * 0.55 + particle * 1.8);
	float alpha = tex.a * shield * alpha_strength;

	COLOR = vec4(color * alpha, alpha);
}
