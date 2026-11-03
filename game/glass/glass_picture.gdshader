shader_type canvas_item;
// What the tube shows, drawn over the glass (UV is a point of the glass UV pass, which follows the
// curved tube): ND-OS where GlassFit puts it, phosphor black around it, in display sRGB. The front
// frame turns the result into light.

#include "res://game/shaders/glass_fit.gdshaderinc"

uniform sampler2D picture : filter_linear, repeat_disable;
uniform vec3 phosphor_black : source_color;

void fragment() {
	vec2 ndos_uv = glass_to_ndos(UV);
	vec3 c = phosphor_black;
	if (all(greaterThanEqual(ndos_uv, vec2(0.0))) && all(lessThan(ndos_uv, vec2(1.0)))) {
		c = texture(picture, ndos_uv).rgb;
	}
	COLOR = vec4(c, 1.0);
}
