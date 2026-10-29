// The inverse of agx_punchy(): the linear light that AgX Punchy shows as a given display colour, so a
// picture keeps its own colours after tonemapping. tools/glass/bake_inverse_agx.py bakes the LUT from
// the forward one; Lut3D.apply_to(material, "agx_inverse_lut") sets these uniforms.

uniform sampler3D agx_inverse_lut : filter_linear, repeat_disable;
uniform float agx_inverse_lut_size;

// Display sRGB in, linear Rec.709 light out (before exposure).
vec3 agx_punchy_inverse(vec3 display) {
	vec3 t = (clamp(display, 0.0, 1.0) * (agx_inverse_lut_size - 1.0) + 0.5) / agx_inverse_lut_size;
	return exp2(texture(agx_inverse_lut, t).rgb);
}
