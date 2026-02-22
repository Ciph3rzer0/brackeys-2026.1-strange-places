extends MeshInstance3D

enum FaceAxis {
	POSITIVE_X,
	NEGATIVE_X,
	POSITIVE_Y,
	NEGATIVE_Y,
	POSITIVE_Z,
	NEGATIVE_Z
}

@export var facing_axis: FaceAxis = FaceAxis.POSITIVE_Y
@export var billboard_y_only: bool = false

var _camera: Camera3D

func _ready() -> void:
	_find_camera()

func _find_camera() -> void:
	_camera = get_tree().root.find_child("MainCamera3D", true, false)
	#assert(_camera != null, "No camera found in scene for LookAtCamera script.")
	
func _process(_delta: float) -> void:
	if _camera:
		# Preserve current scale
		var current_scale = scale
		
		# Calculate direction from object to camera
		var direction = (_camera.global_position - global_position).normalized()
		
		# If billboard_y_only, flatten direction to XZ plane
		if billboard_y_only:
			direction.y = 0
			direction = direction.normalized()
			if direction.length_squared() < 0.001:
				return  # Too close or directly above/below
		
		# Get the axis direction based on selection
		var target_axis: Vector3
		match facing_axis:
			FaceAxis.POSITIVE_X:
				target_axis = direction
				var forward = target_axis.cross(Vector3.UP)
				if forward.length_squared() < 0.001:
					forward = target_axis.cross(Vector3.FORWARD)
				forward = forward.normalized()
				var up = forward.cross(target_axis).normalized()
				if billboard_y_only:
					up = Vector3.UP
					forward = target_axis.cross(up).normalized()
				global_transform.basis = Basis(target_axis, up, forward)
				scale = current_scale
			FaceAxis.NEGATIVE_X:
				target_axis = -direction
				var forward = target_axis.cross(Vector3.UP)
				if forward.length_squared() < 0.001:
					forward = target_axis.cross(Vector3.FORWARD)
				forward = forward.normalized()
				var up = forward.cross(target_axis).normalized()
				if billboard_y_only:
					up = Vector3.UP
					forward = target_axis.cross(up).normalized()
				global_transform.basis = Basis(target_axis, up, forward)
				scale = current_scale
			FaceAxis.POSITIVE_Y:
				target_axis = direction
				var right = target_axis.cross(Vector3.FORWARD)
				if right.length_squared() < 0.001:
					right = target_axis.cross(Vector3.RIGHT)
				right = right.normalized()
				var forward = right.cross(target_axis).normalized()
				if billboard_y_only:
					# For Y axis pointing at player with billboard_y, keep object upright
					# We need to adjust so Y points horizontally at player
					right = Vector3.UP.cross(target_axis).normalized()
					if right.length_squared() < 0.001:
						right = Vector3.RIGHT
					forward = target_axis.cross(right).normalized()
				global_transform.basis = Basis(right, target_axis, forward)
				scale = current_scale
			FaceAxis.NEGATIVE_Y:
				target_axis = -direction
				var right = target_axis.cross(Vector3.FORWARD)
				if right.length_squared() < 0.001:
					right = target_axis.cross(Vector3.RIGHT)
				right = right.normalized()
				var forward = right.cross(target_axis).normalized()
				if billboard_y_only:
					right = Vector3.UP.cross(target_axis).normalized()
					if right.length_squared() < 0.001:
						right = Vector3.RIGHT
					forward = target_axis.cross(right).normalized()
				global_transform.basis = Basis(right, target_axis, forward)
				scale = current_scale
			FaceAxis.POSITIVE_Z:
				target_axis = direction
				var right = Vector3.UP.cross(target_axis)
				if right.length_squared() < 0.001:
					right = Vector3.RIGHT.cross(target_axis)
				right = right.normalized()
				var up = target_axis.cross(right).normalized()
				if billboard_y_only:
					up = Vector3.UP
					right = up.cross(target_axis).normalized()
				global_transform.basis = Basis(right, up, target_axis)
				scale = current_scale
			FaceAxis.NEGATIVE_Z:
				target_axis = -direction
				var right = Vector3.UP.cross(target_axis)
				if right.length_squared() < 0.001:
					right = Vector3.RIGHT.cross(target_axis)
				right = right.normalized()
				var up = target_axis.cross(right).normalized()
				if billboard_y_only:
					up = Vector3.UP
					right = up.cross(target_axis).normalized()
				global_transform.basis = Basis(right, up, target_axis)
				scale = current_scale
	# else:
	# 	print("No player found for portal to billboard towards.")
