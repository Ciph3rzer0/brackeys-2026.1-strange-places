extends Area3D

@export var active_color: Color = Color.GREEN
@export var inactive_color: Color = Color.RED
@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	_setup_material()
	_update_color(inactive_color)

func _setup_material() -> void:
	if mesh.material_override == null:
		var material = StandardMaterial3D.new()
		mesh.material_override = material

func _update_color(color: Color) -> void:
	if mesh.material_override:
		mesh.material_override.albedo_color = color

func set_active(active: bool) -> void:
	print("Setting pressure plate active: ", active)
	_update_color(active_color if active else inactive_color)
