extends Label

@export var prefix: String = "FPS: "
@export_range(0, 3, 1) var decimals: int = 0


func _process(_delta: float) -> void:
	var fps: float = Engine.get_frames_per_second()
	text = "%s%.*f" % [prefix, decimals, fps]
