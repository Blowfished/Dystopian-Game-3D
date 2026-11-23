shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.24;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.58;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.014;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.46;
uniform vec3 shadow_color : source_color = vec3(0.13, 0.09, 0.22);
uniform vec3 highlight_color : source_color = vec3(1.06, 0.97, 0.85);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;

	// Warm amber highlights / deep indigo-violet lifted shadows split-toning.
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	vec3 violet_lifted = mix(col, max(col, shadow_color * 0.52) * vec3(1.01, 0.95, 1.08), (1.0 - smoothstep(0.0, 0.42, luma)) * grade_strength);
	vec3 warm_graded = mix(violet_lifted, violet_lifted * highlight_color, smoothstep(0.32, 0.95, luma) * grade_strength);
	col = warm_graded;

	// Gentle film grain.
	if (grain_strength > 0.0005) {
		float g = hash12(FRAGCOORD.xy + vec2(fract(TIME * 17.0) * 500.0, fract(TIME * 31.0) * 500.0)) - 0.5;
		col += g * grain_strength;
	}

	// Soft atmospheric vignette.
	vec2 centered = SCREEN_UV - vec2(0.5);
	float dist = length(centered * vec2(1.12, 1.0));
	float vig = smoothstep(0.38, 0.38 + vignette_softness, dist);
	col *= 1.0 - vig * vignette_strength;

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
