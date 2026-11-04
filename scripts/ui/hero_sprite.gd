class_name HeroSprite
extends Control
## The hero's picture: layers stacked back to front, each a 5-frame breathing strip in
## assets/sprites/hero/. Grey layers are tinted (modulate = multiply) with the skin or hair color.
## play_attack() swaps the weapon for its 6-frame attack strip and moves body and head through a pose.

const FPS: int = 6
const ATTACK_FPS: int = 10
## [file, which look value fills the %s, tint, part]. Missing files are skipped: only Dwarves have a beard.
## The part says how a layer moves in an attack pose: with the body, the head or the weapon.
const LAYERS: Array = [
	["race/%s_back", "race", "", "body"], ["race/%s", "race", "skin", "body"], ["race/%s_face", "race", "", "head"],
	["outfit/%s", "outfit", "", "body"], ["race/%s_beard", "race", "hair_color", "head"], ["hair/%s", "hair_style", "hair_color", "head"],
	["race/%s_ears", "race", "skin", "head"], ["race/%s_top", "race", "", "head"], ["weapon/%s", "class", "", "body"],
]
## Per attack strip: one [body x, body y, head x, head y] pixel offset per frame (negative x = toward the monsters),
## and "hits", the frames where a blow lands or a shot leaves. The head lags a little: it reads as weight.
const POSES: Dictionary = {
	"warrior_attack": {"hits": [2], "frames": [[1, 0, 1, 0], [0, -1, 0, -1], [-3, 0, -2, 0], [-3, 1, -3, 1], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"archer_attack": {"hits": [3], "frames": [[0, 0, 0, 0], [1, 0, 1, 0], [1, 0, 1, 0], [0, 0, 0, 0], [1, 0, 1, 0], [0, 0, 0, 0]]},
	"mage_attack": {"hits": [2], "frames": [[0, -1, 0, -1], [1, 0, 1, 0], [-2, 0, -2, 0], [-2, 0, -1, 0], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"brawler_attack": {"hits": [1], "frames": [[1, 1, 1, 1], [-3, 0, -2, 0], [-3, 0, -3, 0], [-1, 0, -1, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
	"warrior_skill": {"hits": [2], "frames": [[1, 0, 1, 0], [0, -2, 0, -2], [-3, 1, -2, 1], [-3, 1, -3, 1], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"archer_skill": {"hits": [4], "frames": [[0, 0, 0, 0], [1, 0, 1, 0], [1, 0, 1, 0], [2, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
	"mage_skill": {"hits": [3], "frames": [[0, -1, 0, -1], [0, -1, 0, -1], [1, -1, 1, -1], [-2, 0, -2, 0], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"warrior_guard": {"hits": [2], "frames": [[0, 0, 0, 0], [1, 0, 1, 0], [0, 1, 0, 1], [0, 1, 0, 1], [0, 0, 0, 0], [0, 0, 0, 0]]},
	"archer_aimed": {"hits": [4], "frames": [[0, 0, 0, 0], [1, 0, 1, 0], [1, 0, 1, 0], [2, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
	"mage_frost": {"hits": [3], "frames": [[0, 0, 0, 0], [1, 0, 1, 0], [-2, 0, -2, 0], [-3, 0, -2, 0], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"brawler_uppercut": {"hits": [2], "frames": [[0, 1, 0, 1], [0, 2, 0, 2], [-2, -1, -2, -1], [-2, -2, -2, -2], [-1, 0, -1, 0], [0, 0, 0, 0]]},
	"brawler_skill": {"hits": [1, 3], "frames": [[1, 1, 1, 1], [-3, 0, -2, 0], [-1, 0, -1, 0], [-3, 0, -2, 0], [-1, 0, -1, 0], [0, 0, 0, 0]]},
}

var frames: Array[AtlasTexture] = []
var parts: Array = []  # [TextureRect, part] per layer, for attack poses
var weapon: TextureRect
var attacking: bool = false


## look: {race, class, outfit, hair_style, skin: Color, hair_color: Color}, see CharacterDraft.sprite_look().
func show_look(look: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	frames.clear()
	parts.clear()
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
		parts.append([picture, layer[3]])
		if layer[0].begins_with("weapon"):
			weapon = picture


## Play the attack pose for kind ("warrior_attack", or a skill like "warrior_skill"). on_hit(n) runs on each hit frame
## (n = 0, 1...). Without art for it, the hits just run.
func play_attack(kind: String, on_hit: Callable) -> void:
	var path: String = "res://assets/sprites/hero/weapon/%s.png" % kind
	var pose: Dictionary = POSES.get(kind, {})
	if weapon == null or pose.is_empty() or not ResourceLoader.exists(path):
		for n in pose.get("hits", [0]).size():
			on_hit.call(n)
		return
	attacking = true
	var idle: Texture2D = weapon.texture
	var strip: AtlasTexture = UI.strip(path)
	weapon.texture = strip
	for texture in frames:
		texture.region.position.x = 0  # attack poses start from the first breathing frame
	var pixel: float = size.x / 32
	for i in pose.frames.size():
		strip.region.position.x = i * strip.region.size.x
		var offsets: Array = pose.frames[i]
		for part in parts:
			var offset: Vector2 = Vector2(offsets[2], offsets[3]) if part[1] == "head" else Vector2(offsets[0], offsets[1])
			part[0].position = offset * pixel
		if i in pose.hits:
			on_hit.call(pose.hits.find(i))
		await get_tree().create_timer(1.0 / ATTACK_FPS).timeout
	weapon.texture = idle
	attacking = false


func _process(_delta: float) -> void:
	if attacking:
		return
	for strip in frames:
		UI.animate(strip, FPS)
