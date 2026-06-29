shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float glow_radius : hint_range(0.0, 10.0) = 3.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	vec4 color = texture(screen_texture, uv);

	vec4 glow = vec4(0.0);
	float samples = 0.0;
	for (float x = -glow_radius; x <= glow_radius; x += 1.0) {
		for (float y = -glow_radius; y <= glow_radius; y += 1.0) {
			float dist = length(vec2(x, y));
			if (dist > glow_radius) continue;
			vec2 offset = vec2(x, y) * (1.0 / vec2(textureSize(screen_texture, 0)));
			glow += texture(screen_texture, uv + offset);
			samples += 1.0;
		}
	}
	glow /= samples;

	float brightness = dot(glow.rgb, vec3(0.299, 0.587, 0.114));
	glow *= smoothstep(0.3, 0.8, brightness) * glow_intensity;

	COLOR = color + glow * 0.5;
}
