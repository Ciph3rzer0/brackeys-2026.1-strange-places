extends Node

const BACKGROUND_MUSIC_FADE_DISTANCE := 7.0

var _all_portals: Array = []

var _in_mirror_world: bool = false
var _active_portal: Node3D = null
var _portal_traversal_in_progress: bool = false
var _player: Player = null
var _background_music_player: Node = null

@warning_ignore_start("unused_signal")
signal camera_mode_changed(look: bool)

func set_look_mode(look: bool) -> void:
	print("Emitting camera_mode_changed signal with look_mode: ", look)
	emit_signal("camera_mode_changed", look)

signal portal_traversal_started(mirror_world: bool)
signal portal_traversal_finished(mirror_world: bool)

func start_portal_traversal():
	if _portal_traversal_in_progress:
		print("Portal traversal already in progress. Ignoring new traversal start.")
		return

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
		assert(node not in _all_portals, "Trying to activate a portal that is already active.")
		_all_portals.append(node)
		_active_portal = node
	else:
		print("Deactivating portal: ", node.name)
		assert(node in _all_portals, "Trying to deactivate a portal that is not in the list of active portals.")
		_all_portals.erase(node)
		if _active_portal == node:
			_active_portal = null

func set_player(player: Player):
	_player = player

func set_background_music_player(music: Node):
	_background_music_player = music


func _process(_delta: float) -> void:
	if !(_player and _active_portal):
		if !_player:
			print("game_world.gd: No player set.")
		if !_active_portal:
			print("game_world.gd: No active portal.")
		return

	var pre_active_portal = _active_portal
	_active_portal = _find_closest_portal_to_camera()
	if pre_active_portal != _active_portal:
		print("Active portal changed to: ", (str(_active_portal.name) if _active_portal else "null"))
	
	var portal_to_camera = DarkWorldView.mirror_camera.global_position - _active_portal.global_position
	var distance = portal_to_camera.length()
	# Set the near frustum of DarkWorldView.mirror_camera to distance
	# This prevents objects between the camera and the portal
	# from rendering in the portal.
	DarkWorldView.mirror_camera.near = max(0.05, distance - 2)
	if DarkWorldView._portal_animating:
		DarkWorldView.mirror_camera.near = 0.05
	
	var portal_to_player_distance = (_player.global_position - _active_portal.global_position).length()
	var fade = clampf(1 - (portal_to_player_distance / BACKGROUND_MUSIC_FADE_DISTANCE), 0, 0.5)
	if _in_mirror_world:
		fade = 1 - fade
	_background_music_player.track_fade = fade

func _find_closest_portal_to_camera() -> Node3D:
	if not _player:
		return null
	var closest_portal: Node3D = null
	var closest_distance: float = INF
	for portal in _all_portals:
		var distance = portal.global_position.distance_to(_player.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_portal = portal
	return closest_portal
