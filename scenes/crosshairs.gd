extends CanvasLayer

func _ready():
	visible = false
	GameWorld.camera_mode_changed.connect(_on_camera_mode_changed)

func _on_camera_mode_changed(look: bool) -> void:
	visible = look
