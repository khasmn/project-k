class_name UI
## Shared look for menus: flat text buttons that show a gold "▶" cursor on hover.

const GOLD: Color = Color(1, 0.83, 0.3)
const FLAT: StyleBox = preload("res://scenes/ui/flat_button.tres")


static func menu_button(text: String, on_pressed: Callable, font_size: int = 18) -> Button:
	var button: Button = Button.new()
	button.text = "   " + text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, FLAT)
	button.pressed.connect(on_pressed)
	add_cursor(button)
	return button


## An animated strip of frames side by side (frame_width 0 = square frames, like 32x32 sprites).
## AtlasTexture is a texture that shows one rectangle ("region") of a bigger picture.
static func strip(path: String, frame_width: int = 0) -> AtlasTexture:
	var frames: AtlasTexture = AtlasTexture.new()
	frames.atlas = load(path)
	var height: int = frames.atlas.get_height()
	frames.region = Rect2(0, 0, frame_width if frame_width else height, height)
	return frames


## Move a strip to the frame for the current time, fps frames per second (0 = stay on frame 1).
static func animate(frames: AtlasTexture, fps: int) -> void:
	var width: int = int(frames.region.size.x)
	frames.region.position.x = Time.get_ticks_msec() * fps / 1000 % (frames.atlas.get_width() / width) * width


static func add_cursor(button: Button) -> void:
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			button.text = "▶" + button.text.substr(1))
	button.mouse_exited.connect(func() -> void: button.text = " " + button.text.substr(1))
