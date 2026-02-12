shader_type canvas_item;
render_mode unshaded;

uniform float columns = 24.0;
uniform float rows = 22.0;
uniform float speed = 0.7;
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float layer_seed = 1.0;
uniform vec4 rain_color : source_color = vec4(0.0, 1.0, 0.25, 0.2);
uniform float glyph_refresh_rate = 7.0;
uniform float trail_decay = 8.0;
uniform float brightness = 1.875;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

int glyph_row_mask(int glyph, int row) {
	// 4x5 bitmap masks for 0-9 and A-F.
	if (glyph == 0) {
		if (row == 0) { return 15; }
		if (row == 1) { return 9; }
		if (row == 2) { return 9; }
		if (row == 3) { return 9; }
		return 15;
	}
	if (glyph == 1) {
		if (row == 0) { return 2; }
		if (row == 1) { return 6; }
		if (row == 2) { return 2; }
		if (row == 3) { return 2; }
		return 7;
	}
	if (glyph == 2) {
		if (row == 0) { return 15; }
		if (row == 1) { return 1; }
		if (row == 2) { return 15; }
		if (row == 3) { return 8; }
		return 15;
	}
	if (glyph == 3) {
		if (row == 0) { return 15; }
		if (row == 1) { return 1; }
		if (row == 2) { return 7; }
		if (row == 3) { return 1; }
		return 15;
	}
	if (glyph == 4) {
		if (row == 0) { return 9; }
		if (row == 1) { return 9; }
		if (row == 2) { return 15; }
		if (row == 3) { return 1; }
		return 1;
	}
	if (glyph == 5) {
		if (row == 0) { return 15; }
		if (row == 1) { return 8; }
		if (row == 2) { return 15; }
		if (row == 3) { return 1; }
		return 15;
	}
	if (glyph == 6) {
		if (row == 0) { return 15; }
		if (row == 1) { return 8; }
		if (row == 2) { return 15; }
		if (row == 3) { return 9; }
		return 15;
	}
	if (glyph == 7) {
		if (row == 0) { return 15; }
		if (row == 1) { return 1; }
		if (row == 2) { return 2; }
		if (row == 3) { return 4; }
		return 4;
	}
	if (glyph == 8) {
		if (row == 0) { return 15; }
		if (row == 1) { return 9; }
		if (row == 2) { return 15; }
		if (row == 3) { return 9; }
		return 15;
	}
	if (glyph == 9) {
		if (row == 0) { return 15; }
		if (row == 1) { return 9; }
		if (row == 2) { return 15; }
		if (row == 3) { return 1; }
		return 15;
	}
	if (glyph == 10) {
		if (row == 0) { return 15; }
		if (row == 1) { return 9; }
		if (row == 2) { return 15; }
		if (row == 3) { return 9; }
		return 9;
	}
	if (glyph == 11) {
		if (row == 0) { return 14; }
		if (row == 1) { return 9; }
		if (row == 2) { return 14; }
		if (row == 3) { return 9; }
		return 14;
	}
	if (glyph == 12) {
		if (row == 0) { return 15; }
		if (row == 1) { return 8; }
		if (row == 2) { return 8; }
		if (row == 3) { return 8; }
		return 15;
	}
	if (glyph == 13) {
		if (row == 0) { return 14; }
		if (row == 1) { return 9; }
		if (row == 2) { return 9; }
		if (row == 3) { return 9; }
		return 14;
	}
	if (glyph == 14) {
		if (row == 0) { return 15; }
		if (row == 1) { return 8; }
		if (row == 2) { return 14; }
		if (row == 3) { return 8; }
		return 15;
	}
	// F
	if (row == 0) { return 15; }
	if (row == 1) { return 8; }
	if (row == 2) { return 14; }
	if (row == 3) { return 8; }
	return 8;
}

float bit_from_mask(int mask, int x) {
	// x in [0..3], left to right.
	float denom = pow(2.0, float(3 - x));
	float shifted = floor(float(mask) / denom);
	return mod(shifted, 2.0);
}

float glyph_alpha(int glyph, vec2 cell_uv) {
	// Leave a margin so glyphs don't touch cell bounds.
	// Narrower width + taller height prevents square-looking glyphs.
	if (cell_uv.x < 0.19 || cell_uv.x > 0.81 || cell_uv.y < 0.03 || cell_uv.y > 0.97) {
		return 0.0;
	}

	float sx = (cell_uv.x - 0.19) / 0.62;
	float sy = (cell_uv.y - 0.03) / 0.94;
	int gx = int(clamp(floor(sx * 4.0), 0.0, 3.0));
	int gy = int(clamp(floor(sy * 5.0), 0.0, 4.0));

	int row_mask = glyph_row_mask(glyph, gy);
	return bit_from_mask(row_mask, gx);
}

void fragment() {
	vec2 uv = UV;

	float column_id = floor(uv.x * columns);
	float col_rand = hash21(vec2(column_id, layer_seed));
	float fall_speed = speed * mix(0.6, 1.45, col_rand);

	float head = fract(TIME * fall_speed + col_rand);
	float trail = head - uv.y;
	if (trail < 0.0) {
		trail += 1.0;
	}

	float row_id = floor((uv.y + TIME * fall_speed) * rows);
	float glyph_noise = hash21(vec2(column_id * 1.71 + layer_seed, row_id + layer_seed * 3.0));
	float active = step(1.0 - density, glyph_noise);

	vec2 glyph_uv = fract(vec2(uv.x * columns, uv.y * rows));
	float tick = floor(TIME * glyph_refresh_rate);
	float glyph_pick = hash21(vec2(column_id * 9.17 + layer_seed * 2.0, row_id + tick + layer_seed * 13.0));
	int glyph_index = int(floor(glyph_pick * 16.0));
	float glyph_shape = glyph_alpha(glyph_index, glyph_uv);

	float tail_falloff = exp(-trail * max(trail_decay, 0.001)) * step(0.0, trail);
	float flicker = 0.8 + 0.2 * hash21(vec2(row_id + TIME * 2.0, column_id + layer_seed));
	float bottom_fade = 1.0 - uv.y * 0.45;
	float intensity = active * glyph_shape * tail_falloff * flicker * bottom_fade;

	COLOR = vec4(rain_color.rgb * intensity * brightness, rain_color.a * intensity);
}
