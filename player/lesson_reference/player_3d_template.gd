extends CharacterBody3D
class_name Player

@export_group("Movement")
## Character maximum run speed on the ground in meters per second.
@export var move_speed := 8.0
## Ground movement acceleration in meters per second squared.
@export var acceleration := 20.0
## When the player is on the ground and presses the jump button, the vertical
## velocity is set to this value.
@export var jump_impulse := 12.0
## Player model rotation speed in arbitrary units. Controls how fast the
## character skin orients to the movement or camera direction.
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character skin's
## animation tree changes between the idle and running states.
@export var stopping_speed := 1.0

@export_group("Glide")
## Maximum downward speed while gliding (holding jump in the air).
@export var glide_max_fall_speed := 3.0
## Horizontal velocity multiplier each frame while gliding, for a floaty feel.
@export var glide_horizontal_drag := 0.98

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

@export_flags_3d_physics var main_world_collision: int = 1
@export_flags_3d_physics var dark_world_collision: int = 1

## Each frame, we find the height of the ground below the player and store it here.
## The camera uses this to keep a fixed height while the player jumps, for example.
var ground_height := 0.0

var _gravity := -30.0
var _was_on_floor_last_frame := true
var _camera_input_direction := Vector2.ZERO
var _look_mode := false
var _is_gliding := false
@onready var _original_spring_arm_length = %SpringArm.spring_length

## The last movement or aim direction input by the player. We use this to orient
## the character model.
@onready var _last_input_direction := global_basis.z
# We store the initial position of the player to reset to it when the player falls off the map.
@onready var _start_position := global_position

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %MainCamera3D
@onready var _skin: SophiaSkin = %SophiaSkin
@onready var _landing_sound: AudioStreamPlayer3D = %LandingSound
@onready var _jump_sound: AudioStreamPlayer3D = %JumpSound
@onready var _dust_particles: GPUParticles3D = %DustParticles
@onready var _glide_particles: GPUParticles3D = %GlideParticles
@onready var _glide_sound: AudioStreamPlayer3D = %GlideSound


func _ready() -> void:
	_setup_shared_viewport()

	GameWorld.set_player(self)
	GameWorld.portal_traversal_started.connect(_traverse_worlds)
	_traverse_worlds(GameWorld._in_mirror_world)

	#Events.kill_plane_touched.connect(func on_kill_plane_touched() -> void:
		#global_position = _start_position
		#velocity = Vector3.ZERO
		#_skin.idle()
		#set_physics_process(true)
	#)
	#Events.flag_reached.connect(func on_flag_reached() -> void:
		#set_physics_process(false)
		#_skin.idle()
		#_dust_particles.emitting = false
	#)

func _traverse_worlds(_mirror_world: bool) -> void:
	collision_mask = dark_world_collision if _mirror_world else main_world_collision
	%SpringArm.collision_mask = dark_world_collision if _mirror_world else main_world_collision

func _setup_shared_viewport() -> void:
	DarkWorldView.set_primary_camera(_camera)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("pc_look"):
		print("Toggling look mode. Current: ", _look_mode)
		_set_look_mode(!_look_mode)


func _unhandled_input(event: InputEvent) -> void:
	var player_is_using_mouse := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if player_is_using_mouse:
		_camera_input_direction.x = - event.relative.x * mouse_sensitivity
		_camera_input_direction.y = event.relative.y * mouse_sensitivity

func _set_look_mode(enabled: bool) -> void:
	_look_mode = enabled
	%SophiaSkin.visible = not enabled
	%StrangeThingRay.enabled = enabled
	if _look_mode:
		%SpringArm.spring_length = 0.0
	else:
		%SpringArm.spring_length = _original_spring_arm_length

func _physics_process(delta: float) -> void:
	if %StrangeThingRay.is_colliding():
		var collider = %StrangeThingRay.get_collider()
		collider.get_parent().find_child('Pulsar').get_stranger(delta)
		print("Ray hit: ", collider.name if collider else "null")

	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y += _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	# Calculate movement input and align it to the camera's direction.
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.4)

	# Should be projected onto the ground plane.
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * (0.35 if _look_mode else 1.0)

	# To not orient the character too abruptly, we filter movement inputs we
	# consider when turning the skin. This also ensures we have a normalized
	# direction for the rotation basis.
	if move_direction.length() > 0.2:
		_last_input_direction = move_direction.normalized()
	var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

	# We separate out the y velocity to only interpolate the velocity in the
	# ground plane, and not affect the gravity.
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity + _gravity * delta

	# Glide: limit fall speed while holding jump in the air.
	var wants_to_glide := (
		not is_on_floor()
		and velocity.y < 0.0
		and Input.is_action_pressed("jump")
		and not _look_mode
	)
	if wants_to_glide:
		velocity.y = max(velocity.y, -glide_max_fall_speed)
		velocity.x *= glide_horizontal_drag
		velocity.z *= glide_horizontal_drag
		if not _is_gliding:
			_is_gliding = true
			_glide_particles.emitting = true
			_glide_sound.play()
	else:
		if _is_gliding:
			_is_gliding = false
			_glide_particles.emitting = false
			_glide_sound.stop()

	# Character animations and visual effects.
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor() and not _look_mode
	if is_just_jumping:
		velocity.y += jump_impulse
		_skin.jump()
		_jump_sound.play()
	elif not is_on_floor() and velocity.y < 0:
		_skin.fall()
	elif is_on_floor():
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()

	_dust_particles.emitting = is_on_floor() && ground_speed > 0.0

	if is_on_floor() and not _was_on_floor_last_frame:
		_landing_sound.play()

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()
