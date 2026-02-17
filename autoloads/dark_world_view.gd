extends SubViewport

var primary_camera: Camera3D
@onready var mirror_camera: Camera3D = $MirrorCamera3D

func set_primary_camera(camera: Camera3D) -> void:
	print("Setting primary camera in DarkWorldView: ", camera)
	primary_camera = camera
	if primary_camera and has_node("Camera3D"):
		print("Setting up camera properties in DarkWorldView")
		var viewport_camera = get_node("Camera3D")
		viewport_camera.fov = primary_camera.fov
		viewport_camera.near = primary_camera.near
		viewport_camera.far = primary_camera.far

func _process(_delta: float) -> void:
	print("primary_camera: ", primary_camera)
	print("Has Camera3D node: ", has_node("Camera3D"))
	if primary_camera and mirror_camera:
		print("Updating camera transform in DarkWorldView")
		mirror_camera.global_transform = primary_camera.global_transform

func switch_cameras() -> void:
	print ("Prmary camera: ", primary_camera, " Mirror camera: ", mirror_camera)
	if primary_camera and mirror_camera:
		# Swap camera cull masks
		var temp_mask = primary_camera.cull_mask
		primary_camera.cull_mask = mirror_camera.cull_mask
		mirror_camera.cull_mask = temp_mask

		# XOR to flip layer 15.  Which displays the portal
		var layer_15_mask = 1 << 14  # Layer 15 (0-indexed as bit 14)
		primary_camera.cull_mask ^= layer_15_mask
		mirror_camera.cull_mask ^= layer_15_mask
		
		print("Swapped camera cull masks: primary=", primary_camera.cull_mask, " mirror=", mirror_camera.cull_mask)
