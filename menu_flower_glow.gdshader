shader_type canvas_item;
render_mode blend_mix;

uniform float reveal_progress = 1.12;
uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	// A shallow wave carries one continuous light band across the flower bed.
	float center_y = 0.70
		+ 0.010 * sin(UV.x * 6.0 + TIME * 0.20)
		+ 0.005 * sin(UV.x * 15.0 - TIME * 0.13);
	float distance_to_band = abs(UV.y - center_y);
	float atmosphere = exp(-pow(distance_to_band / 0.105, 2.0)) * 0.055;
	float halo = exp(-pow(distance_to_band / 0.036, 2.0)) * 0.105;
	float fine_line = exp(-pow(distance_to_band / 0.0045, 2.0)) * 0.175;

	// Flower colors drift through a pale yellow base without hard color stops.
	vec3 color = vec3(1.0, 0.95, 0.66);
	float rose = exp(-pow((UV.x - 0.23 - 0.035 * sin(TIME * 0.08)) / 0.19, 2.0));
	float lime = exp(-pow((UV.x - 0.51 - 0.045 * sin(TIME * 0.06 + 1.3)) / 0.20, 2.0));
	float violet = exp(-pow((UV.x - 0.77 - 0.035 * sin(TIME * 0.07 + 2.2)) / 0.18, 2.0));
	color = mix(color, vec3(1.0, 0.72, 0.79), rose * 0.43);
	color = mix(color, vec3(0.82, 0.96, 0.60), lime * 0.35);
	color = mix(color, vec3(0.80, 0.76, 0.98), violet * 0.32);

	float breath = 0.86 + 0.14 * sin(TIME * 0.68);
	float reveal = 1.0 - smoothstep(reveal_progress - 0.10, reveal_progress + 0.10, UV.x);
	float alpha = (atmosphere + halo + fine_line) * breath * reveal * glow_strength;
	COLOR = vec4(color, alpha);
}
