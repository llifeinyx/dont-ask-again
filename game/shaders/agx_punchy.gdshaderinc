// Blender's AgX view transform with the "AgX - Punchy" look, baked into a 3D LUT over a log2 shaper.
// tools/blender/export_front.py bakes the LUT; Lut3D.apply_to() sets these uniforms.

uniform sampler3D agx_lut : filter_linear, repeat_disable;
uniform float agx_lut_lo;
uniform float agx_lut_hi;
uniform float agx_lut_size;

// Linear Rec.709 light in, display sRGB out.
vec3 agx_punchy(vec3 linear) {
	vec3 t = clamp((log2(max(linear, vec3(1e-12))) - agx_lut_lo) / (agx_lut_hi - agx_lut_lo), 0.0, 1.0);
	// Texel centres: 0 and 1 must land on the first and last LUT entries.
	t = (t * (agx_lut_size - 1.0) + 0.5) / agx_lut_size;
	return texture(agx_lut, t).rgb;
}
