shader_type canvas_item;

uniform int color_levels : hint_range(2, 32) = 16;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

float dither_matrix(vec2 pos) {
    // 4x4 Bayer matrix for ordered dithering
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    int index = x + y * 4;
    float bayer[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    return bayer[index] / 16.0 - 0.5;
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    // Apply ordered dithering before quantization
    vec2 pixel_pos = UV / TEXTURE_PIXEL_SIZE;
    float dither = dither_matrix(pixel_pos) * dither_strength;

    float levels = float(color_levels);
    col.r = floor((col.r + dither / levels) * levels) / levels;
    col.g = floor((col.g + dither / levels) * levels) / levels;
    col.b = floor((col.b + dither / levels) * levels) / levels;

    COLOR = col;
}