shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform vec3 grass_tint_a : source_color = vec3(0.24, 0.56, 0.21);
uniform vec3 grass_tint_b : source_color = vec3(0.40, 0.68, 0.24);
uniform vec3 dirt_tint : source_color = vec3(0.56, 0.43, 0.29);
uniform vec3 rock_tint : source_color = vec3(0.48, 0.51, 0.56);
uniform vec3 snow_tint : source_color = vec3(0.93, 0.96, 1.00);
uniform float uv_scale = 0.22;

varying vec3 v_world_pos;
varying vec4 v_splat;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_splat = COLOR;
}

void fragment() {
	vec2 uv = v_world_pos.xz * uv_scale;
	float macro = value_noise(v_world_pos.xz * 0.085);
	float detail = value_noise(v_world_pos.xz * 0.65);

	// Soft organic edge feathering between brown dirt path and lush meadow grass
	float dirt_w = smoothstep(0.14, 0.78, v_splat.r + (detail - 0.5) * 0.22 * step(0.03, v_splat.r));
	float rock_w = clamp(v_splat.b, 0.0, 1.0);
	float snow_w = smoothstep(0.18, 0.75, v_splat.a + (detail - 0.5) * 0.16 * step(0.03, v_splat.a));

	vec3 g_tex = texture(grass_albedo, uv).rgb;
	vec3 g_col = mix(grass_tint_a, grass_tint_b, macro) * mix(vec3(0.92), g_tex * 1.45, 0.35);

	vec3 d_tex = texture(dirt_albedo, uv * 1.35).rgb;
	vec3 d_col = dirt_tint * mix(vec3(0.92), d_tex * 1.30, 0.42) * (0.92 + 0.16 * detail);

	vec3 r_tex = texture(rock_albedo, uv * 0.9).rgb;
	vec3 r_col = rock_tint * mix(vec3(0.90), r_tex * 1.28, 0.48);

	vec3 albedo = mix(g_col, d_col, dirt_w);
	albedo = mix(albedo, r_col, rock_w);
	albedo = mix(albedo, snow_tint, snow_w);

	vec3 n_grass = texture(grass_normal, uv).rgb;
	vec3 n_dirt = texture(dirt_normal, uv * 1.35).rgb;
	vec3 n_rock = texture(rock_normal, uv * 0.9).rgb;
	vec3 n_blend = mix(n_grass, n_dirt, dirt_w);
	n_blend = mix(n_blend, n_rock, max(rock_w, snow_w * 0.35));

	ALBEDO = albedo;
	NORMAL_MAP = n_blend;
	NORMAL_MAP_DEPTH = mix(0.45, 0.85, max(dirt_w, rock_w));
	ROUGHNESS = mix(0.86, 0.92, dirt_w) * (1.0 - snow_w * 0.22);
	METALLIC = 0.0;
}
