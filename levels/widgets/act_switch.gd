extends Area3D

signal switched_on()
signal switched_off()

@export var active_color: Color = Color.GREEN
@export var inactive_color: Color = Color.RED
@onready var mesh: MeshInstance3D = $Mesh

var is_active: bool = false

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

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		var bodies = get_overlapping_bodies()
		if bodies.size() > 0:
			is_active = !is_active
			print("Switch activated by input. Active: ", is_active)
			_update_color(active_color if is_active else inactive_color)
			if is_active:
				switched_on.emit()
			else:
				switched_off.emit()
