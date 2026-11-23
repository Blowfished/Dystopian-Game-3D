shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tower_dark : source_color = vec4(0.07, 0.09, 0.19, 1.0);
uniform vec4 tower_mid : source_color = vec4(0.11, 0.15, 0.29, 1.0);
uniform vec4 haze_color : source_color = vec4(0.11, 0.145, 0.30, 1.0);
uniform vec4 window_warm_a : source_color = vec4(1.0, 0.72, 0.36, 1.0);
uniform vec4 window_warm_b : source_color = vec4(1.0, 0.88, 0.64, 1.0);
uniform vec4 window_dim_amber : source_color = vec4(0.76, 0.48, 0.24, 1.0);
uniform vec4 window_teal : source_color = vec4(0.24, 0.85, 0.86, 1.0);
uniform vec4 roof_magenta : source_color = vec4(1.0, 0.26, 0.62, 1.0);
uniform float emission_boost : hint_range(0.2, 5.0) = 1.95;
uniform float window_density : hint_range(0.1, 0.95) = 0.54;
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
	float dist_haze = smoothstep(75.0, 540.0, cam_dist);
	float low_haze = smoothstep(110.0, -75.0, v_world_pos.y) * 0.42;
	float total_haze = clamp(max(layer_haze, dist_haze * 0.72) + low_haze * (0.4 + layer_haze), 0.0, 0.86);

	// Height normalized 0 (bottom) to 1 (top) for a unit BoxMesh centered at 0.
	float h01 = clamp(v_local_pos.y + 0.5, 0.0, 1.0);
	vec3 base_col = mix(tower_dark.rgb, tower_mid.rgb, h01 * 0.65 + seed * 0.22);
	ALBEDO = mix(base_col, haze_color.rgb, total_haze);
	ROUGHNESS = 0.88;
	METALLIC = 0.10;

	vec3 an = abs(v_local_normal);
	bool is_roof = an.y > 0.6;
	vec3 emissive = vec3(0.0);

	if (!is_roof) {
		// Choose face horizontal coordinate scaled to physical tower meters.
		float horiz = (an.x > an.z) ? (v_local_pos.z + 0.5) * width : (v_local_pos.x + 0.5) * width;
		float vert = h01 * height;

		// Dense, fine grid spacing in meters so megastructures read at monumental scale.
		float col_w = mix(0.88, 1.38, fract(seed * 7.3)) * window_scale;
		float row_h = mix(1.32, 1.92, fract(seed * 13.1)) * window_scale;

		vec2 cell_id = floor(vec2(horiz / col_w, vert / row_h));
		vec2 cell_uv = fract(vec2(horiz / col_w, vert / row_h));

		// Subtle per-window size variation and crisp architectural mullions.
		float size_var = hash21(cell_id + vec2(seed * 61.3, 4.9));
		float x_pad = mix(0.20, 0.30, size_var);
		float y_pad = mix(0.25, 0.35, fract(size_var * 3.7));
		float win_mask = step(x_pad, cell_uv.x) * step(cell_uv.x, 1.0 - x_pad) * step(y_pad, cell_uv.y) * step(cell_uv.y, 1.0 - y_pad);

		// Keep edges and very top/bottom dark for clean silhouettes.
		float edge_mask = step(0.05, horiz / width) * step(horiz / width, 0.95) * step(0.03, h01) * step(h01, 0.97);

		// Floor clusters (some floors busier, some quiet) + individual room lights.
		float floor_bias = hash21(vec2(cell_id.y, seed * 41.0));
		float room_rand = hash21(cell_id + vec2(seed * 97.1, seed * 23.7));
		float lit_threshold = 1.0 - window_density * mix(0.45, 1.35, floor_bias);
		float is_lit = step(lit_threshold, room_rand);

		// Subtle brightness variation & slow gentle flicker on a small subset of windows.
		float flicker_chance = step(0.90, hash21(cell_id + vec2(11.4, seed * 53.0)));
		float flicker = 1.0 - flicker_chance * (0.18 + 0.16 * sin(TIME * (1.6 + room_rand * 3.8) + room_rand * 30.0));
		float brightness = mix(0.34, 1.24, hash21(cell_id + vec2(3.7, 9.2))) * flicker;

		// Mostly warm amber/cream windows, a few dim amber, and occasional cool cyan/indigo rooms.
		float color_pick = hash21(cell_id + vec2(19.2, seed * 17.0));
		vec3 wcol = mix(window_warm_a.rgb, window_warm_b.rgb, smoothstep(0.22, 0.86, color_pick));
		if (color_pick < 0.16) {
			wcol = window_dim_amber.rgb;
		} else if (color_pick > 0.91) {
			wcol = window_teal.rgb * 0.82;
		}

		// Farther windows become softer and dimmer into the atmospheric indigo haze.
		float dist_dim = mix(1.0, 0.36, smoothstep(95.0, 520.0, cam_dist));
		float vert_fade = smoothstep(0.02, 0.18, h01);
		emissive += wcol * win_mask * edge_mask * is_lit * brightness * vert_fade * dist_dim * emission_boost;

		// Occasional vertical architectural light strip on hero megastructures.
		if (style > 0.78) {
			float strip = smoothstep(0.028, 0.010, abs(horiz / width - 0.5));
			vec3 strip_col = (style > 0.90) ? window_teal.rgb : vec3(0.88, 0.92, 1.0);
			emissive += strip_col * strip * step(0.08, h01) * step(h01, 0.98) * 1.35 * dist_dim;
		}

		// Subtle horizontal teal crown band near the top of select towers.
		if (style > 0.54 && style <= 0.78) {
			float crown = smoothstep(0.016, 0.005, abs(h01 - 0.94));
			emissive += window_teal.rgb * crown * 1.05 * dist_dim;
		}
	} else if (v_local_normal.y > 0.6 && style > 0.68) {
		// Subtle rooftop aviation/beacon glow dots near roof corners.
		vec2 ruv = abs(v_local_pos.xz);
		float corner = smoothstep(0.11, 0.04, length(ruv - vec2(0.42, 0.42)));
		float pulse = 0.55 + 0.45 * sin(TIME * 2.0 + seed * 19.0);
		emissive += roof_magenta.rgb * corner * pulse * 2.0;
	}

	// Keep far abyssal underside soft and fade tower emission gently into indigo depth haze.
	float abyss_fade = smoothstep(-95.0, -10.0, v_world_pos.y);
	EMISSION = emissive * mix(0.22, 1.0, abyss_fade) * (1.0 - total_haze * 0.55);
}
