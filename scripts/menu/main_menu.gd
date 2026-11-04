extends Control
## Main menu: new game, settings, quit. Continue stays greyed out until saving exists (build step 5).

const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"
const FONT_SIZE: int = 26


func _ready() -> void:
	Settings.load_file()
	%Buttons.add_child(UI.menu_button("New Game", get_tree().change_scene_to_file.bind(CREATION_SCENE), FONT_SIZE))
	var continue_button: Button = UI.menu_button("Continue", func() -> void: pass, FONT_SIZE)
	continue_button.disabled = true
	%Buttons.add_child(continue_button)
	%Buttons.add_child(UI.menu_button("Settings", _show_settings.bind(true), FONT_SIZE))
	%Buttons.add_child(UI.menu_button("Quit", get_tree().quit, FONT_SIZE))
	for button: Button in %Buttons.get_children():
		button.add_theme_color_override("font_outline_color", Color.BLACK)
		button.add_theme_constant_override("outline_size", 6)  # readable over the title art

	%AnimateCheck.button_pressed = Settings.animate_background
	%FullscreenCheck.button_pressed = Settings.fullscreen
	%DiceCheck.button_pressed = Settings.animate_dice
	%AttackCheck.button_pressed = Settings.animate_attacks
	%ForgeCheck.button_pressed = Settings.animate_forge
	%AnimateCheck.toggled.connect(func(on: bool) -> void: Settings.animate_background = on; Settings.save_file())
	%DiceCheck.toggled.connect(func(on: bool) -> void: Settings.animate_dice = on; Settings.save_file())
	%AttackCheck.toggled.connect(func(on: bool) -> void: Settings.animate_attacks = on; Settings.save_file())
	%ForgeCheck.toggled.connect(func(on: bool) -> void: Settings.animate_forge = on; Settings.save_file())
	%FullscreenCheck.toggled.connect(func(on: bool) -> void: Settings.fullscreen = on; Settings.save_file())
	%Options.add_child(UI.menu_button("Back", _show_settings.bind(false)))


func _show_settings(on: bool) -> void:
	%SettingsPanel.visible = on
	%Buttons.visible = not on
