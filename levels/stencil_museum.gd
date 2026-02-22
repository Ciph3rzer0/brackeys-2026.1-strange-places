extends Node3D

var _open_portal_progress := 0.0

func _ready():
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
	
	var portal_scale = _open_portal_progress / 3
	# var portal_scale = _open_portal_progress
	
	%Portal.set_portal_open_progress(portal_scale)
