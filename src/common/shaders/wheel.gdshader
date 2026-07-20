shader_type canvas_item;

const float RADIUS = 0.5;
const vec2 CENTRE = vec2(0.5, 0.5);

uniform float outline_width: hint_range(0.0, 1.0, 0.01);
uniform vec4 outline: source_color;

// portion floats
uniform float portions[10];

//portion colours
uniform vec4 portion_colours[10]: source_color;

void fragment() {
	
	if (distance(UV, CENTRE) < RADIUS && distance(UV, CENTRE) > RADIUS - outline_width) {
		COLOR = outline;
	} else if (distance(UV, CENTRE) > RADIUS) {
		COLOR.a = 0.0;
	} else {
		float angle = atan(UV.y - CENTRE.y, UV.x - CENTRE.x) + PI;
		float portion = angle / (2. * PI);
		float accum = 0.;
		for (int i = 0; i < 10; i++) {
			accum += portions[i];
			if (portion < accum) {
				COLOR = portion_colours[i];
				break;
			}
		}
	}
}
