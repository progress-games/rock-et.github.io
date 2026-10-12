shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true; // only useful when inside is false
uniform vec4 modulate : source_color = vec4(1.0);
uniform float progress : hint_range(0.0, 1.0) = 1.;

uniform vec4 original_colors[4]: source_color; // Up to 8 original colors
uniform vec4 replacement_colors[4]: source_color; // Matching replacement colors
uniform float threshold : hint_range(0.0, 1.0) = 0.01; // How exact the match needs to be


varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
	
	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(width); i <= ceil(width); i++) {
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;

		if (pattern == 0) {
			offset = width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = width;
		}

		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);

			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a * modulate.a <= 0.0) == inside) {
				return true;
			}
		}
	}

	return false;
}

void fragment() {
	vec2 uv = UV;

	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));

		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv) * vertex_color;
		}
	} else {
		COLOR = texture(TEXTURE, uv) * vertex_color;
	}
	
	vec4 colour = texture(TEXTURE, UV);
	
	for (int i = 0; i < 4; i++) {
		if (distance(COLOR.rgb, original_colors[i].rgb) < threshold) {
			if (replacement_colors[i].a != 1.) {
				COLOR.rgba = replacement_colors[i].rgba;
			} else {
				COLOR.rgb = replacement_colors[i].rgb;
			}
			break;
		}
	}

	if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.rgb = inside ? mix(COLOR.rgb, color.rgb, color.a) : color.rgb;
		COLOR.a += (1.0 - COLOR.a) * color.a;
	}
	
	if (progress < 1. && (1. - uv.y) >= progress) {
		COLOR.a = 0.;
	}
}