shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tower_dark : source_color = vec4(0.10, 0.085, 0.21, 1.0);
uniform vec4 tower_mid : source_color = vec4(0.16, 0.135, 0.32, 1.0);
uniform vec4 haze_color : source_color = vec4(0.16, 0.125, 0.31, 1.0);
uniform vec4 window_warm_a : source_color = vec4(1.0, 0.74, 0.38, 1.0);
uniform vec4 window_warm_b : source_color = vec4(1.0, 0.89, 0.66, 1.0);
uniform vec4 window_dim_amber : source_color = vec4(0.84, 0.52, 0.26, 1.0);
uniform vec4 window_teal : source_color = vec4(0.24, 0.88, 0.90, 1.0);
uniform vec4 roof_magenta : source_color = vec4(1.0, 0.26, 0.64, 1.0);
uniform float emission_boost : hint_range(0.2, 5.0) = 2.15;
uniform float window_density : hint_range(0.1, 0.95) = 0.58;
uniform float window_scale : hint_range(0.25, 2.0) = 1.0;
uniform float layer_haze : hint_range(0.0, 0.85) = 0.0;

varying vec4 v_custom;
varying vec3 v_local_pos;
varying vec3 v_local_normal;
varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// v_custom: x = seed, y = tower_width, z = tower_height, w = style (0..1)
	float seed = v_custom.x;
	float width = max(v_custom.y, 6.0);
	float height = max(v_custom.z, 20.0);
	float style = v_custom.w;

	float cam_dist = length(CAMERA_POSITION_WORLD - v_world_pos);
	float dist_haze = smoothstep(85.0, 520.0, cam_dist);
	float low_haze = smoothstep(95.0, -68.0, v_world_pos.y) * 0.44;
	float total_haze = clamp(max(layer_haze, dist_haze * 0.72) + low_haze * (0.38 + layer_haze), 0.0, 0.86);

	// Height normalized 0 (bottom) to 1 (top) for a unit BoxMesh centered at 0.
	float h01 = clamp(v_local_pos.y + 0.5, 0.0, 1.0);
	vec3 base_col = mix(tower_dark.rgb, tower_mid.rgb, h01 * 0.65 + seed * 0.22);
	ALBEDO = mix(base_col, haze_color.rgb, total_haze);
	ROUGHNESS = 0.86;
	METALLIC = 0.10;

	vec3 an = abs(v_local_normal);
	bool is_roof = an.y > 0.6;
	vec3 emissive = vec3(0.0);

	if (!is_roof) {
		float horiz = (an.x > an.z) ? (v_local_pos.z + 0.5) * width : (v_local_pos.x + 0.5) * width;
		float vert = h01 * height;

		float col_w = mix(1.05, 1.55, fract(seed * 7.3)) * window_scale;
		float row_h = mix(1.45, 2.05, fract(seed * 13.1)) * window_scale;

		vec2 cell_id = floor(vec2(horiz / col_w, vert / row_h));
		vec2 cell_uv = fract(vec2(horiz / col_w, vert / row_h));

		float size_var = hash21(cell_id + vec2(seed * 61.3, 4.9));
		float x_pad = mix(0.18, 0.28, size_var);
		float y_pad = mix(0.24, 0.34, fract(size_var * 3.7));
		float win_mask = step(x_pad, cell_uv.x) * step(cell_uv.x, 1.0 - x_pad) * step(y_pad, cell_uv.y) * step(cell_uv.y, 1.0 - y_pad);

		float edge_mask = step(0.04, horiz / width) * step(horiz / width, 0.96) * step(0.02, h01) * step(h01, 0.98);

		float floor_bias = hash21(vec2(cell_id.y, seed * 41.0));
		float room_rand = hash21(cell_id + vec2(seed * 97.1, seed * 23.7));
		float lit_threshold = 1.0 - window_density * mix(0.48, 1.38, floor_bias);
		float is_lit = step(lit_threshold, room_rand);

		float flicker_chance = step(0.90, hash21(cell_id + vec2(11.4, seed * 53.0)));
		float flicker = 1.0 - flicker_chance * (0.16 + 0.14 * sin(TIME * (1.6 + room_rand * 3.8) + room_rand * 30.0));
		float brightness = mix(0.42, 1.32, hash21(cell_id + vec2(3.7, 9.2))) * flicker;

		float color_pick = hash21(cell_id + vec2(19.2, seed * 17.0));
		vec3 wcol = mix(window_warm_a.rgb, window_warm_b.rgb, smoothstep(0.20, 0.84, color_pick));
		if (color_pick < 0.16) {
			wcol = window_dim_amber.rgb;
		} else if (color_pick > 0.88 && color_pick <= 0.95) {
			wcol = window_teal.rgb * 0.88;
		} else if (color_pick > 0.95) {
			wcol = roof_magenta.rgb * 0.82;
		}

		float dist_dim = mix(1.0, 0.42, smoothstep(95.0, 520.0, cam_dist));
		float vert_fade = smoothstep(0.01, 0.12, h01);
		emissive += wcol * win_mask * edge_mask * is_lit * brightness * vert_fade * dist_dim * emission_boost;

		if (style > 0.78) {
			float strip = smoothstep(0.028, 0.010, abs(horiz / width - 0.5));
			vec3 strip_col = (style > 0.90) ? window_teal.rgb : ((style > 0.84) ? roof_magenta.rgb : window_warm_b.rgb);
			emissive += strip_col * strip * step(0.08, h01) * step(h01, 0.98) * 1.45 * dist_dim;
		}

		if (style > 0.54 && style <= 0.78) {
			float crown = smoothstep(0.016, 0.005, abs(h01 - 0.94));
			emissive += window_teal.rgb * crown * 1.15 * dist_dim;
		}
	} else if (v_local_normal.y > 0.6 && style > 0.65) {
		vec2 ruv = abs(v_local_pos.xz);
		float corner = smoothstep(0.11, 0.04, length(ruv - vec2(0.42, 0.42)));
		float pulse = 0.55 + 0.45 * sin(TIME * 2.0 + seed * 19.0);
		emissive += roof_magenta.rgb * corner * pulse * 2.1;
	}

	float abyss_fade = smoothstep(-95.0, -16.0, v_world_pos.y);
	EMISSION = emissive * mix(0.32, 1.0, abyss_fade) * (1.0 - total_haze * 0.48);
}
