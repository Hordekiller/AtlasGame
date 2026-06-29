shader_type canvas_item;
render_mode blend_add;

uniform vec4 color1 : source_color = vec4(1.0, 0.6, 0.1, 0.8);
uniform vec4 color2 : source_color = vec4(1.0, 0.2, 0.05, 0.0);

void fragment() {
	float gradient = 1.0 - UV.y;
	COLOR = mix(color1, color2, gradient);
	float alpha = 1.0 - smoothstep(0.0, 1.0, UV.y);
	COLOR.a *= alpha;

	float flicker = sin(UV.y * 20.0 + TIME * 10.0) * 0.3 + 0.7;
	COLOR.rgb *= flicker;

	float edge = 1.0 - abs(UV.x - 0.5) * 2.0;
	edge = pow(edge, 1.5);
	COLOR.a *= edge;
}
