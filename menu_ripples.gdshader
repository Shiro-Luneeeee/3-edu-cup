shader_type canvas_item;

uniform sampler2D background_texture : source_color, filter_linear, repeat_disable;
uniform vec2 image_size = vec2(1672.0, 941.0);
uniform vec4 ripples[16]; // Center x/y, elapsed seconds, final radius (in screen-height units).

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 displacement = vec2(0.0);
	float highlight = 0.0;

	for (int i = 0; i < 16; i++) {
		vec4 ripple = ripples[i];
		if (ripple.z < 0.0 || ripple.z > 1.65) {
			continue;
		}
		vec2 from_center = (UV - ripple.xy) * vec2(aspect, 1.0);
		float distance_to_center = length(from_center);
		float front = ripple.w * ripple.z / 1.65;
		float ring_width = 0.009 + ripple.w * 0.13;
		float from_front = distance_to_center - front;
		float envelope = exp(-pow(from_front / ring_width, 2.0));
		float fade = 1.0 - ripple.z / 1.65;
		float wave = sin(from_front * 340.0) * envelope * fade;
		vec2 direction = from_center / max(distance_to_center, 0.0001);
		displacement += vec2(direction.x / aspect, direction.y) * wave * 0.006;
		highlight += envelope * fade * (0.018 + 0.012 * cos(from_front * 340.0));
	}

	// Cover the screen without stretching the supplied illustration.
	vec2 visible_fraction = vec2(1.0);
	float image_aspect = image_size.x / image_size.y;
	if (aspect > image_aspect) {
		visible_fraction.y = image_aspect / aspect;
	} else {
		visible_fraction.x = aspect / image_aspect;
	}
	vec2 image_uv = (UV + displacement - vec2(0.5)) * visible_fraction + vec2(0.5);
	vec4 background = texture(background_texture, image_uv);
	COLOR = vec4(min(background.rgb + vec3(highlight), vec3(1.0)), background.a);
}
