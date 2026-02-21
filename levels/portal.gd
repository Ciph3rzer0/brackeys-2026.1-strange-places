extends Node3D

var _player: Node3D
var _camera: Camera3D

var _front_portal_contact: bool = false
var _back_portal_contact: bool = false
var _is_animating: bool = false
var _original_fade_position: Vector3
var _original_fade_rotation: Vector3
var _last_collision_enabled: bool = true

@onready var _portal_screen_fade: Node3D = %PortalScreenFade
@onready var _portal_screen_fade_anim_player = %PortalScreenFadeAnimationPlayer


func set_portal_open_progress(val: float):
	var size =  Vector3.ONE * max(0.001, val)
	$PortalHole.scale = size
	%TraversalDetectors.scale = Vector3(size.x, size.y, 1.0)
	# Only update collision when state changes
	var should_enable = val > 0.001
	if should_enable != _last_collision_enabled:
		_last_collision_enabled = should_enable
		_set_collision_recursive($PortalHole, should_enable)
		_set_collision_recursive($TraversalDetectors, should_enable)
		%RingParticles.emitting = should_enable
		GameWorld.set_active_portal(self, should_enable)

func _set_collision_recursive(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = !enabled
	for child in node.get_children():
		_set_collision_recursive(child, enabled)

func _ready() -> void:
	GameWorld.set_active_portal(self, true)
	_find_player()
	_find_camera()

func _find_camera() -> void:
	# Find the main camera
	var camera_node = get_tree().root.find_child("MainCamera3D", true, false)
	if camera_node and camera_node is Camera3D:
		_camera = camera_node

func _find_player() -> void:
	# Try to find player by group or common name
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
	else:
		# Fallback: try to find by name
		_player = get_tree().root.find_child("Player*", true, false)

func _process(_delta: float) -> void:
	# During animation, position PortalScreenFade in front of camera
	if _is_animating and _camera and _portal_screen_fade:
		# Get animation progress
		var progress = 0.0
		if _portal_screen_fade_anim_player.is_playing():
			var current_time = _portal_screen_fade_anim_player.current_animation_position
			var total_time = _portal_screen_fade_anim_player.current_animation_length / 2
			progress = clamp(current_time / total_time, 0.0, 1.0)
		
		# Lerp between portal position and camera position
		var distance_from_camera = 4.0  # Distance in front of camera at full progress
		var camera_forward = -_camera.global_transform.basis.z
		var target_position = _camera.global_position + camera_forward * distance_from_camera
		
		# Use global_position for interpolation
		var portal_world_pos = _portal_screen_fade.get_parent().global_position + _original_fade_position
		_portal_screen_fade.global_position = portal_world_pos.lerp(target_position, progress)
		# _portal_screen_fade.global_position = target_position
		_portal_screen_fade.look_at(_camera.global_position, Vector3.UP)


func _on_player_detect_f_body_entered(_body: Node3D) -> void:
	# print("Player entered front portal area.")
	_front_portal_contact = true


func _on_player_detect_f_body_exited(_body: Node3D) -> void:
	# print("Player exited front portal area.")
	_front_portal_contact = false
	if _back_portal_contact:
		print("Player should be teleported now! (Entered F, then B)")
		_teleport_player()


func _on_player_detect_b_body_entered(_body: Node3D) -> void:
	# print("Player entered back portal area.")
	_back_portal_contact = true


func _on_player_detect_b_body_exited(_body: Node3D) -> void:
	# print("Player exited back portal area.")
	_back_portal_contact = false
	if _front_portal_contact:
		print("Player should be teleported now! (Entered B, then F)")
		_teleport_player()


func _teleport_player() -> void:
	GameWorld.start_portal_traversal()
	# Store original PortalScreenFade transform
	if _portal_screen_fade:
		_original_fade_position = _portal_screen_fade.position
		_original_fade_rotation = _portal_screen_fade.rotation
	# Make PortalScreenFade follow camera during animation
	_is_animating = true
	_portal_screen_fade_anim_player.play(&"expand")

func _on_portal_expansion_finished() -> void:
	GameWorld.finish_portal_traversal()
	print("Portal expansion finished. Now switching cameras.")
	_is_animating = false
	# Reset PortalScreenFade to original transform
	if _portal_screen_fade:
		_portal_screen_fade.position = _original_fade_position
		_portal_screen_fade.rotation = _original_fade_rotation
