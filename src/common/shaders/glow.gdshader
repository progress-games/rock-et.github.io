shader_type canvas_item;

uniform float glow_size = 4.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float alpha = tex.a;

    // sample around for fake blur
    for (float x = -glow_size; x <= glow_size; x++) {
        for (float y = -glow_size; y <= glow_size; y++) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            alpha = max(alpha, texture(TEXTURE, UV + offset).a * 0.2);
        }
    }

    vec4 glow = glow_color * alpha;
    COLOR = tex + glow;
}