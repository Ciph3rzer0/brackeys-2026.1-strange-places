extends CollisionShape3D
@export var outer_radius: float = 1.0
@export var inner_radius: float = 0.3
@export var rings: int = 32
@export var ring_segments: int = 16

func _ready() -> void:
	create_torus_collision()

func create_torus_collision() -> void:
	var faces = _generate_torus_faces()
	var collision_shape = ConcavePolygonShape3D.new()
	collision_shape.set_faces(faces)
	shape = collision_shape

func _generate_torus_faces() -> PackedVector3Array:
	var faces = PackedVector3Array()
	
	for i in range(rings):
		for j in range(ring_segments):
			# Calculate indices for the quad
			var next_i = (i + 1) % rings
			var next_j = (j + 1) % ring_segments
			
			# Get the four corners of the quad
			var v1 = _get_torus_vertex(i, j)
			var v2 = _get_torus_vertex(next_i, j)
			var v3 = _get_torus_vertex(next_i, next_j)
			var v4 = _get_torus_vertex(i, next_j)
			
			# Create two triangles from the quad
			faces.append(v1)
			faces.append(v2)
			faces.append(v3)
			
			faces.append(v1)
			faces.append(v3)
			faces.append(v4)
	
	return faces

func _get_torus_vertex(ring_idx: int, segment_idx: int) -> Vector3:
	var u = float(ring_idx) / float(rings) * TAU
	var v = float(segment_idx) / float(ring_segments) * TAU
	
	var x = (outer_radius + inner_radius * cos(v)) * cos(u)
	var y = (outer_radius + inner_radius * cos(v)) * sin(u)
	var z = inner_radius * sin(v)
	
	return Vector3(x, y, z)
