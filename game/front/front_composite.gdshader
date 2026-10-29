shader_type canvas_item;
// The front frame in linear light: every Blender light layer times its strength, the mug over the room
// by its coverage. Draws into an HDR viewport; front_view.gdshader turns the result into display colour.

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

void fragment() {
	vec3 light = texture(lamp_layer, UV).rgb * lamp
		+ texture(screen_layer, UV).rgb * screen
		+ texture(base_layer, UV).rgb * base
		+ texture(world_layer, UV).rgb * world
		+ texture(indicator_layer, UV).rgb * indicator;
	vec2 mug_uv = (UV - mug_rect.xy) / mug_rect.zw;
	if (all(greaterThanEqual(mug_uv, vec2(0.0))) && all(lessThan(mug_uv, vec2(1.0)))) {
		// The mug layers are premultiplied by their coverage.
		vec3 mug = texture(mug_lamp_layer, mug_uv).rgb * lamp
			+ texture(mug_screen_layer, mug_uv).rgb * screen
			+ texture(mug_base_layer, mug_uv).rgb * base
			+ texture(mug_world_layer, mug_uv).rgb * world
			+ texture(mug_indicator_layer, mug_uv).rgb * indicator;
		light = light * (1.0 - texture(mug_alpha, mug_uv).r) + mug;
	}
	COLOR = vec4(light, 1.0);
}
