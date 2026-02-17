extends Node3D

@export var billboard_y_only: bool = true

var _player: Node3D

var _front_portal_contact: bool = false
var _back_portal_contact: bool = false

func set_portal_open_progress(val: float):
	var size =  Vector3.ONE * max(0.001, val)
	$PortalHole.scale = size

func _ready() -> void:
	# _find_player()
	pass
	# Pattern:
	# Player enters F, Player enters B, Player leaves F, -> portal transfer

func _find_player() -> void:
	# Try to find player by group or common name
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
	else:
		# Fallback: try to find by name
		_player = get_tree().root.find_child("Player*", true, false)

func _process(_delta: float) -> void:
	if _player:
		if billboard_y_only:
			# Only rotate on Y axis (keep portal upright)
			var target_pos = _player.global_position
			target_pos.y = global_position.y
			look_at(target_pos, Vector3.UP)
		else:
			# Full billboard (faces player completely)
			look_at(_player.global_position, Vector3.UP)


func _on_player_detect_f_body_entered(_body: Node3D) -> void:
	# print("Player entered front portal area.")
	_front_portal_contact = true


func _on_player_detect_f_body_exited(_body: Node3D) -> void:
	# print("Player exited front portal area.")
	_front_portal_contact = false
	if _back_portal_contact:
		print("Player should be teleported now! (Entered F, then B)")
		_teleport_player()


func _on_player_detect_b_body_entered(_body: Node3D) -> void:
	# print("Player entered back portal area.")
	_back_portal_contact = true


func _on_player_detect_b_body_exited(_body: Node3D) -> void:
	# print("Player exited back portal area.")
	_back_portal_contact = false
	if _front_portal_contact:
		print("Player should be teleported now! (Entered B, then F)")
		_teleport_player()


func _teleport_player() -> void:
	# This is where you'd implement the actual teleportation logic.
	# For example, you might want to move the player to a specific location,
	# or swap their position with another portal.;
	DarkWorldView.switch_cameras()
	pass
