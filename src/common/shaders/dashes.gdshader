shader_type canvas_item;

uniform float border_width : hint_range(0.001, 0.5) = 0.05;
uniform int dash_count : hint_range(1, 128) = 16;
uniform float gap_ratio : hint_range(0.0, 0.95) = 0.3;

uniform float rotation : hint_range(-3.14, 3.14) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 1.0;

uniform vec4 dash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float radius = length(uv);

    if (radius > 1.0) {
        discard;
    }

    float inner_radius = 1.0 - border_width;

    // Calculate angle once
    float angle = atan(uv.y, uv.x);
    if (angle < 0.0) {
        angle += TAU;
    }

    // Normalize angle to 0 → 1
    float angle_ratio = angle / TAU;

    if (radius < inner_radius) {
        // --- INNER PROGRESS FILL ---
        if (angle_ratio <= progress) {
            COLOR = fill_color;
        } else {
            discard;
        }
    } else {
        // --- DASHED BORDER (unaffected by progress) ---
        float segment = TAU / float(dash_count);
        float local_angle = mod(angle + rotation, segment);
        float dash_length = segment * (1.0 - gap_ratio);

        if (local_angle <= dash_length) {
            COLOR = dash_color;
        } else {
            discard;
        }
    }
}
