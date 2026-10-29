shader_type canvas_item;
// Average luminance of the ND-OS picture in linear light, drawn into a 1×1 HDR viewport. The front
// frame divides it by the idle Desktop's average to scale the screen light layer.

#include "res://game/shaders/color.gdshaderinc"

uniform sampler2D picture : filter_nearest, repeat_disable;
// Samples across and down, at the centres of an even grid.
uniform ivec2 grid = ivec2(80, 60);

void fragment() {
	float sum = 0.0;
	for (int y = 0; y < grid.y; y++) {
		for (int x = 0; x < grid.x; x++) {
			vec2 uv = (vec2(float(x), float(y)) + 0.5) / vec2(grid);
			sum += luminance(srgb_to_linear(texture(picture, uv).rgb));
		}
	}
	COLOR = vec4(vec3(sum / float(grid.x * grid.y)), 1.0);
}
