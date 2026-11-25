shader_type canvas_item;
render_mode unshaded;

varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float value = max(texel.r, max(texel.g, texel.b));
	float alpha = smoothstep(0.035, 0.20, value);
	vec3 foreground = clamp(texel.rgb / max(alpha, 0.45), vec3(0.0), vec3(1.0));
	COLOR = vec4(foreground, texel.a * alpha) * sprite_tint;
}
