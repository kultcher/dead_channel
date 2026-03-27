shader_type canvas_item;

uniform float speed: hint_range(0.0, 20.0, 0.01) = 5.0;
uniform float blur_x: hint_range(0.0, 20.0, 0.01) = 5.0;
uniform float blur_y: hint_range(0.0, 20.0, 0.01) = 5.0;
uniform float density: hint_range(1.0, 20.0, 0.01) = 20.0;
uniform float intensity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float tear_strength: hint_range(0.0, 0.25, 0.001) = 0.045;
uniform float noise_strength: hint_range(0.0, 0.5, 0.001) = 0.08;
uniform float tear_density: hint_range(1.0, 40.0, 0.1) = 11.0;

float hash11(float n) {
	return fract(sin(n) * 43758.5453);
}

float hash12(vec2 x) {
	return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 centered_uv = UV - 0.5;
	float time = floor(TIME * speed);
	float shift = hash12(floor(centered_uv * density) * time);
	float disp = pow(shift, 11.0);
	float power = hash11(time) * 0.2 - 0.1;
	vec2 offset = vec2(disp + vec2(blur_x, blur_y) * power);
	offset *= hash11(time + power) * 0.05 * intensity;

	float tear_row = floor(uv.y * tear_density + time * 0.35);
	float tear_gate = step(0.72, hash11(tear_row + time * 1.7));
	float tear_offset = (hash11(tear_row * 4.17 + time) * 2.0 - 1.0) * tear_strength * intensity * tear_gate;
	vec2 tear_uv = uv + vec2(tear_offset, 0.0);

	vec3 source = texture(TEXTURE, tear_uv).rgb;
	vec3 glitched = vec3(
		source.r,
		texture(TEXTURE, tear_uv + offset).g,
		texture(TEXTURE, tear_uv - offset).b
	);
	float noise = (hash12(floor(uv * vec2(320.0, 180.0)) + vec2(time, time * 0.37)) * 2.0 - 1.0);
	vec3 noisy = glitched + vec3(noise) * noise_strength * intensity;
	vec3 color = mix(source, glitched, intensity);
	color = mix(color, noisy, min(1.0, intensity * 0.85));
	COLOR = vec4(color, 1.0);
}
