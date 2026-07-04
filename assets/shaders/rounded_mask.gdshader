shader_type canvas_item;

// Clips the node's own texture to a rounded rectangle. Push corner_radius
// up toward min(width, height) / 2 to turn it into a full circle/pill.
uniform float corner_radius : hint_range(0.0, 1000.0) = 28.0;
uniform float edge_softness : hint_range(0.0, 8.0) = 1.5;

float rounded_rect_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 d = abs(point) - half_size + radius;
	return length(max(d, 0.0)) - radius;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel_pos = UV * size;
	vec2 centered = pixel_pos - size * 0.5;

	float radius = min(corner_radius, min(size.x, size.y) * 0.5);
	float dist = rounded_rect_sdf(centered, size * 0.5, radius);

	vec4 tex_color = texture(TEXTURE, UV);
	float mask = 1.0 - smoothstep(-edge_softness, edge_softness, dist);

	COLOR = vec4(tex_color.rgb, tex_color.a * mask);
}
