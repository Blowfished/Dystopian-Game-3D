shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 beam_color : source_color = vec4(0.95, 0.91, 0.78, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.24;
uniform float edge_softness : hint_range(0.5, 6.0) = 2.4;
uniform float beam_height : hint_range(1.0, 400.0) = 1.0;

varying float v_height;

void vertex() {
	// Normalized 0 (narrow emitter base) to 1 (wide upper sky fade).
	v_height = clamp(VERTEX.y / max(beam_height, 0.001) + 0.5, 0.0, 1.0);
}

void fragment() {
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = pow(clamp(ndotv, 0.0, 1.0), edge_softness);
	// Softly fade in near the source base and fade out toward the upper sky.
	float v_fade = smoothstep(0.0, 0.14, v_height) * pow(1.0 - v_height, 1.55);
	float alpha = edge * v_fade * intensity;
	ALBEDO = beam_color.rgb * alpha;
	ALPHA = alpha;
}
