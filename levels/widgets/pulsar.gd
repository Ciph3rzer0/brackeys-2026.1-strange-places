extends Node3D

@export var mesh: MeshInstance3D

var _strangeness: float = 0.0

# func _ready() -> void:
# 	_setup_material()

# func _setup_material() -> void:
	# if mesh and mesh.material_override == null:
	# 	var material = StandardMaterial3D.new()
	# 	material.grow = true
	# 	material.grow_amount = 0.0
	# 	mesh.material_override = material

func get_stranger(delta: float) -> void:
	_set_strangeness(min(1.5, _strangeness + delta))


func _process(delta: float) -> void:
	_set_strangeness(max(0, _strangeness - delta * 0.5))
	# print("Setting strangeness to: ", _strangeness)


func _set_strangeness(value: float) -> void:
	_strangeness = value

	var material: StandardMaterial3D = mesh.get_surface_override_material(0)

	if material:
		# Enable grow if it isn't already
		if not material.grow:
			material.grow = true
		
		var a = sin(Time.get_ticks_msec() * 0.004) * 0.9
		var b = sin(Time.get_ticks_msec() * 0.01) * 0.15 
		var c = (cos(a) + cos(b) - sin(a + b)) / 20
		
		var z = sin(_strangeness * 0.01) * 0.15
		var y = sin(_strangeness * 0.0021) * 0.75
		var x = (cos(z) - cos(y) + sin(z + y)) / 20

		var stencil_thickness = _strangeness * 0.02 + (c + x) / 4 - 0.034
		material.set("stencil_outline_thickness", max(0, stencil_thickness))
		material.grow_amount = 0 + cos(Time.get_ticks_msec() * 0.0031) * _strangeness / 140

	# # Update the mesh outline based on the new strangeness value.
	# if mesh and mesh.material_override:
	# 	mesh.material_override.grow_amount = _strangeness * 10.1
	# 	mesh.material_override.
