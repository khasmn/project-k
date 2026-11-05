class_name Cutscene
extends Control
## Story cutscene player (data/cutscenes.json): each scene is a slow picture loop with its text typing in
## below. A click shows the whole text, or goes to the next scene; Skip ends it. Then the next screen opens.

const SCENE: String = "res://scenes/story/cutscene.tscn"
const ART_SIZE: Vector2 = Vector2(384, 216)  # pictures are drawn at this size and shown scaled up
const TEXT_HEIGHT: int = 40  # the dark band at the bottom of every picture, in art pixels
const LETTERS_PER_SECOND: float = 40.0

static var playing: String = ""
static var after: String = ""

var scenes: Array = []
var index: int = -1
var picture: TextureRect = TextureRect.new()
var hero: HeroSprite = HeroSprite.new()
var text: Label = Label.new()
var frames: AtlasTexture
var fps: int = 0


## Show cutscene id, then open next_scene.
static func play(tree: SceneTree, id: String, next_scene: String) -> void:
	playing = id
	after = next_scene
	tree.change_scene_to_file(SCENE)


func _ready() -> void:
	var back: ColorRect = ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(PRESET_FULL_RECT)
	add_child(back)
	picture.set_anchors_preset(PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(picture)
	if Run.hero_look:
		hero.show_look(Run.hero_look)
	add_child(hero)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	add_child(text)
	var skip: Button = UI.menu_button("Skip", _finish, 18)
	skip.position = Vector2(16, 12)
	add_child(skip)
	for child: Control in [back, picture, hero, text]:
		child.mouse_filter = MOUSE_FILTER_IGNORE  # clicks reach this screen (next) or the Skip button
	scenes = Run.data("cutscenes")[playing]
	_next()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if text.visible_ratio < 1:
			text.visible_ratio = 1
		else:
			_next()


func _process(delta: float) -> void:
	text.visible_ratio = minf(1, text.visible_ratio + delta * LETTERS_PER_SECOND / maxi(text.text.length(), 1))
	UI.animate(frames, fps)
	# The picture keeps its shape on any window: place the hero and the text in art pixels on top of it.
	var scale: float = minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var corner: Vector2 = (size - ART_SIZE * scale) / 2
	var spot: Array = scenes[index].get("hero", [])
	hero.visible = not spot.is_empty() and Run.hero_look
	if hero.visible:
		hero.position = corner + Vector2(spot[0], spot[1]) * scale
		hero.size = Vector2(32, 32) * scale
	text.position = corner + Vector2(24, ART_SIZE.y - TEXT_HEIGHT) * scale
	text.size = Vector2(ART_SIZE.x - 48, TEXT_HEIGHT) * scale


func _next() -> void:
	index += 1
	if index >= scenes.size():
		_finish()
		return
	var scene: Dictionary = scenes[index]
	frames = UI.strip("res://assets/cutscenes/%s.png" % scene.art, int(ART_SIZE.x))
	fps = int(scene.fps) if Settings.animate_background else 0  # off: the picture stays on frame 1
	picture.texture = frames
	text.text = scene.text
	text.visible_ratio = 0


func _finish() -> void:
	get_tree().change_scene_to_file(after)
