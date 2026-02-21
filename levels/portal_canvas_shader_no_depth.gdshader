shader_type spatial;
render_mode unshaded, ambient_light_disabled, fog_disabled, cull_disabled, depth_test_disabled;

uniform sampler2D mirror_texture;

void fragment() {
    // Get the screen-space coordinates of the pixel
    vec2 screen_uv = SCREEN_UV;
    
    // Sample the SubViewport texture (the mirror world)
    vec3 mirror_color = texture(mirror_texture, screen_uv).rgb;
    
    ALBEDO = mirror_color;
}