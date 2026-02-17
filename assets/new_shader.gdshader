shader_type spatial;

// Uniforms for controlling the fluid simulation
uniform float slosh_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float wave_amplitude : hint_range(0.0, 0.5) = .1;
uniform float surface_band : hint_range(0.0, 1.0) = 0.1;
uniform vec4 fluid_color : source_color = vec4(0.2, 0.5, 0.8, 0.8);
uniform vec4 surface_color : source_color = vec4(0.8, 0.9, 1.0, 0.9);
uniform float sphere_radius = .1;
uniform float fill_level = .2;
uniform float wave_frequency = .1;
uniform float wave_speed = .5;
uniform vec2 slosh_direction = vec2(2.0, 1.0);

// Varying variables to pass data from vertex to fragment shader
varying float v_wave;
varying float v_is_capped;
varying float v_dist_from_surface;

void vertex() {
	// Get world position of the vertex
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 object_center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 relative_world_pos = world_pos - object_center;

	// Calculate fill level in world space
	// We assume sphere_radius is the local radius, so we need to account for scale if we want world units.
	// However, usually sphere_radius is 1.0 or similar. 
	// Let's use the local radius scaled by the object's average scale for the world radius approximation.
	float world_scale = length(MODEL_MATRIX[0].xyz); // Approximate scale from X axis
	float world_radius = sphere_radius * world_scale;
	
	float relative_y = relative_world_pos.y;
	float fill_threshold = mix(-world_radius, world_radius, fill_level);

	// Wave calculation in world space
	float wave = sin(world_pos.x * wave_frequency + TIME * wave_speed) *
				 cos(world_pos.z * wave_frequency * 0.7 + TIME * wave_speed * 0.8);
	
	// Slosh calculation
	float local_offset = dot(relative_world_pos.xz, normalize(slosh_direction)) * slosh_intensity + wave * wave_amplitude;
	float surface_height = fill_threshold + local_offset;

	v_wave = wave;
	v_is_capped = 0.0;

	// Check if vertex is above the fluid surface
	if (relative_y > surface_height) {
		v_is_capped = 1.0;
		
		// Banding and slosh direction visual fix
		vec2 bandingOffset = vec2(max(abs(slosh_direction.x), 0.0001)*sign(slosh_direction.x), max(abs(slosh_direction.y)*sign(slosh_direction.y), 0.0001));
		vec2 world_xz_dir = normalize(relative_world_pos.xz - bandingOffset * 0.0001);
		
		// Calculate the radius of the liquid surface at the current fill level
		// This assumes a spherical container logic
		float h = clamp(surface_height / world_radius, -1.0, 1.0);
		float base_cap_radius = world_radius * sqrt(1.0 - h * h);
		vec2 dest_world_xz = world_xz_dir * base_cap_radius;
		
		// Recalculate wave at destination
		float dest_world_wave = sin((object_center.x + dest_world_xz.x) * wave_frequency + TIME * wave_speed) *
						  cos((object_center.z + dest_world_xz.y) * wave_frequency * 0.7 + TIME * wave_speed * 0.8);
						  
		float dest_offset = dot(dest_world_xz, normalize(slosh_direction)) * slosh_intensity + dest_world_wave * wave_amplitude;
		float capped_y = fill_threshold + dest_offset;
		
		// Construct the flattened vertex in World Relative space
		vec3 candidate_relative_world = vec3(dest_world_xz.x, capped_y, dest_world_xz.y);
		
		// Transform back to local space using the inverse of the Model Matrix
		// Note: We only need the 3x3 linear part for the vector, but since we are transforming a position
		// relative to the center, we are good.
		VERTEX = (inverse(mat3(MODEL_MATRIX)) * candidate_relative_world);
		
		v_wave = dest_world_wave;
	}
	
	v_dist_from_surface = surface_height - relative_y;
}
 
void fragment() {
	float surface_factor = 0.0;
	if (v_is_capped > 0.5) {
		surface_factor = smoothstep(0.6, 1.0, abs(v_wave));
	} else {
		surface_factor = 1.0 - smoothstep(0.0, surface_band, v_dist_from_surface);
	}
 
	vec4 final_color = mix(fluid_color, surface_color, surface_factor);
	float emission_strength = v_is_capped > 0.5 ? 0.2 + v_wave * 0.1 : 0.1;
 
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	EMISSION = fluid_color.rgb * emission_strength;
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.9;
}