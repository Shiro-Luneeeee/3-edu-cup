shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float direction = 1.0;

float glint(vec2 point, float size) {
	vec2 arms = pow(abs(point) / vec2(size * 0.76, size), vec2(0.65));
	return 1.0 - smoothstep(0.83, 1.1, arms.x + arms.y);
}

void fragment() {
	float x = direction > 0.0 ? UV.x : 1.0 - UV.x;
	float diagonal = x + (UV.y - 0.5) * 0.32 + sin(UV.y * 3.14159) * 0.035;
	float page_x = mix(-0.34, 2.84, progress) - diagonal;
	// At the scene swap, both edges of the sheet are outside the viewport.
	float distance_to_edge = min(page_x, 1.50 - page_x);
	float paper_mask = smoothstep(-0.0015, 0.0015, distance_to_edge);
	float shadow = 0.42 * (1.0 - smoothstep(0.0, 0.075, -distance_to_edge));

	float light = clamp(0.87 - UV.y * 0.48 + 0.16 * cos(page_x * 5.0), 0.0, 1.0);
	vec3 paper = mix(vec3(0.79, 0.67, 0.83), vec3(1.0, 0.95, 0.81), light);
	float ruling = 1.0 - smoothstep(0.014, 0.045, abs(fract(UV.y * 24.0) - 0.5));
	paper = mix(paper, vec3(0.48, 0.38, 0.57), ruling * 0.13);
	float fold = 1.0 - smoothstep(0.0, 0.17, distance_to_edge);
	paper = mix(paper, vec3(0.48, 0.33, 0.61), fold * 0.34);

	float trim = 1.0 - smoothstep(0.026, 0.029, distance_to_edge);
	paper = mix(paper, vec3(0.37, 0.25, 0.49), trim * 0.88);
	float gold = 1.0 - smoothstep(0.0015, 0.004, abs(distance_to_edge - 0.024));
	float fine_gold = 1.0 - smoothstep(0.0009, 0.0026, abs(distance_to_edge - 0.039));
	paper = mix(paper, vec3(1.0, 0.81, 0.48), max(gold, fine_gold * 0.65));

	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float edge_x = (distance_to_edge - 0.066) * aspect;
	float sparks = glint(vec2(edge_x, UV.y - 0.22), 0.018);
	sparks += glint(vec2(edge_x + 0.032, UV.y - 0.42), 0.011);
	sparks += glint(vec2(edge_x, UV.y - 0.67), 0.022);
	sparks += glint(vec2(edge_x - 0.039, UV.y - 0.78), 0.009);
	paper = mix(paper, vec3(1.0, 0.96, 0.72), clamp(sparks, 0.0, 1.0));
	COLOR = vec4(mix(vec3(0.13, 0.09, 0.23), paper, paper_mask), mix(shadow, 1.0, paper_mask));
}
