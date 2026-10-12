shader_type canvas_item;

uniform vec2[3] bites;
uniform float bite_size;


void fragment() {
	for (int i = 0; i < 3; i++) {
		if (distance(bites[i], UV) <= bite_size) {
			COLOR.a = 0.;
		}
	}
}
