shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.5, 0.7, 1.0, 0.0);
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * glow_intensity;
	COLOR = base + glow_color * pulse;
	COLOR.a = base.a;
}
