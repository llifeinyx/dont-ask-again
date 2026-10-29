shader_type canvas_item;
// The part of the HDR front frame the player sees, in display colour.

#include "res://game/shaders/agx_punchy.gdshaderinc"

uniform sampler2D frame : filter_linear, repeat_disable;
// Visible part of the frame: top-left corner and size, in frame UV.
uniform vec4 view_rect = vec4(0.0, 0.0, 1.0, 1.0);
// Stops, like Blender's exposure.
uniform float exposure = 0.0;

void fragment() {
	vec3 linear = texture(frame, view_rect.xy + UV * view_rect.zw).rgb;
	COLOR = vec4(agx_punchy(linear * exp2(exposure)), 1.0);
}
