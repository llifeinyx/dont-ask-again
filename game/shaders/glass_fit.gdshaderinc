// Where the ND-OS picture sits in the tube's lit raster; the same maths as GlassFit.glass_to_ndos(),
// which also sets this uniform (GlassFit.apply_to()).

uniform float glass_picture_scale = 1.0;

// ND-OS position (0..1 inside the picture) at a point of the glass UV pass; outside 0..1 off it.
vec2 glass_to_ndos(vec2 glass_uv) {
	return 0.5 + (glass_uv - 0.5) / glass_picture_scale;
}
