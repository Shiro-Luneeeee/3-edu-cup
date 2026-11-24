shader_type canvas_item;

uniform vec4 hole_rect = vec4(-1.0);

void fragment() {
	if (UV.x >= hole_rect.x && UV.x < hole_rect.z && UV.y >= hole_rect.y && UV.y < hole_rect.w) {
		COLOR.a = 0.0;
	}
}
