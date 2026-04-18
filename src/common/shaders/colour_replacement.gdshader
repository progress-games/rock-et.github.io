shader_type canvas_item;

uniform vec4 original_colors[4]: source_color; // Up to 8 original colors
uniform vec4 replacement_colors[4]: source_color; // Matching replacement colors
uniform float threshold : hint_range(0.0, 1.0) = 0.01; // How exact the match needs to be

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    for (int i = 0; i < 4; i++) {
        if (distance(col.rgb, original_colors[i].rgb) < threshold) {
            // Replace the color and preserve original alpha
			if (replacement_colors[i].a != 1.) {
				col.rgba = replacement_colors[i].rgba;
			} else {
				col.rgb = replacement_colors[i].rgb;
			}
            break;
        }
    }

    COLOR = col;
}
