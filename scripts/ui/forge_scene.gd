class_name ForgeScene
extends Control
## The Blacksmith cutscene: Torvik strikes the anvil 3 times (slow, no shaking), then the piece appears
## with its name in its grade's color. Click anywhere to skip or close. Settings "Forge cutscene" turns it off.

signal finished

const ART: String = "res://assets/sprites/npc/anvil_scene.png"
const FRAME_WIDTH: int = 96
const SCALE: int = 4
const REST: float = 0.6
const STRIKE: float = 0.45  # seconds for each hammer up and down
const STRIKES: int = 3

var frames: AtlasTexture = UI.strip(ART, FRAME_WIDTH)
var picture: TextureRect = TextureRect.new()
var result: VBoxContainer = VBoxContainer.new()
var icon: TextureRect = TextureRect.new()
var name_label: Label = Label.new()
var text_label: Label = Label.new()
var playing: bool = false
var plays: int = 0  # counts plays, so an old play still waiting on a timer stops when a new one starts


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.95)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_on_click)
	add_child(backdrop)
	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks go through to the backdrop
	add_child(center)
	picture.texture = frames
	picture.custom_minimum_size = Vector2(FRAME_WIDTH, frames.region.size.y) * SCALE
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(picture)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for label: Label in [name_label, text_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
	name_label.add_theme_font_size_override("font_size", 30)
	text_label.add_theme_font_size_override("font_size", 18)
	var hint: Label = Label.new()
	hint.text = "Click to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate.a = 0.6
	for node: Control in [icon, name_label, text_label, hint]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(node)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(result)
	hide()


## Play the scene for a Gear.forge or Gear.upgrade result. A failed upgrade shows the piece without a glow.
func play(outcome: Dictionary) -> void:
	icon.texture = Gear.icon(outcome.item.id)
	icon.modulate = Color(0.6, 0.6, 0.6) if outcome.outcome in ["fail", "down"] else Color.WHITE
	name_label.text = Gear.title(outcome.item).to_upper()
	name_label.add_theme_color_override("font_color", Gear.color(outcome.item))
	text_label.text = outcome.text
	result.hide()
	picture.show()
	show()
	playing = true
	plays += 1
	var this_play: int = plays
	_show_frame(0)
	await get_tree().create_timer(REST).timeout
	for i in STRIKES:
		for frame in [1, 2]:
			if not playing or this_play != plays:
				return
			_show_frame(frame)
			await get_tree().create_timer(STRIKE).timeout
	if playing and this_play == plays:
		_show_result()


func _show_frame(frame: int) -> void:
	frames.region.position.x = frame * FRAME_WIDTH


func _show_result() -> void:
	playing = false
	picture.hide()
	result.show()


## First click skips to the result, the next one closes.
func _on_click(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if playing:
		_show_result()
	elif visible:
		hide()
		finished.emit()
