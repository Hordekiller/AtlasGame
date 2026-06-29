shader_type canvas_item;

uniform float wave_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec4 shallow_color : source_color = vec4(0.1, 0.4, 0.6, 1.0);
uniform vec4 deep_color : source_color = vec4(0.0, 0.15, 0.3, 1.0);
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	float time = TIME * wave_speed + time_offset;

	float wave1 = sin(uv.x * 8.0 + uv.y * 4.0 + time * 0.7) * 0.5 + 0.5;
	float wave2 = sin(uv.x * 3.0 - uv.y * 6.0 + time * 0.5) * 0.5 + 0.5;
	float wave3 = cos(uv.x * 5.0 + uv.y * 5.0 + time * 0.3) * 0.5 + 0.5;

	float combined = (wave1 + wave2 + wave3) / 3.0;
	vec4 water_color = mix(shallow_color, deep_color, combined);

	float edge_fade = 1.0 - smoothstep(0.0, 0.2, min(uv.x, 1.0 - uv.x));
	edge_fade = max(edge_fade, 1.0 - smoothstep(0.0, 0.2, min(uv.y, 1.0 - uv.y)));
	water_color.a = 1.0 - edge_fade;

	vec2 displacement = vec2(
		sin(uv.y * 10.0 + time) * wave_strength * 0.01,
		cos(uv.x * 10.0 + time * 1.3) * wave_strength * 0.01
	);

	COLOR = water_color;

	float specular = pow(max(0.0, combined - 0.3), 4.0) * 0.3;
	COLOR.rgb += vec3(specular);
}
