extends TextureRect

func _process(delta):
	modulate.a -= delta * 0.017
