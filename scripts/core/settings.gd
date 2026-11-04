class_name Settings
## Player options, saved in user://settings.cfg so they stay between launches.
## user:// is a folder Godot gives each game for its own save files.

const PATH: String = "user://settings.cfg"

static var animate_background: bool = true
static var fullscreen: bool = false
static var animate_dice: bool = true
static var animate_attacks: bool = true


static func load_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.load(PATH)  # no file yet: the defaults below are used
	animate_background = file.get_value("options", "animate_background", true)
	fullscreen = file.get_value("options", "fullscreen", false)
	animate_dice = file.get_value("options", "animate_dice", true)
	animate_attacks = file.get_value("options", "animate_attacks", true)
	_apply()


static func save_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("options", "animate_background", animate_background)
	file.set_value("options", "fullscreen", fullscreen)
	file.set_value("options", "animate_dice", animate_dice)
	file.set_value("options", "animate_attacks", animate_attacks)
	file.save(PATH)
	_apply()


static func _apply() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
