@tool
extends Node3D
## Scatters environment prop meshes (trees, rocks, bushes) using MultiMeshInstance3D.
## Attach to a Node3D in the scene. It creates child MultiMeshInstance3D nodes at _ready().

## ──────── Scatter Area ────────

## Centre of the scatter rectangle in world XZ
@export var scatter_center := Vector2(-24.0, 91.0)

## Half-extents of the scatter rectangle (X and Z)
@export var scatter_half_extents := Vector2(80.0, 100.0)

## Random seed for reproducible placement
@export var scatter_seed: int = 12345

## Ground Y position in world space
@export var ground_y: float = -5.3

## Rebuild all props when toggled in the editor
@export var regenerate: bool = false: set = _set_regenerate


## ──────── Exclusion Zones ────────
## Each Vector3 = (world_x, world_z, radius)
@export var exclusion_zones: Array[Vector3] = [
	Vector3(106.8, 82.3, 15.0), # cabin
	Vector3(-6.14, -12.9, 8.0), # shack
	Vector3(-124.0, 252.0, 30.0), # cathedral
	Vector3(63.0, 102.2, 5.0), # bonfire
]


## ──────── Prop Definitions ────────
## Stored as a simple inner class so we can cleanly loop over them.

class PropDef:
	var mesh_path: String
	var count: int
	var min_scale: float
	var max_scale: float
	var y_offset: float # vertical nudge so base sits on ground

	func _init(p: String, c: int, smin: float, smax: float, yoff: float = 0.0):
		mesh_path = p
		count = c
		min_scale = smin
		max_scale = smax
		y_offset = yoff


func _get_prop_defs() -> Array:
	return [
		PropDef.new("res://assets/environment/conical-tree.glb", 50, 0.8, 1.6, 0.0),
		PropDef.new("res://assets/environment/round-tree.glb", 20, 0.9, 1.5, 0.0),
		PropDef.new("res://assets/environment/spreading-tree.glb", 10, 0.7, 1.3, 0.0),
		PropDef.new("res://assets/environment/bush.glb", 40, 0.6, 1.2, 0.0),
		PropDef.new("res://assets/environment/rock-large.glb", 6, 0.8, 1.4, -0.3),
		PropDef.new("res://assets/environment/rock-medium_1.glb", 15, 0.7, 1.3, -0.15),
		PropDef.new("res://assets/environment/rock-medium_2.glb", 15, 0.7, 1.3, -0.15),
		PropDef.new("res://assets/environment/rock-small.glb", 30, 0.5, 1.0, -0.05),
	]


func _set_regenerate(value: bool) -> void:
	if value:
		_build_all()
		regenerate = false


func _ready() -> void:
	_build_all()


## ──────── Main builder ────────

func _build_all() -> void:
	# Remove old children so we can rebuild cleanly
	for child in get_children():
		child.queue_free()

	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed

	for prop_def in _get_prop_defs():
		_scatter_prop(prop_def, rng)


func _scatter_prop(prop_def: PropDef, rng: RandomNumberGenerator) -> void:
	# Load the GLB scene and find its root mesh
	var scene: PackedScene = load(prop_def.mesh_path)
	if scene == null:
		push_warning("mesh_scatter: could not load " + prop_def.mesh_path)
		return

	var mesh := _extract_mesh_from_scene(scene)
	if mesh == null:
		push_warning("mesh_scatter: no MeshInstance3D found in " + prop_def.mesh_path)
		return

	# Build MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = prop_def.count
	mm.mesh = mesh

	# Generate transform for each instance
	var placed := 0
	var max_attempts := prop_def.count * 10 # avoid infinite loop
	var attempts := 0

	while placed < prop_def.count and attempts < max_attempts:
		attempts += 1

		var x := rng.randf_range(
			scatter_center.x - scatter_half_extents.x,
			scatter_center.x + scatter_half_extents.x
		)
		var z := rng.randf_range(
			scatter_center.y - scatter_half_extents.y,
			scatter_center.y + scatter_half_extents.y
		)

		# Check exclusion zones
		if _in_exclusion_zone(x, z):
			continue

		var rot_y := rng.randf_range(0.0, TAU)
		var s := rng.randf_range(prop_def.min_scale, prop_def.max_scale)

		var basis := Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s))
		var origin := Vector3(x, ground_y + prop_def.y_offset, z)
		# Positions are in world space; convert to local space of this node
		var world_xform := Transform3D(basis, origin)
		var local_xform := global_transform.affine_inverse() * world_xform
		mm.set_instance_transform(placed, local_xform)
		placed += 1

	# If we couldn't place all, shrink the instance count
	if placed < prop_def.count:
		mm.instance_count = placed

	# Create the MultiMeshInstance3D child
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	# Give it a readable name based on the mesh file
	var base_name := prop_def.mesh_path.get_file().get_basename()
	mmi.name = base_name.capitalize().replace(" ", "")
	add_child(mmi)
	if Engine.is_editor_hint():
		mmi.owner = get_tree().edited_scene_root


func _in_exclusion_zone(x: float, z: float) -> bool:
	for zone in exclusion_zones:
		var dx := x - zone.x
		var dz := z - zone.y
		if dx * dx + dz * dz < zone.z * zone.z:
			return true
	return false


## Walk a scene tree to find the first Mesh resource inside a MeshInstance3D.
func _extract_mesh_from_scene(scene: PackedScene) -> Mesh:
	var instance := scene.instantiate()
	var mesh := _find_mesh_recursive(instance)
	instance.queue_free()
	return mesh


func _find_mesh_recursive(node: Node) -> Mesh:
	if node is MeshInstance3D and node.mesh != null:
		return node.mesh
	for child in node.get_children():
		var m := _find_mesh_recursive(child)
		if m != null:
			return m
	return null
