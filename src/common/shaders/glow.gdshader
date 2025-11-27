shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // yellow glow
uniform float intensity = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Add emissive glow by boosting color
    COLOR = tex_color * glow_color * intensity;
}
