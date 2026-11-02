shader_type canvas_item;
// The front frame in linear light: every Blender light layer times its strength, the picture on the glass,
// the mug over the room by its coverage. Draws into an HDR viewport;
// front_view.gdshader turns the result into display colour.

#include "res://game/shaders/agx_punchy_inverse.gdshaderinc"

uniform sampler2D lamp_layer : filter_nearest, repeat_disable;
uniform sampler2D screen_layer : filter_nearest, repeat_disable;
uniform sampler2D base_layer : filter_nearest, repeat_disable;
uniform sampler2D world_layer : filter_nearest, repeat_disable;
uniform sampler2D indicator_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_lamp_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_screen_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_base_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_world_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_indicator_layer : filter_nearest, repeat_disable;
uniform sampler2D mug_alpha : filter_nearest, repeat_disable;

// Lamp strength times its tint.
uniform vec3 lamp = vec3(1.0);
uniform float screen = 1.0;
uniform float base = 1.0;
uniform float world = 1.0;
uniform float indicator = 1.0;
// The mug layers' place in the frame: top-left corner and size, in frame UV.
uniform vec4 mug_rect;

// Glass UV pass: (u·m, v·m, m), the position on the glass times the glass coverage.
uniform sampler2D glass_uv : filter_nearest, repeat_disable;
// 0 keeps the dark glass Blender rendered; 1 shows the picture on it.
uniform float glass_on = 0.0;
// The tube's picture over the glass UV in display sRGB; it is turned back into light so AgX shows its own
// colours.
uniform sampler2D screen_picture : filter_linear, repeat_disable;
// The view's exposure in stops, undone for the picture.
uniform float exposure = 0.0;
// When average_on is 1, the screen layer follows the picture: its mean luminance (1×1 texture) over
// the idle Desktop's.
uniform float average_on = 0.0;
uniform sampler2D screen_average : filter_nearest, repeat_disable;
uniform float average_reference = 1.0;

void fragment() {
	float screen_light = screen;
	if (average_on > 0.5) {
		screen_light *= texture(screen_average, vec2(0.5)).r / average_reference;
	}
	vec3 light = texture(lamp_layer, UV).rgb * lamp
		+ texture(screen_layer, UV).rgb * screen_light
		+ texture(base_layer, UV).rgb * base
		+ texture(world_layer, UV).rgb * world
		+ texture(indicator_layer, UV).rgb * indicator;
	vec4 glass = texture(glass_uv, UV);
	if (glass_on > 0.5 && glass.b > 0.0) {
		vec2 tube_uv = glass.rg / glass.b;
		vec3 emission = agx_punchy_inverse(texture(screen_picture, tube_uv).rgb) / exp2(exposure);
		// The lit picture replaces the dark glass Blender rendered: the glass reflects nothing (design
		// doc §9.2), so the screen stays the most contrasty place in the frame.
		light = mix(light, emission, glass.b);
	}
	vec2 mug_uv = (UV - mug_rect.xy) / mug_rect.zw;
	if (all(greaterThanEqual(mug_uv, vec2(0.0))) && all(lessThan(mug_uv, vec2(1.0)))) {
		// The mug layers are premultiplied by their coverage.
		vec3 mug = texture(mug_lamp_layer, mug_uv).rgb * lamp
			+ texture(mug_screen_layer, mug_uv).rgb * screen_light
			+ texture(mug_base_layer, mug_uv).rgb * base
			+ texture(mug_world_layer, mug_uv).rgb * world
			+ texture(mug_indicator_layer, mug_uv).rgb * indicator;
		light = light * (1.0 - texture(mug_alpha, mug_uv).r) + mug;
	}
	COLOR = vec4(light, 1.0);
}
