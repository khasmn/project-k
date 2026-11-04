class_name HeroSprite
extends Control
## The hero's picture: layers stacked back to front, each a 5-frame breathing strip in
## assets/sprites/hero/. Grey layers are tinted (modulate = multiply) with the skin or hair color.

const FPS: int = 6
## [file, which look value fills the %s, tint]. Missing files are skipped: only Dwarves have a beard.
const LAYERS: Array = [
	["race/%s_back", "race", ""], ["race/%s", "race", "skin"], ["race/%s_face", "race", ""],
	["outfit/%s", "outfit", ""], ["race/%s_beard", "race", "hair_color"], ["hair/%s", "hair_style", "hair_color"],
	["race/%s_ears", "race", "skin"], ["race/%s_top", "race", ""], ["weapon/%s", "class", ""],
]

var frames: Array[AtlasTexture] = []


## look: {race, class, outfit, hair_style, skin: Color, hair_color: Color}, see CharacterDraft.sprite_look().
func show_look(look: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	frames.clear()
	for layer in LAYERS:
		var path: String = "res://assets/sprites/hero/%s.png" % (layer[0] % look[layer[1]])
		if not ResourceLoader.exists(path):
			continue
		var picture: TextureRect = TextureRect.new()
		picture.texture = UI.strip(path)
		frames.append(picture.texture)
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if layer[2]:
			picture.modulate = look[layer[2]]
		add_child(picture)


func _process(_delta: float) -> void:
	for strip in frames:
		UI.animate(strip, FPS)
