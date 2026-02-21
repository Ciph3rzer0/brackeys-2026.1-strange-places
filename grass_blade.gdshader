// Grass blade shader for MultimeshInstance3D
// Wind-animated, two-sided grass blades with color variation

shader_type spatial;

render_mode skip_vertex_transform, cull_disabled, blend_mix;

uniform vec3 base_color : source_color = vec3(0.12, 0.18, 0.03);
uniform vec3 tip_color : source_color = vec3(0.30, 0.42, 0.08);
uniform float wind_strength : hint_range(0.0, 2.0) = 0.4;
uniform vec2 wind_direction = vec2(1.0, 0.5);
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float color_variation : hint_range(0.0, 1.0) = 0.15;

varying float blade_height_factor;
varying float wind_force;
varying vec2 instance_variation;

void vertex() {
	// Normalized height along the blade (0 at base, 1 at tip)
	// The quad mesh goes from -0.5 to 0.5 in Y, so remap
	blade_height_factor = clamp((VERTEX.y + 0.5), 0.0, 1.0);
	float bend_factor = blade_height_factor * blade_height_factor; // Quadratic for natural curve

	// Pinch tip — narrow the blade towards the top
	VERTEX.x *= (1.0 - blade_height_factor * 0.7);

	// World space position of this instance for wind phase offset
	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// Per-instance variation from INSTANCE_CUSTOM
	instance_variation = INSTANCE_CUSTOM.rg;

	// Wind calculation
	vec2 wind_dir = normalize(wind_direction);
	float phase = dot(world_pos.xz, wind_dir) * 0.5 + instance_variation.x * 6.28;
	float wind_wave = sin(TIME * wind_speed + phase) * 0.6
					+ sin(TIME * wind_speed * 1.7 + phase * 1.3) * 0.3
					+ sin(TIME * wind_speed * 0.4 + phase * 0.7) * 0.1;

	float force = wind_wave * wind_strength * bend_factor;

	// Apply wind displacement in world space
	vec3 w_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Lateral sway
	w_vertex.xz += wind_dir * force * 0.3;
	// Cross-wind wobble for natural look
	vec2 cross_dir = vec2(-wind_dir.y, wind_dir.x);
	float wobble = sin(TIME * 3.0 + instance_variation.y * 6.28) * 0.08 * bend_factor;
	w_vertex.xz += cross_dir * wobble;

	// Slight vertical compression when bent
	w_vertex.y -= abs(force) * 0.15;

	wind_force = abs(force);

	// Transform to view space
	VERTEX = (VIEW_MATRIX * vec4(w_vertex, 1.0)).xyz;
	NORMAL = MODELVIEW_NORMAL_MATRIX * NORMAL;
	BINORMAL = MODELVIEW_NORMAL_MATRIX * BINORMAL;
	TANGENT = MODELVIEW_NORMAL_MATRIX * TANGENT;
}

void fragment() {
	// Color gradient from base to tip
	vec3 color = mix(base_color, tip_color, blade_height_factor);

	// Per-instance color variation
	float hue_shift = (instance_variation.x - 0.5) * color_variation;
	float val_shift = (instance_variation.y - 0.5) * color_variation * 0.5;
	color.r += hue_shift * 0.15;
	color.g += hue_shift * 0.05 + val_shift * 0.1;
	color.b += hue_shift * 0.02;
	color = clamp(color, vec3(0.0), vec3(1.0));

	// Brighten tips slightly for light-catch effect
	color = mix(color, tip_color * 1.3, smoothstep(0.85, 1.0, blade_height_factor) * 0.3);

	ALBEDO = color;

	// Roughness decreases at tips / in wind (shinier highlights)
	float spec_factor = clamp(max(blade_height_factor, wind_force), 0.0, 1.0);
	ROUGHNESS = mix(0.95, 0.5, spec_factor);
	SPECULAR = clamp(spec_factor * 0.2, 0.0, 0.15);

	// Backlight for translucency when viewed against the light
	BACKLIGHT = vec3(0.25);

	// Gamma correction for compatibility renderer
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ALBEDO = pow(ALBEDO, vec3(0.4));
	#endif
}
