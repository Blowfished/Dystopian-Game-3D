shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.2, 0.25, 0.38, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.08, 0.12, 0.26, 1.0);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.78;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.05;
uniform vec4 rim_color : source_color = vec4(0.37, 0.52, 0.77, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.24;
uniform float rim_power : hint_range(1.0, 8.0) = 3.2;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 0.0;
uniform float top_gradient : hint_range(0.0, 0.5) = 0.14;

varying vec3 v_world_normal;

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Subtle painterly top-to-bottom value shift so forms read softly even in flat lighting.
	float up_factor = clamp(v_world_normal.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 shaded_albedo = mix(albedo_color.rgb * mix(vec3(1.0), shadow_tint.rgb * 2.2, 0.35), albedo_color.rgb * (1.0 + top_gradient), up_factor);

	ALBEDO = shaded_albedo;
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;

	// Soft stylized Fresnel rim biased slightly upward to catch moonlight and city glow.
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, rim_power);
	float sky_bias = mix(0.45, 1.0, up_factor);
	vec3 rim_glow = rim_color.rgb * fresnel * rim_strength * sky_bias;

	EMISSION = emission_color.rgb * emission_energy + rim_glow;
}
