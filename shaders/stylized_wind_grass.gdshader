shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 root_color : source_color = vec3(0.09, 0.30, 0.11);
uniform vec3 tip_color : source_color = vec3(0.56, 0.82, 0.24);
uniform float wind_speed = 2.15;
uniform float wind_strength = 0.16;
uniform float fade_begin = 30.0;
uniform float fade_end = 40.0;

varying float v_height_t;
varying float v_patch;
varying float v_fade;

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
	float dist = distance(world_origin, cam_pos);
	v_fade = 1.0 - smoothstep(fade_begin, fade_end, dist);

	v_height_t = clamp(1.0 - UV.y, 0.0, 1.0);
	v_patch = sin(world_origin.x * 0.27 + world_origin.z * 0.31) * 0.5 + 0.5;

	// Smooth dual-wave wind sway anchored cleanly at the grass root
	float phase = TIME * wind_speed + world_origin.x * 0.48 + world_origin.z * 0.36;
	float gust = sin(phase) * 0.72 + cos(phase * 1.73 + 1.1) * 0.28;
	float bend = v_height_t * v_height_t * wind_strength;
	VERTEX.x += gust * bend;
	VERTEX.z += cos(phase * 0.85) * bend * 0.55;

	// Smoothly shrink blades into the meadow near the 40m distance limit (0 alpha overdraw cost!)
	VERTEX *= v_fade;

	// Stylized upward-biased normal so meadow blades catch warm uniform afternoon sunlight
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.78));
}

void fragment() {
	if (v_fade <= 0.01) {
		discard;
	}
	vec3 tip_varied = mix(tip_color * 0.90, tip_color * 1.08, v_patch);
	ALBEDO = mix(root_color, tip_varied, smoothstep(0.0, 0.92, v_height_t));
	ROUGHNESS = 0.74;
	METALLIC = 0.0;
	BACKLIGHT = vec3(0.32, 0.46, 0.14) * v_height_t;
}
