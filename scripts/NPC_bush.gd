extends Node3D

@export var radius: float = 3.0
@export var speed: float = 2.0

@onready var anim: AnimationPlayer = $NPC_bush/AnimationPlayer
@onready var initial_position: Vector3 = position

var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("walk")

func _process(delta: float) -> void:
	time += delta * speed
	
	var x = cos(time) * radius
	var z = sin(time) * radius
	
	var next_pos = initial_position + Vector3(x, 0, z)
	
	# Look slightly ahead in the circle for smoother rotation
	var look_time = time + 0.1
	var look_target = initial_position + Vector3(cos(look_time) * radius, 0, sin(look_time) * radius)
	
	if next_pos != look_target:
		look_at(look_target, Vector3.UP)
	
	position = next_pos
