shader_type canvas_item;
// One direction of a gaussian blur, for the CRT glow. Two passes (across, then down) make the full blur.

uniform sampler2D source : filter_linear, repeat_disable;
// (1, 0) blurs across, (0, 1) down.
uniform vec2 direction = vec2(1.0, 0.0);
// In source pixels; 0 copies the source.
uniform float sigma = 4.0;
// The kernel reaches this many sigmas; the rest weighs under 0.3%.
const float REACH = 3.0;

void fragment() {
	if (sigma <= 0.0) {
		COLOR = texture(source, UV);
	} else {
		vec2 step_uv = direction / vec2(textureSize(source, 0));
		int radius = int(ceil(REACH * sigma));
		vec4 sum = vec4(0.0);
		float total = 0.0;
		for (int i = -radius; i <= radius; i++) {
			float weight = exp(-0.5 * float(i * i) / (sigma * sigma));
			sum += texture(source, UV + step_uv * float(i)) * weight;
			total += weight;
		}
		COLOR = sum / total;
	}
}
