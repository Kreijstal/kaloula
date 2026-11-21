class_name GameSettings
extends RefCounted
## Player settings: sound-effect and music volume, saved to user://settings.cfg.
## Volumes are 0..1 and drive the "SFX" and "Music" audio buses
## (default_bus_layout.tres). Put sound players on the matching bus.

const PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"

static var sound := 0.8
static var music := 0.6


## Read the saved settings (if any) and apply them to the audio buses.
static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sound = clampf(cfg.get_value("audio", "sound", sound), 0.0, 1.0)
		music = clampf(cfg.get_value("audio", "music", music), 0.0, 1.0)
	apply()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound)
	cfg.set_value("audio", "music", music)
	cfg.save(PATH)


static func set_sound(value: float) -> void:
	sound = clampf(value, 0.0, 1.0)
	apply()


static func set_music(value: float) -> void:
	music = clampf(value, 0.0, 1.0)
	apply()


static func apply() -> void:
	_set_bus(SFX_BUS, sound)
	_set_bus(MUSIC_BUS, music)


static func _set_bus(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, volume <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volume, 0.0001)))
