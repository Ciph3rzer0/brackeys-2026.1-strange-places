extends Node

var _in_mirror_world: bool = false

@warning_ignore_start("unused_signal")
signal portal_activated(mirror_world: bool)

func activate_portal():
	print("Activating portal. Emitting signal.")
	_in_mirror_world = !_in_mirror_world
	portal_activated.emit(_in_mirror_world)