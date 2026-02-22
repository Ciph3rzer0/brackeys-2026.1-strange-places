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

var _player: Node3D

func _ready() -> void:
	_find_player()
	print("Portal ready. Player found: ", _player != null)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func _process(_delta: float) -> void:
	if _player:
		# Calculate direction from portal to player
		var direction = (_player.global_position - global_position).normalized()
		
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
	# else:
	# 	print("No player found for portal to billboard towards.")
