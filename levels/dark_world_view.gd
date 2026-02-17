extends SubViewport

var source_camera: Camera3D

func set_source_camera(camera: Camera3D) -> void:
	source_camera = camera
	if source_camera and has_node("Camera3D"):
		var viewport_camera = get_node("Camera3D")
		viewport_camera.fov = source_camera.fov
		viewport_camera.near = source_camera.near
		viewport_camera.far = source_camera.far

func _process(_delta: float) -> void:
	if source_camera and has_node("Camera3D"):
		var viewport_camera = get_node("Camera3D")
		viewport_camera.global_transform = source_camera.global_transform
	print(get_node("Camera3D").position)
