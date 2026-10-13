shader_type canvas_item;
// The ND-OS picture on the curved CRT glass of the room photo.
// Draws over the glass area only: barrel-warped picture, phosphor softness and bloom,
// scanlines, and the photo's own glass reflections screen-blended on top.
// Geometry is in viewport units (640x360); keep in sync with crt_screen.gd.

uniform sampler2D ui_tex : filter_linear, repeat_disable;
uniform sampler2D room_tex : filter_linear, repeat_disable;
uniform vec2 view_size = vec2(640.0, 360.0);
uniform vec2 rect_pos;
uniform vec2 rect_size;
uniform vec4 glass;             // center xy, half size zw
uniform float glass_n = 7.0;
uniform vec4 active;            // center xy, half size zw
uniform float barrel = 0.045;
uniform float power = 1.0;      // 0 = screen off
uniform float flicker = 1.0;
// Picture clarity. 1 = the full CRT (soft phosphor, heavy glow, lamp reflection),
// 0 = a clean sharp picture; the shift cycles it with F4 for readability.
uniform float clarity : hint_range(0.0, 1.0) = 1.0;
uniform float softness = 0.22;  // weight of the neighbour ring mixed into every texel
uniform float bloom = 1.0;      // scales both glow passes
uniform float scan = 0.07;      // scanline depth
uniform float reflection = 0.7; // how much of the photo's glass reflection is screen-blended

float se(vec2 p, float n) {
	return pow(abs(p.x), n) + pow(abs(p.y), n);
}

vec3 phosphor(vec3 c) {
	c = pow(max(c, vec3(0.0)), vec3(0.9)) * 0.95;
	float g = (c.r + c.g + c.b) / 3.0;
	c = c * 0.72 + vec3(g) * 0.28;
	return c * vec3(1.0, 0.97, 0.9);
}

vec3 tap(vec2 uv) {
	return phosphor(texture(ui_tex, uv).rgb);
}

vec3 ring(vec2 uv, vec2 r) {
	vec3 s = tap(uv + vec2(r.x, 0.0)) + tap(uv - vec2(r.x, 0.0)) + tap(uv + vec2(0.0, r.y)) + tap(uv - vec2(0.0, r.y));
	s += tap(uv + r * 0.7) + tap(uv - r * 0.7) + tap(uv + vec2(r.x, -r.y) * 0.7) + tap(uv + vec2(-r.x, r.y) * 0.7);
	return s / 8.0;
}

void fragment() {
	vec2 p = rect_pos + UV * rect_size;
	vec2 u = (p - active.xy) / active.zw;
	float r2 = dot(u, u);
	vec2 s = u * (1.0 + barrel * r2) / (1.0 + barrel * 2.0);
	vec2 tuv = s * 0.5 + 0.5;
	vec2 px = 1.0 / vec2(textureSize(ui_tex, 0));

	float soft = softness * clarity;
	vec3 c = tap(tuv) * (1.0 - soft) + ring(tuv, px * 1.1) * soft;
	vec3 b1 = ring(tuv, px * 6.0);
	vec3 b2 = ring(tuv, px * 18.0);
	c += (b1 * 0.16 + b2 * 0.09) * bloom * clarity;
	c += vec3(0.018, 0.02, 0.017) * clarity;

	float am = clamp((1.0 - se(s, 22.0)) / 0.06, 0.0, 1.0);
	float line = 1.0 - scan * clarity * (0.5 - 0.5 * cos(s.y * 3.14159 * 168.0));
	float vign = clamp(1.0 - 0.2 * pow(r2 / 2.0, 1.4), 0.0, 1.0);
	vec3 pic = c * am * line * vign * power * flicker;

	vec2 g = (p - glass.xy) / glass.zw;
	float gm = clamp((1.0 - se(g, glass_n)) / 0.05, 0.0, 1.0);
	vec3 room = texture(room_tex, p / view_size).rgb;
	vec3 face = 1.0 - (1.0 - pic) * (1.0 - room * reflection * clarity);
	face += b2 * 0.3 * bloom * clarity * (1.0 - am) * power * flicker * clamp(1.0 - se(s, 4.0) * 0.4, 0.0, 1.0);
	COLOR = vec4(face, gm);
}
