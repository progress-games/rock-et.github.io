shader_type canvas_item;

uniform float progress: hint_range(0, 1) = 0.5;
uniform float frequency = 2.5;
uniform float amplitude = 0.1;
uniform float speed = 1.5;
uniform float line_width = 1.0;
uniform vec2 centre;
uniform float radius;

uniform vec4 outlineColour: source_color;
uniform vec4 backgroundColour : source_color;
uniform vec4 waveColour: source_color;
uniform vec4 lineColour: source_color;

float get_progress(float start, float end, float prg) {
	return start - (start - end) * prg;
}

vec4 _wave(vec2 uv, vec4 colour, float spd) {
	float sinus = sin((uv.x + TIME * spd) * frequency) * amplitude + cos((uv.x + TIME * spd) * frequency * 2.3) * amplitude;
	return colour * step(1.0 - sinus - get_progress(0.1, 0.9, progress), uv.y);
}

void fragment() {
	vec4 wave = _wave(UV, waveColour, speed);

	if (wave.a == 0.0) {
		wave = _wave(UV - vec2(100.0, 0.0), lineColour, speed * 0.5);
		COLOR = mix(backgroundColour, wave, wave.a);
	} else {
		COLOR = mix(backgroundColour, wave, wave.a);
	}

	if (distance(UV, centre) > radius &&  distance(UV, centre) < radius + line_width) {
		COLOR = outlineColour;
	} else if (distance (UV, centre) > radius) {
		COLOR.a = 0.0;
	}
}