extends Node3D

signal fully_strange()

const PORTAL_MAX_STRANGENESS: float = 3.0

@export var mesh: MeshInstance3D
@export var outline_color: Color = Color(1, 0.5, 0.5)
@export var fully_strange_color: Color = Color(1, 0.5, 0.5)

var _strangeness: float = 0.0
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_setup_material()

func _setup_material() -> void:
	if mesh and mesh.mesh:
		# Get all materials and make them unique to this instance
		var surface_count = mesh.mesh.get_surface_count()
		for i in range(surface_count):
			var base_material = mesh.mesh.surface_get_material(i)
			if base_material is StandardMaterial3D:
				var duplicated = base_material.duplicate()
				# Enable stencil for outlines
				duplicated.stencil_mode = StandardMaterial3D.STENCIL_MODE_OUTLINE
				duplicated.stencil_color = outline_color
				_materials.append(duplicated)
				mesh.set_surface_override_material(i, duplicated)

func get_stranger(delta: float) -> void:
	if _strangeness >= PORTAL_MAX_STRANGENESS:
		emit_signal("fully_strange")
	else:
		_strangeness = min(PORTAL_MAX_STRANGENESS, _strangeness + delta)


func _process(delta: float) -> void:
	if _strangeness < PORTAL_MAX_STRANGENESS:
		_set_strangeness(max(0, _strangeness - delta * 0.5))
	else:
		for material in _materials:
			material.stencil_color = fully_strange_color


func _set_strangeness(value: float) -> void:
	_strangeness = value

	if _materials.size() > 0:
		var a = sin(Time.get_ticks_msec() * 0.004) * 0.9
		var b = sin(Time.get_ticks_msec() * 0.01) * 0.15 
		var c = (cos(a) + cos(b) - sin(a + b)) / 20
		
		var z = sin(_strangeness * 0.01) * 0.15
		var y = sin(_strangeness * 0.0021) * 0.75
		var x = (cos(z) - cos(y) + sin(z + y)) / 20

		var stencil_thickness = _strangeness * 0.02 + (c + x) / 4 - 0.034
		var grow_amount = 0 + cos(Time.get_ticks_msec() * 0.0031) * _strangeness / 140
		
		# Apply to all materials
		for material in _materials:
			# Enable grow if it isn't already
			if not material.grow:
				material.grow = true
			
			material.stencil_outline_thickness = max(0, stencil_thickness)
			material.stencil_color = outline_color

			material.grow_amount = grow_amount

	# # Update the mesh outline based on the new strangeness value.
	# if mesh and mesh.material_override:
	# 	mesh.material_override.grow_amount = _strangeness * 10.1
	# 	mesh.material_override.
