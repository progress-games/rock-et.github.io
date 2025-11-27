shader_type canvas_item;

uniform vec4 colour: source_color = vec4(0., 0., 0., 1.);

void fragment() {
    COLOR = texture(TEXTURE, UV);
	if (COLOR.a < 1. && COLOR.a > 0.) {
		COLOR = colour;
	}
}