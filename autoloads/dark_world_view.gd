extends SubViewport

var primary_camera: Camera3D
@onready var mirror_camera: Camera3D = $MirrorCamera3D

func _ready() -> void:
	# Disable tonemapping in SubViewport to prevent double tonemapping
	# The SubViewport should output linear HDR, then the main viewport applies tonemapping
	if mirror_camera and mirror_camera.environment:
		var viewport_env = mirror_camera.environment.duplicate()
		viewport_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		mirror_camera.environment = viewport_env
	
	# Match SubViewport size to main viewport
	_update_viewport_size()

	GameWorld.portal_activated.connect(switch_cameras)

func _update_viewport_size() -> void:
	var main_viewport = get_tree().root
	if main_viewport:
		size = main_viewport.size

func set_primary_camera(camera: Camera3D) -> void:
	primary_camera = camera
	if primary_camera and mirror_camera:
		mirror_camera.fov = primary_camera.fov
		mirror_camera.near = primary_camera.near
		mirror_camera.far = primary_camera.far

func _process(_delta: float) -> void:
	if primary_camera and mirror_camera:
		mirror_camera.global_transform = primary_camera.global_transform
		
		# Update SubViewport size if main viewport changed (for web/window resizing)
		var main_viewport = get_tree().root
		if main_viewport and size != main_viewport.size:
			size = main_viewport.size

func switch_cameras(_mirror_world) -> void:
	if primary_camera and mirror_camera:
		# Swap camera cull masks
		var temp_mask = primary_camera.cull_mask
		primary_camera.cull_mask = mirror_camera.cull_mask
		mirror_camera.cull_mask = temp_mask

		# Swap camera environments BUT maintain mirror camera's LINEAR tonemapping
		var temp_environment = primary_camera.environment
		primary_camera.environment = mirror_camera.environment
		
		# For mirror camera, duplicate the primary's environment and force LINEAR tonemap
		if temp_environment:
			var mirror_env = temp_environment.duplicate()
			mirror_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			mirror_camera.environment = mirror_env
		else:
			mirror_camera.environment = temp_environment

		# XOR to flip layer 15.  Which displays the portal
		var layer_15_mask = 1 << 14  # Layer 15 (0-indexed as bit 14)
		primary_camera.cull_mask ^= layer_15_mask
		mirror_camera.cull_mask ^= layer_15_mask
