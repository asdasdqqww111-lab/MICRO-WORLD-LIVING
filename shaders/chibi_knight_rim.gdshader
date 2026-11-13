shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float armor_metallic : hint_range(0.0, 1.0) = 0.8;
uniform float armor_roughness : hint_range(0.05, 1.0) = 0.3;
uniform vec3 hair_brown : source_color = vec3(0.34, 0.20, 0.11);
uniform vec3 rim_color : source_color = vec3(1.0, 0.86, 0.48);
uniform float rim_power : hint_range(1.0, 8.0) = 2.8;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.50;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	vec3 col = tex.rgb * tint_color;

	// KayKit knight_texture.png swatch [col 1, row 0] (UV.x 0.125..0.25, UV.y 0.0..0.25) is Knight_Head hair!
	float is_hair = step(0.126, UV.x) * step(UV.x, 0.249) * step(0.0, UV.y) * step(UV.y, 0.249);
	float hair_shade = clamp(dot(tex.rgb, vec3(0.333)) * 1.35, 0.55, 1.22);
	col = mix(col, hair_brown * hair_shade, is_hair);

	// Steel plate swatches on knight_texture.png have low saturation & medium-high luminance
	float cmax = max(col.r, max(col.g, col.b));
	float cmin = min(col.r, min(col.g, col.b));
	float sat = (cmax > 0.001) ? ((cmax - cmin) / cmax) : 0.0;
	float armor_mask = (1.0 - is_hair) * (1.0 - smoothstep(0.14, 0.28, sat)) * smoothstep(0.20, 0.38, cmax);

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);

	ALBEDO = mix(col, col * vec3(1.05, 1.06, 1.10), armor_mask);
	METALLIC = mix(0.04, armor_metallic, armor_mask);
	ROUGHNESS = mix(mix(0.66, 0.46, is_hair), armor_roughness, armor_mask);
	EMISSION = rim_color * fresnel * rim_intensity;
}
