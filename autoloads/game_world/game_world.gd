extends Node

var _in_mirror_world: bool = false
var _active_portal: Node3D = null
var _portal_traversal_in_progress: bool = false
var _player: Player = null

@warning_ignore_start("unused_signal")
signal portal_traversal_started(mirror_world: bool)
signal portal_traversal_finished(mirror_world: bool)

func start_portal_traversal():
	print("Start Portal Traversal --- Emitting signal.")
	_in_mirror_world = !_in_mirror_world
	_portal_traversal_in_progress = true
	portal_traversal_started.emit(_in_mirror_world)

func finish_portal_traversal():
	print("Finishing Portal Traversal --- Emitting signal.")
	_portal_traversal_in_progress = false
	portal_traversal_finished.emit(_in_mirror_world)

func set_active_portal(node: Node3D, should_enable: bool):
	if should_enable:
		print("Setting active portal to: ", node.name)
		_active_portal = node
	else:
		print("Deactivating portal: ", node.name)
		if _active_portal == node:
			_active_portal = null

func set_player(player: Player):
	_player = player


func _process(_delta: float) -> void:
	if _player and _active_portal:
		var portal_to_player = DarkWorldView.mirror_camera.global_position - _active_portal.global_position
		var distance = portal_to_player.length()
		# Set the near frustum of DarkWorldView.mirror_camera to distance
		# This prevents objects between the camera and the portal
		# from rendering in the portal.
		DarkWorldView.mirror_camera.near = max(0.05, distance - 2)
		if DarkWorldView._portal_animating:
			DarkWorldView.mirror_camera.near = 0.05
