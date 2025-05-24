shader_type canvas_item;

void fragment() {
    COLOR = texture(TEXTURE, UV);
	if (COLOR.a < 1. && COLOR.a > 0.) {
		COLOR = vec4(0., 0., 0., 1.);
	}
}