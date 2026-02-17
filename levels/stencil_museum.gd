extends Node3D

var _open_portal_progress := 0.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("pc_open_portal"):
		_open_portal_progress = min(3, _open_portal_progress + delta)
	else:
		_open_portal_progress = max(0, _open_portal_progress - delta * 2.0)
	
	var EASE = 0.15
	var portal_scale = ease(_open_portal_progress * 1.0 / 2, EASE) * 2
	# var portal_scale = _open_portal_progress
	
	%Portal.set_portal_open_progress(portal_scale)
