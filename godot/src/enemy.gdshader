shader_type spatial;

uniform sampler2D albedo_texture : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (fract(SCREEN_UV.x*500.0 + SCREEN_UV.y*500.0) < 0.5) discard;
	ALBEDO = texture(albedo_texture, UV).xyz;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
