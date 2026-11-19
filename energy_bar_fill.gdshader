shader_type canvas_item;

uniform vec4 track_rect;
uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 extra_track_rects[2];
uniform vec2 extra_fill_ratios = vec2(0.0);
uniform vec2 paper_green_range = vec2(0.68, 0.86);
uniform vec4 fill_top : source_color = vec4(0.66, 0.53, 0.80, 1.0);
uniform vec4 fill_bottom : source_color = vec4(0.46, 0.33, 0.61, 1.0);

vec3 paint_track(vec3 paper_color, vec2 texture_point, vec4 track, float ratio) {
	if (ratio <= 0.0) {
		return paper_color;
	}
	vec2 point = texture_point - track.xy;
	float fill_width = track.z * ratio;
	float radius = min(track.w, fill_width) * 0.5;
	vec2 spine = vec2(clamp(point.x, radius, fill_width - radius), track.w * 0.5);
	float distance_to_edge = length(point - spine) - radius;
	float feather = max(0.5 * fwidth(distance_to_edge), 0.01);
	float coverage = (1.0 - smoothstep(-feather, feather, distance_to_edge)) * step(0.01, fill_width);

	// Let the dark outline and shading of the original artwork show through.
	float paper = smoothstep(paper_green_range.x, paper_green_range.y, paper_color.g);
	float height_fraction = clamp(point.y / track.w, 0.0, 1.0);
	vec3 ink = mix(fill_top.rgb, fill_bottom.rgb, height_fraction);
	return mix(paper_color, ink, coverage * paper * 0.94);
}

void fragment() {
	vec2 texture_point = UV * vec2(textureSize(TEXTURE, 0));
	vec3 painted = paint_track(COLOR.rgb, texture_point, track_rect, fill_ratio);
	painted = paint_track(painted, texture_point, extra_track_rects[0], extra_fill_ratios.x);
	COLOR.rgb = paint_track(painted, texture_point, extra_track_rects[1], extra_fill_ratios.y);
}
