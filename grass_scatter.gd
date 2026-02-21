@tool
extends MultiMeshInstance3D
## Scatters grass blades across the ground plane at _ready() or in-editor.
## Attach this to a MultimeshInstance3D node.

## Total number of grass blade instances
@export var instance_count: int = 6000

## Half-width of the XZ scatter area (blades spawn in [-scatter_extent, scatter_extent])
@export var scatter_extent: float = 6.5

## Minimum blade height scale
@export var min_height: float = 0.7

## Maximum blade height scale
@export var max_height: float = 1.4

## Base width of each blade quad
@export var blade_width: float = 0.04

## Base height of each blade quad
@export var blade_height: float = 0.2

## Random seed for reproducible scatter
@export var scatter_seed: int = 42

## If true, regenerate instances when any export changes in-editor
@export var regenerate: bool = false: set = _set_regenerate


func _set_regenerate(value: bool) -> void:
	if value:
		_generate_grass()
		regenerate = false


func _ready() -> void:
	_generate_grass()


func _generate_grass() -> void:
	# Create the blade mesh — a simple quad
	# Keep default center so VERTEX.y spans [-0.5, 0.5] for shader math
	var quad := QuadMesh.new()
	quad.size = Vector2(blade_width, blade_height)

	# Create MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.instance_count = instance_count
	mm.mesh = quad

	# Seed the RNG
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed

	for i in range(instance_count):
		# Random XZ position
		var x := rng.randf_range(-scatter_extent, scatter_extent)
		var z := rng.randf_range(-scatter_extent, scatter_extent)

		# Random Y rotation
		var rot_y := rng.randf_range(0.0, TAU)

		# Random height scale
		var h_scale := rng.randf_range(min_height, max_height)

		# Build transform
		var basis := Basis(Vector3.UP, rot_y)
		# Scale: keep X uniform, vary Y (height), keep Z uniform
		basis = basis.scaled(Vector3(1.0, h_scale, 1.0))

		# Shift Y up so blade base sits on the ground
		var y_offset := blade_height * 0.5 * h_scale
		var xform := Transform3D(basis, Vector3(x, y_offset, z))
		mm.set_instance_transform(i, xform)

		# Custom data: RG = per-instance variation (for color/phase), BA = reserved
		var custom := Color(
			rng.randf(), # R — color/wind phase variation
			rng.randf(), # G — additional variation
			0.0, # B — reserved
			1.0 # A — reserved (scale signal for shader)
		)
		mm.set_instance_custom_data(i, custom)

	multimesh = mm
