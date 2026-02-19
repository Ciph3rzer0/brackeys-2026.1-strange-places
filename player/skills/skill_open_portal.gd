extends Node

const PORTAL = preload("uid://cu1hypoa4fiqw")

var _portal : Node3D = null
var _open_portal_progress := 0.0

func _ready():
	_portal = PORTAL.instantiate()
	# Add to scene root so it doesn't follow the player
	# Use call_deferred since parent is busy during _ready()
	get_tree().current_scene.call_deferred("add_child", _portal)
	_portal.global_position = get_parent().global_position + get_parent().global_transform.basis.z * 3

	print("Portal instance created: ", _portal)
	# Note: will be false until next frame when deferred call executes
	print("Portal instance tree: ", _portal.is_inside_tree())
	GameWorld.portal_traversal_started.connect(func(_mirror_world: bool):
		print("Portal traversal finished. Resetting portal progress.")
		_open_portal_progress = 0.0
	)


func _process(delta: float) -> void:
	if not GameWorld._portal_traversal_in_progress:
		if Input.is_action_pressed("pc_open_portal"):
			_open_portal_progress = min(3, _open_portal_progress + delta)
		else:
			_open_portal_progress = max(0, _open_portal_progress - delta * 2.0)
	
	var EASE = 0.15
	var portal_scale = ease(_open_portal_progress * 1.0 / 2, EASE) * 2
	# var portal_scale = _open_portal_progress
	
	_portal.set_portal_open_progress(portal_scale)
