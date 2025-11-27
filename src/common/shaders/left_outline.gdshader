shader_type canvas_item;

uniform vec4 outline_colour : source_color = vec4(1.0, 0.0, 0.0, 1.0); // red outline
uniform vec4 font_colour: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness = 1.0;

void fragment() {
    vec4 tex_colour = texture(TEXTURE, UV);

    // Sample the pixel to the right
    vec2 offset = UV + vec2(outline_thickness * TEXTURE_PIXEL_SIZE.x, 0.0);
    vec4 right_colour = texture(TEXTURE, offset);

    // if current pixel is opaque but right neighbour has something
    if (tex_colour.a == 0. && right_colour.a > 0.) {
        COLOR = outline_colour;
    } else if (tex_colour.a > 0.) {
        COLOR = font_colour;
    }
}
