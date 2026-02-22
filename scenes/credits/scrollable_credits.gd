@tool
extends Control

@onready var credits_label : Control = %CreditsLabel

@export var input_scroll_speed : float = 400.0

var _scroll_position : float = 0.0


func _get_max_scroll() -> float:
	if not credits_label:
		return 0.0
	var content_height = maxf(credits_label.size.y, credits_label.get_combined_minimum_size().y)
	return maxf(0.0, content_height - size.y)


func _apply_scroll_position() -> void:
	if not credits_label:
		return
	credits_label.position.y = -_scroll_position


func _on_visibility_changed() -> void:
	if visible:
		_scroll_position = 0.0
		_apply_scroll_position()

func _ready() -> void:
	clip_contents = true
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_apply_scroll_position)
	_apply_scroll_position()

func _process(delta : float) -> void:
	if Engine.is_editor_hint() or not visible:
		return
	var input_axis = Input.get_axis("ui_up", "ui_down")
	if abs(input_axis) > 0.5:
		_scroll_position += input_axis * delta * input_scroll_speed
		_scroll_position = clampf(_scroll_position, 0.0, _get_max_scroll())
		_apply_scroll_position()
