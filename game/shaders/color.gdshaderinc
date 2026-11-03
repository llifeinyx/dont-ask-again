// Colour conversions shared by shaders.

// Display sRGB to linear Rec.709, the exact piecewise curve.
vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// Relative luminance of linear Rec.709 light.
float luminance(vec3 linear) {
	return dot(linear, vec3(0.2126, 0.7152, 0.0722));
}
