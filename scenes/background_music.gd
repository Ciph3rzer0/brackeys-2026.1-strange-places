extends Node

const BLEND_BUS_PREFIX : String = "Blend"

@onready var main_world: AudioStreamPlayer = $BackgroundMusicMainWorld
@onready var main_world_max_volume_db: float = main_world.volume_db

@onready var dark_world: AudioStreamPlayer = $BackgroundMusicDarkWorld
@onready var dark_world_max_volume_db: float = dark_world.volume_db

const SILENT_DB := -40.0

@export var parent_volume_bus: StringName = &"_BlendMusic"

@export var fade_background_tracks: bool = true
@export_range(0.0, 1.0, 0.01) var track_fade: float = 0.0:
	set(value):
		track_fade = clampf(value, 0.0, 1.0)
		_apply_track_fade()

@export var track_fade_curve: Curve = null

func _ready() -> void:
	GameWorld.set_background_music_player(self)
	_assign_parent_volume_bus()
	print("Main World:", main_world, " | Dark World:", dark_world)
	_apply_track_fade()


# Re-parent audio stream bus so the dark theme can inherit volume changes from the main theme.
# (Just has to be this way because of the template)
func _assign_parent_volume_bus() -> void:
	if parent_volume_bus == StringName():
		return

	if AudioServer.get_bus_index(parent_volume_bus) == -1:
		push_warning("Audio bus '%s' was not found. Keeping existing music buses." % parent_volume_bus)
		return

	main_world.bus = parent_volume_bus
	dark_world.bus = parent_volume_bus


func _apply_track_fade() -> void:
	if not is_node_ready():
		return

	if fade_background_tracks:
		var main_sample := track_fade_curve.sample(track_fade)
		var dark_sample := track_fade_curve.sample(1 - track_fade)
		# print("Applying track fade: %.2f --- %.2f" % [main_sample, dark_sample])
		main_world.volume_db = lerpf(SILENT_DB, main_world_max_volume_db, main_sample)
		dark_world.volume_db = lerpf(SILENT_DB, dark_world_max_volume_db, dark_sample)
	else:
		main_world.volume_db = main_world_max_volume_db
		dark_world.volume_db = dark_world_max_volume_db
