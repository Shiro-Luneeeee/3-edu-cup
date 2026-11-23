shader_type canvas_item;

// Add a small amount of ink only beside solid strokes. Ignore faint PNG noise.
uniform float spread_px : hint_range(0.0, 12.0) = 5.0;
uniform float extra_opacity : hint_range(0.0, 1.0) = 0.24;
uniform bool white_ink = false;
// Colors sampled from main_menu_background.png: pink (520,470), green (530,240), yellow (400,580).
uniform vec4 glow_pink : source_color = vec4(0.992, 0.710, 0.784, 1.0);
uniform vec4 glow_green : source_color = vec4(0.788, 0.886, 0.376, 1.0);
uniform vec4 glow_yellow : source_color = vec4(0.992, 0.898, 0.267, 1.0);
uniform float color_flow_speed : hint_range(0.0, 0.2) = 0.055;
uniform bool include_pink_glow = true;
uniform float breath_scale = 0.0;
uniform float breath_rise = 0.0; // Fraction of the texture height.

varying float breath;

void vertex() {
	breath = -cos(TIME * 1.25);
}

void fragment() {
	// Sample around the texture center so the artwork and its halo move together.
	vec2 ink_uv = (UV - vec2(0.5) + vec2(0.0, breath_rise * breath))
		/ (1.0 + breath_scale * breath) + vec2(0.5);
	vec4 original = texture(TEXTURE, ink_uv);
	vec2 step_size = TEXTURE_PIXEL_SIZE * spread_px;
	float nearby = 0.0;
	nearby = max(nearby, texture(TEXTURE, ink_uv + vec2(step_size.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, ink_uv - vec2(step_size.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, ink_uv + vec2(0.0, step_size.y)).a);
	nearby = max(nearby, texture(TEXTURE, ink_uv - vec2(0.0, step_size.y)).a);
	float support = smoothstep(0.45, 0.95, nearby) * extra_opacity;
	float ink_alpha = original.a + (1.0 - original.a) * support;

	// Weighted average produces a smooth halo without the stepped edges of dilation.
	float glow_pulse = 0.5 + 0.5 * breath;
	float glow_step = mix(18.0, 27.0, glow_pulse);
	float blurred_ink = 0.0;
	for (int y = -2; y <= 2; y++) {
		float wy = y == 0 ? 6.0 : (abs(y) == 1 ? 4.0 : 1.0);
		for (int x = -2; x <= 2; x++) {
			float wx = x == 0 ? 6.0 : (abs(x) == 1 ? 4.0 : 1.0);
			vec2 sample_uv = ink_uv + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * glow_step;
			float solid_ink = smoothstep(0.30, 0.80, texture(TEXTURE, sample_uv).a);
			blurred_ink += solid_ink * wx * wy;
		}
	}
	float glow_mask = pow(1.0 - exp(-14.0 * blurred_ink / 256.0), 0.65);
	float glow_alpha = glow_mask * mix(0.30, 0.75, glow_pulse);
	float color_phase = fract(SCREEN_UV.x * 3.4 + SCREEN_UV.y * 0.85 - TIME * color_flow_speed);
	vec3 glow_rgb;
	if (!include_pink_glow) {
		float blend = 0.5 - 0.5 * cos(color_phase * TAU);
		glow_rgb = mix(glow_green.rgb, glow_yellow.rgb, blend);
	} else if (color_phase < 0.3333333) {
		float blend = smoothstep(0.0, 1.0, color_phase * 3.0);
		glow_rgb = mix(glow_pink.rgb, glow_green.rgb, blend);
	} else if (color_phase < 0.6666667) {
		float blend = smoothstep(0.0, 1.0, (color_phase - 0.3333333) * 3.0);
		glow_rgb = mix(glow_green.rgb, glow_yellow.rgb, blend);
	} else {
		float blend = smoothstep(0.0, 1.0, (color_phase - 0.6666667) * 3.0);
		glow_rgb = mix(glow_yellow.rgb, glow_pink.rgb, blend);
	}
	float alpha = ink_alpha + (1.0 - ink_alpha) * glow_alpha;
	vec3 color = mix(glow_rgb, original.rgb, ink_alpha);
	if (white_ink) {
		color = mix(glow_rgb, vec3(1.0), ink_alpha / max(alpha, 0.0001));
	}
	COLOR = vec4(color, alpha);
}
