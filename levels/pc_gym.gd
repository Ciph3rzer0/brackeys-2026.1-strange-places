extends Node3D



func _on_move_the_ball_body_entered(_body: Node3D) -> void:
	print("Entered the move the ball area. Is ball moving? ", %BallMover._is_moving)
	if %BallMover._at_start:
		print("Moving the ball!")
		%BallMover.run()
		%BallMoverTrigger.set_active(true)


func _on_sphere_mover_trigger_body_exited(_body: Node3D) -> void:
	if not %BallMover._at_start:
		print("Removing the ball!")
		%BallMover.run()
		%BallMoverTrigger.set_active(false)
