shader_type canvas_item;

uniform float progress: hint_range(0, 1);

uniform vec4[4] colours: source_color;
uniform float[4] thresholds;

void fragment() {
	vec4 texture_colour = texture(TEXTURE, UV);
	
	int idx = 3;
	for (int i = 3; i >= 0; i--) {
		if (progress > thresholds[i]) {
			idx = i;
			break;
		}
	}
	
	if (UV.x > progress) {
		COLOR = vec4(.0, .0, .0, .2);
	} else {
		COLOR = colours[idx];
	}
}
