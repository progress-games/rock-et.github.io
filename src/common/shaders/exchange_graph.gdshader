shader_type canvas_item;

const int BARS = 100;

uniform float values[BARS];

void fragment() {
	int position = int(UV.x * float(BARS));
	if (values[position] < 1.0 - UV.y) {
		COLOR.a = 0.;
	}
}