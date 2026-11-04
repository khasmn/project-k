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


static func add_cursor(button: Button) -> void:
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			button.text = "▶" + button.text.substr(1))
	button.mouse_exited.connect(func() -> void: button.text = " " + button.text.substr(1))
