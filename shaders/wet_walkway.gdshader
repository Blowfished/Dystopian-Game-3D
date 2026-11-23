shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_stone : source_color = vec4(0.11, 0.14, 0.23, 1.0);
uniform vec4 grout_color : source_color = vec4(0.06, 0.08, 0.14, 1.0);
uniform vec4 puddle_tint : source_color = vec4(0.07, 0.10, 0.19, 1.0);
uniform vec4 sky_sheen : source_color = vec4(0.18, 0.26, 0.48, 1.0);
uniform float tile_size : hint_range(0.5, 4.0) = 1.6;
uniform float puddle_amount : hint_range(0.0, 1.0) = 0.52;
uniform float rain_intensity : hint_range(0.0, 2.0) = 1.0;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p = p * 2.03 + vec2(13.7, 29.1);
		amp *= 0.5;
	}
	return v;
}

// Expanding circular raindrop ripples in a tiled grid.
vec2 rain_ripple_normal(vec2 uv, float t) {
	vec2 total = vec2(0.0);
	for (int layer = 0; layer < 2; layer++) {
		float scale = (layer == 0) ? 2.4 : 3.9;
		vec2 p = uv * scale + vec2(float(layer) * 17.3, float(layer) * 9.1);
		vec2 cell = floor(p);
		vec2 local = fract(p) - 0.5;
		float seed = hash21(cell + float(layer) * 31.7);
		float cycle = fract(t * (0.75 + seed * 0.45) + seed * 7.0);
		vec2 drop_offset = (vec2(hash21(cell + 1.3), hash21(cell + 7.9)) - 0.5) * 0.48;
		vec2 dvec = local - drop_offset;
		float dist = length(dvec);
		float radius = cycle * 0.44;
		float ring = exp(-pow((dist - radius) * 24.0, 2.0));
		float fade = (1.0 - cycle) * smoothstep(0.0, 0.08, cycle);
		float wave = sin((dist - radius) * 52.0) * ring * fade;
		total += normalize(dvec + vec2(0.0001)) * wave;
	}
	return total;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = v_world_pos.xz;

	// Stylized paving slabs with soft panel variation.
	vec2 tile_uv = wp / tile_size;
	vec2 tile_id = floor(tile_uv);
	vec2 tile_f = fract(tile_uv);
	float border_x = min(tile_f.x, 1.0 - tile_f.x);
	float border_y = min(tile_f.y, 1.0 - tile_f.y);
	float grout = 1.0 - smoothstep(0.015, 0.038, min(border_x, border_y));
	float tile_var = (hash21(tile_id) - 0.5) * 0.08;

	// Organic puddle mask driven by FBM noise.
	float n = fbm(wp * 0.24 + vec2(3.1, 7.4));
	float puddle = smoothstep(0.62 - puddle_amount * 0.35, 0.78 - puddle_amount * 0.25, n);
	// Slightly pool water along tile grooves.
	puddle = clamp(puddle + grout * 0.22, 0.0, 1.0);

	// Rain ripples inside puddles.
	vec2 ripple = rain_ripple_normal(wp, TIME) * puddle * rain_intensity;
	vec3 micro_normal = normalize(vec3(ripple.x * 0.24, ripple.y * 0.24, 1.0));
	NORMAL_MAP = micro_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.85;

	vec3 stone = base_stone.rgb * (1.0 + tile_var);
	stone = mix(stone, grout_color.rgb, grout * 0.72);
	// Wet concrete darkens slightly inside puddles and reflects surroundings sharply.
	vec3 col = mix(stone, puddle_tint.rgb, puddle * 0.65);

	ALBEDO = col;
	ROUGHNESS = mix(0.56, 0.045, puddle);
	METALLIC = mix(0.06, 0.22, puddle);
	SPECULAR = mix(0.48, 0.92, puddle);

	// Subtle cool Fresnel sheen on wet ground so puddles catch twilight even at low quality.
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 4.0);
	EMISSION = sky_sheen.rgb * fresnel * mix(0.05, 0.24, puddle);
}
