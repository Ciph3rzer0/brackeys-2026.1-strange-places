// Ground De-Tiling Shader
// Breaks up visible texture repetition using rotated UV sampling,
// multi-scale blending, and procedural noise variation.

shader_type spatial;

// Ground textures
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;

// Material properties
uniform float metallic_specular : hint_range(0.0, 1.0) = 0.46;
uniform float roughness : hint_range(0.0, 1.0) = 0.97;
uniform float normal_scale : hint_range(-2.0, 2.0) = 0.37;

// De-tiling controls
uniform float uv_scale : hint_range(0.1, 50.0) = 1.0;
uniform float detile_strength : hint_range(0.0, 10.0) = 0.6;
uniform float color_variation : hint_range(0.0, 0.4) = 0.08;
uniform float brightness_variation : hint_range(0.0, 0.3) = 0.06;

// --- Procedural noise helpers ---

// Simple 2D hash → vec2 for rotation angles and offsets
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Value noise for smooth variation
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = dot(hash2(i + vec2(0.0, 0.0)), vec2(1.0));
	float b = dot(hash2(i + vec2(1.0, 0.0)), vec2(1.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), vec2(1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), vec2(1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for natural-looking noise
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p *= 2.17;
		amplitude *= 0.5;
	}
	return value;
}

// Rotate UV by angle in radians
vec2 rotate_uv(vec2 uv, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

// --- De-tiling core: sample texture with per-cell random rotation ---
// Based on the technique from "Procedural Stochastic Textures by Tiling and Blending"
// Each tile cell rotates and offsets the UV, then blends across cell boundaries.
vec4 sample_detiled(sampler2D tex, vec2 uv) {
	// The tile cell this UV falls in
	vec2 cell = floor(uv);
	vec2 local = fract(uv);

	// Smooth blend weights for the 4 surrounding cells
	vec2 w = local * local * (3.0 - 2.0 * local);

	vec4 result = vec4(0.0);

	for (int dy = 0; dy <= 1; dy++) {
		for (int dx = 0; dx <= 1; dx++) {
			vec2 neighbor = cell + vec2(float(dx), float(dy));
			vec2 h = hash2(neighbor);

			// Per-cell random rotation (0, 90, 180, or 270 degrees for seamlessness)
			float angle = floor(h.x * 4.0) * 1.5707963; // PI/2

			// Per-cell random offset
			vec2 offset = h * 0.5;

			// Rotated + offset UV relative to the cell
			vec2 sample_uv = rotate_uv(uv - neighbor + offset, angle) + neighbor;

			// Bilinear blend weight
			float wx = (dx == 0) ? (1.0 - w.x) : w.x;
			float wy = (dy == 0) ? (1.0 - w.y) : w.y;

			result += texture(tex, sample_uv) * wx * wy;
		}
	}

	return result;
}

void fragment() {
	vec2 base_uv = UV * uv_scale;

	// World-space position for noise lookups
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 world_uv = world_pos.xz;

	// --- Blend factor from noise: controls where we use detiled vs. straight sampling ---
	float blend = smoothstep(0.3, 0.7, fbm(world_uv * 0.37));

	// Sample 1: standard tiled
	vec4 albedo_a = texture(albedo_texture, base_uv);
	vec3 normal_a = texture(normal_texture, base_uv).rgb;

	// Sample 2: de-tiled (rotated per cell)
	vec4 albedo_b = sample_detiled(albedo_texture, base_uv);
	vec3 normal_b = sample_detiled(normal_texture, base_uv).rgb;

	// Mix based on noise-driven blend
	float mix_factor = blend * detile_strength;
	vec3 final_albedo = mix(albedo_a.rgb, albedo_b.rgb, mix_factor);
	vec3 final_normal = mix(normal_a, normal_b, mix_factor);

	// --- Secondary large-scale color variation ---
	float large_noise = fbm(world_uv * 0.13);
	float detail_noise = fbm(world_uv * 0.7);
	float combined_noise = large_noise * 0.7 + detail_noise * 0.3;

	// Subtle hue/brightness shift
	final_albedo *= 1.0 + (combined_noise - 0.5) * brightness_variation * 2.0;
	final_albedo.g += (combined_noise - 0.5) * color_variation; // greenish variation
	final_albedo.r -= (combined_noise - 0.5) * color_variation * 0.3; // less red in green spots
	final_albedo = clamp(final_albedo, vec3(0.0), vec3(1.0));

	ALBEDO = final_albedo;
	METALLIC = 0.0;
	SPECULAR = metallic_specular;
	ROUGHNESS = roughness;
	NORMAL_MAP = final_normal;
	NORMAL_MAP_DEPTH = normal_scale;
}
