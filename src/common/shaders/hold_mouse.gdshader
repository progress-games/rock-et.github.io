shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0); // Progress from 0 to 1
uniform float radius = 0.5;
uniform float inner = 0.;
uniform vec2 centre = vec2(0.5, 0.5); // Normalized UV center

void fragment() {
	vec2 dir = UV - centre;
	float dist = length(dir);

	float angle = atan(dir.y, dir.x); // -PI to PI
	if (angle < 0.0) angle += 2.*PI; // Convert to 0 to TAU (2π)
	
	if (angle <= progress * 6.2831853 && dist <= radius && dist >= inner) {
		COLOR.a = 1.0;
	} else {
		COLOR.a = 0.0;
	}
}
