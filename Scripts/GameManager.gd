extends Node3D
## Autoload: settings (volume, mouse, fullscreen) and the Continue save.

const SAVE_PATH := 'user://save.cfg'
const SETTINGS_PATH := 'user://settings.cfg'
var score = 0
var coins_required = 0
var volume: float = 0.8
var mouse_sensitivity: float = 0.18
var fullscreen: bool = false
var continuing: bool = false

func _ready() -> void:
	load_settings()

func _process(_delta):
	show_mouse_cursor()

# Making Cursor visible using "mouse_visible" key which is assigned in Project Settings > Input Map
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_score():
	score += 1

# Called by each level's root script on load so the HUD/door know how many coins this level has
func reset_level(total_coins):
	score = 0
	coins_required = total_coins

# ---------- Continue save ---------- #

func save_progress(data: Dictionary) -> void:
	var file := ConfigFile.new()
	for key in data:
		file.set_value('progress', key, data[key])
	file.save(SAVE_PATH)

func load_progress() -> Dictionary:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK or not file.has_section('progress'):
		return {}
	var data := {}
	for key in file.get_section_keys('progress'):
		data[key] = file.get_value('progress', key)
	return data

func has_progress() -> bool:
	return not load_progress().is_empty()

func clear_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

## Returns the save once if the menu asked to continue, otherwise {}.
func take_continue() -> Dictionary:
	if not continuing:
		return {}
	continuing = false
	return load_progress()

# ---------- Settings ---------- #

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	if not OS.has_feature('web'):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) == OK:
		volume = file.get_value('settings', 'volume', volume)
		mouse_sensitivity = file.get_value('settings', 'mouse_sensitivity', mouse_sensitivity)
		fullscreen = file.get_value('settings', 'fullscreen', fullscreen)
	apply_settings()

func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value('settings', 'volume', volume)
	file.set_value('settings', 'mouse_sensitivity', mouse_sensitivity)
	file.set_value('settings', 'fullscreen', fullscreen)
	file.save(SETTINGS_PATH)
	apply_settings()
