shader_type canvas_item;

uniform float degradation : hint_range(0.0, 1.0) = 0.3;
uniform float scan_line_opacity : hint_range(0.0, 1.00) = 0.04;
uniform sampler2D noise_tex;  // feed in a tileable noise texture

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    // Subtle scan lines — this display tech wouldn't have them,
    // but they appear as the upscaler deteriorates
    float scan = sin(UV.y * TEXTURE_PIXEL_SIZE.y * 800.0) * 0.5 + 0.5;  // Adjust 800.0 based on resolution
    col.rgb -= scan * scan_line_opacity * degradation;

    // Brightness inconsistency — some regions dimmer than others
    float noise_val = texture(noise_tex, UV * 0.5 + vec2(TIME * 0.01, 0.0)).r;
    float brightness_variation = mix(1.0, mix(0.85, 1.0, noise_val), degradation);
    col.rgb *= brightness_variation;

    // Slight desaturation in degraded areas
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(col.rgb, vec3(luma), degradation * 0.3 * (1.0 - noise_val));

    COLOR = col;
}