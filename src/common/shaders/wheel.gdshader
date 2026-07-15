shader_type canvas_item;

const float RADIUS = 0.48;
const vec2 CENTRE = vec2(0.5, 0.5);
const float OUTLINE_WIDTH = 0.02;

uniform vec4 outline: source_color;

// portion floats
uniform float portions[10];

//portion colours
uniform vec4 portion_colours[10]: source_color;

void fragment() {
	
	if (distance(UV, CENTRE) < RADIUS + OUTLINE_WIDTH && distance(UV, CENTRE) > RADIUS) {
		COLOR = outline;
	} else if (distance(UV, CENTRE) > RADIUS + OUTLINE_WIDTH) {
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
