shader_type canvas_item;
// The ND-OS picture as the CRT shows it, built like the Figma frame "ND-OS Desktop / CRT" (2:114) and in
// its colour space (display sRGB): glow, scanlines, vignette, noise, then the tube's edge shading.
// The front frame turns the result into light. CrtPreset holds the numbers; sizes are in ND-OS pixels.

uniform sampler2D picture : filter_nearest, repeat_disable;
uniform sampler2D glow : filter_linear, repeat_disable;
uniform vec2 screen_size = vec2(1280.0, 960.0);

uniform float scanline_opacity;
uniform int scanline_period = 3;
uniform float glow_opacity;
uniform float vignette_start;
uniform float vignette_mid;
uniform float vignette_mid_opacity;
uniform float vignette_edge_opacity;
uniform float noise_opacity;
uniform float noise_density;
// Changes every frame; screenshots fix it.
uniform float noise_seed;
uniform float tube_radius;
uniform float edge_shadow_opacity;
uniform float edge_shadow_blur;
uniform vec3 edge_light_color : source_color;
uniform float edge_light_opacity;
uniform float edge_light_blur;
uniform float edge_light_offset;

// Logistic fit of the gaussian's cumulative curve, close enough for soft shadows.
const float GAUSS_LOGISTIC = 1.702;

// Distance from p into the tube's rounded rectangle; negative outside.
float inside_tube(vec2 p) {
	vec2 half_size = screen_size * 0.5;
	vec2 q = abs(p - half_size) - (half_size - tube_radius);
	return tube_radius - length(max(q, 0.0)) - min(max(q.x, q.y), 0.0);
}

// How much of a Figma inner shadow with this blur radius reaches a point this far inside the shape.
float inner_shadow(float inside, float blur) {
	if (blur <= 0.0) {
		return inside > 0.0 ? 0.0 : 1.0;
	}
	// Figma's blur radius is two sigmas.
	return 1.0 / (1.0 + exp(GAUSS_LOGISTIC * inside / (blur * 0.5)));
}

// Darkening at r, the distance from the centre in units of the inscribed ellipse.
float vignette(float r) {
	if (r <= vignette_start) {
		return 0.0;
	}
	if (r <= vignette_mid) {
		return vignette_mid_opacity * (r - vignette_start) / (vignette_mid - vignette_start);
	}
	return mix(vignette_mid_opacity, vignette_edge_opacity, clamp((r - vignette_mid) / (1.0 - vignette_mid), 0.0, 1.0));
}

// Repeatable random number in [0, 1) for a pixel and a seed (the common sine hash).
float random(vec2 pixel, float seed) {
	return fract(sin(dot(pixel + seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * screen_size;
	vec2 pixel = floor(p);
	vec3 c = texture(picture, UV).rgb;
	vec3 g = texture(glow, UV).rgb;
	c = mix(c, 1.0 - (1.0 - c) * (1.0 - g), glow_opacity);
	if (int(pixel.y) % scanline_period == 0) {
		c = mix(c, vec3(0.0), scanline_opacity);
	}
	c = mix(c, vec3(0.0), vignette(length((UV - 0.5) * 2.0)));
	// Figma's monotone noise, measured on its export: a fine white veil whose mean is
	// opacity × density × 0.5 over the picture.
	c = mix(c, vec3(1.0), noise_opacity * noise_density * random(pixel, noise_seed));
	c = mix(c, vec3(0.0), edge_shadow_opacity * inner_shadow(inside_tube(p), edge_shadow_blur));
	float light = inner_shadow(inside_tube(p - vec2(0.0, edge_light_offset)), edge_light_blur);
	c = mix(c, edge_light_color, edge_light_opacity * light);
	COLOR = vec4(c, 1.0);
}
