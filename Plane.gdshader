void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	SPECULAR = specular;

	vec3 emission_tex = texture(texture_emission, base_uv).rgb;

	// ✅ Get world position of the light itself
	vec3 light_pos = (WORLD_TRANSFORM * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// ✅ Determine emission color based on aircraft position
	bool facing_aircraft = aircraft_position.z > light_pos.z;
	vec3 dynamic_emission = facing_aircraft ? vec3(1.0, 1.0, 0.0) : vec3(1.0); // yellow or white

	// ✅ Final emission with strength 100
	EMISSION = (emission.rgb + emission_tex + dynamic_emission) * 100.0;
}


