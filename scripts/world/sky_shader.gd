class_name DynamicSkyShader
extends RefCounted
## High-cohesion GLES3 procedural sky shader:
##   - Rayleigh/Mie horizon & zenith gradient synced with DayNightCycle
##   - Multi-octave FBM drifting volumetric-style clouds lit by sun elevation
##   - Solar disc + warm corona halo, plus twinkling night starfield & moon glow

const SKY_SHADER_CODE := """
shader_type sky;

uniform vec3 sky_top : source_color = vec3(0.14, 0.36, 0.72);
uniform vec3 sky_horizon : source_color = vec3(0.62, 0.78, 0.90);
uniform vec3 ground_color : source_color = vec3(0.20, 0.24, 0.20);
uniform vec3 cloud_bright : source_color = vec3(0.99, 0.98, 0.96);
uniform vec3 cloud_shadow : source_color = vec3(0.58, 0.65, 0.76);
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;
uniform float rain_factor : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.46;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise2d(p);
		p = p * 2.04 + vec2(17.1, 31.7);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, -1.0, 1.0);

	// Atmospheric zenith-to-horizon scattering curve
	float horizon_t = pow(1.0 - clamp(up, 0.0, 1.0), 2.35);
	vec3 col = mix(sky_top, sky_horizon, horizon_t);

	// Sun disc & golden atmospheric Mie glow
	if (LIGHT0_ENABLED) {
		float sun_dot = max(dot(dir, LIGHT0_DIRECTION), 0.0);
		float halo = pow(sun_dot, 12.0) * 0.36 * (1.0 - night_factor) * (1.0 - rain_factor * 0.8);
		float disc = smoothstep(0.9982, 0.9994, sun_dot) * (1.0 - night_factor) * (1.0 - rain_factor * 0.85);
		col += LIGHT0_COLOR * (halo + disc * 2.2);
	}

	// Twinkling procedural night stars & subtle moon glow
	if (night_factor > 0.05 && up > 0.04) {
		vec2 star_uv = dir.xz / (dir.y + 0.35) * 95.0;
		float st = hash21(floor(star_uv));
		if (st > 0.992) {
			float twinkle = 0.65 + 0.35 * sin(TIME * 2.8 + st * 90.0);
			col += vec3(0.85, 0.90, 1.0) * twinkle * night_factor * (1.0 - rain_factor) * smoothstep(0.04, 0.28, up);
		}
		if (LIGHT1_ENABLED) {
			float m_dot = max(dot(dir, LIGHT1_DIRECTION), 0.0);
			float m_disc = smoothstep(0.9986, 0.9995, m_dot);
			float m_halo = pow(m_dot, 28.0) * 0.22;
			col += vec3(0.76, 0.84, 1.0) * (m_disc * 1.4 + m_halo) * night_factor * (1.0 - rain_factor * 0.7);
		}
	}

	// Volumetric-style multi-octave drifting clouds above the horizon
	if (up > 0.02) {
		vec2 cuv = dir.xz / (dir.y + 0.22) * 1.35 + vec2(TIME * 0.011, TIME * 0.004);
		float n = fbm(cuv);
		float n_lit = fbm(cuv + LIGHT0_DIRECTION.xz * 0.14);
		float cov = mix(cloud_coverage, 0.82, rain_factor);
		float mask = smoothstep(1.0 - cov, 1.0 - cov + 0.26, n) * smoothstep(0.02, 0.18, up);
		float rim = clamp((n - n_lit) * 3.0 + 0.55, 0.0, 1.0);
		vec3 c_col = mix(cloud_shadow, cloud_bright, rim);
		c_col = mix(c_col, vec3(0.16, 0.20, 0.30), night_factor * 0.78);
		c_col = mix(c_col, vec3(0.42, 0.46, 0.52), rain_factor * 0.65);
		col = mix(col, c_col, mask * 0.86);
	}

	// Ground hemisphere blend
	if (up < 0.0) {
		col = mix(sky_horizon * 0.78, ground_color, clamp(-up * 3.2, 0.0, 1.0));
	}

	COLOR = col;
}
"""

static func create_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SKY_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
