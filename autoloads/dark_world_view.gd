extends SubViewport

@export var PORTAL_RESOLUTION_SCALE: float = 0.5

var primary_camera: Camera3D
@onready var mirror_camera: Camera3D = $MirrorCamera3D

var _portal_animating: bool = false
var _initial_primary_cull_mask: int = 0
var _initial_mirror_cull_mask: int = 0
var _initial_primary_fov: float = 0.0
var _initial_primary_near: float = 0.0
var _initial_primary_far: float = 0.0
var _initial_mirror_fov: float = 0.0
var _initial_mirror_near: float = 0.0
var _initial_mirror_far: float = 0.0
var _initial_primary_environment: Environment
var _initial_mirror_environment: Environment
var _has_initial_primary_state: bool = false
var _has_initial_mirror_state: bool = false

func _ready() -> void:
	# Disable tonemapping in SubViewport to prevent double tonemapping
	# The SubViewport should output linear HDR, then the main viewport applies tonemapping
	if mirror_camera and mirror_camera.environment:
		var viewport_env = mirror_camera.environment.duplicate()
		viewport_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		mirror_camera.environment = viewport_env

	_capture_mirror_initial_state()
	
	# Match SubViewport size to main viewport
	_update_viewport_size()

	GameWorld.portal_traversal_started.connect(_on_portal_traversal_started)
	GameWorld.portal_traversal_finished.connect(_on_portal_traversal_finished)

func _on_portal_traversal_started(mirror_world: bool) -> void:
	_portal_animating = true
	print("Portal traversal started. Mirror world: ", mirror_world)

func _on_portal_traversal_finished(_mirror_world) -> void:
	_portal_animating = false
	_switch_cameras()

func _update_viewport_size() -> void:
	var main_viewport = get_tree().root
	if main_viewport:
		size = main_viewport.size * PORTAL_RESOLUTION_SCALE

func set_primary_camera(camera: Camera3D) -> void:
	reset()
	primary_camera = camera
	if primary_camera and mirror_camera:
		mirror_camera.fov = primary_camera.fov
		mirror_camera.near = primary_camera.near
		mirror_camera.far = primary_camera.far

func _process(_delta: float) -> void:
	if primary_camera and mirror_camera:
		mirror_camera.global_transform = primary_camera.global_transform
	
	_update_viewport_size()

func _switch_cameras() -> void:
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

func _capture_mirror_initial_state() -> void:
	if not mirror_camera:
		return

	_initial_mirror_cull_mask = mirror_camera.cull_mask
	_initial_mirror_fov = mirror_camera.fov
	_initial_mirror_near = mirror_camera.near
	_initial_mirror_far = mirror_camera.far
	if mirror_camera.environment:
		_initial_mirror_environment = mirror_camera.environment.duplicate()
	else:
		_initial_mirror_environment = null
	_has_initial_mirror_state = true


func reset() -> void:
	_portal_animating = false

	if _has_initial_primary_state and primary_camera:
		primary_camera.cull_mask = _initial_primary_cull_mask
		primary_camera.fov = _initial_primary_fov
		primary_camera.near = _initial_primary_near
		primary_camera.far = _initial_primary_far
		if _initial_primary_environment:
			primary_camera.environment = _initial_primary_environment.duplicate()
		else:
			primary_camera.environment = null

	if _has_initial_mirror_state and mirror_camera:
		mirror_camera.cull_mask = _initial_mirror_cull_mask
		mirror_camera.fov = _initial_mirror_fov
		mirror_camera.near = _initial_mirror_near
		mirror_camera.far = _initial_mirror_far
		if _initial_mirror_environment:
			mirror_camera.environment = _initial_mirror_environment.duplicate()
		else:
			mirror_camera.environment = null
