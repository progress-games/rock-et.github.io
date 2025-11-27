shader_type canvas_item;

uniform float progress: hint_range(0, 1);

void fragment() {
	if (UV.y < (1. - progress)) {
		COLOR = vec4(0., 0., 0., 0.);
	}
}