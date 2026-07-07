shader_type canvas_item;

uniform float break_width = 10.; // how many sectors on this line
uniform float break_point = 2.;

void fragment() {
	float x = UV.x * break_width;
	
	if (x >= break_point && x <= (break_point + 0.96)) {
		COLOR.a = 0.;
	}
}
