extends Control

func _process(_delta: float) -> void:
	var c = cos(Time.get_ticks_msec() / 3000.0) * 0.4 + 0.4
	var a = sin(Time.get_ticks_msec() / 1000.0) * 0.4 + 1.4
	var b = cos((Time.get_ticks_msec() + 200) / 600.0) * 0.3 + 1.0
	
	rotation -= _delta * 0.02 * (a + b + c)
