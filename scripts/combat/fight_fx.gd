class_name FightFx
extends Control
## Fight effects drawn over the whole fight screen: effect strips from assets/sprites/fx/, projectiles,
## hit flashes and damage numbers. Every function can be awaited; with attack animations off they return at once.

const FPS: int = 12
const SCALE: float = 3.0  # same pixel size as the 32x32 sprites shown 3x
const FLY_TIME: float = 0.25
const MONSTER_FPS: int = 10
## How far (in art pixels) a monster moves toward the hero on each frame of its attack strip.
const MONSTER_LUNGE: Array[int] = [-2, -3, 5, 6, 2, 0]
const MONSTER_HIT_FRAME: int = 2


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Play effect strip `name` once, centered on `over`. Missing art plays nothing.
func play(name: String, over: Control) -> void:
	if not Settings.animate_attacks or name == "" or over == null:
		return
	var path: String = "res://assets/sprites/fx/%s.png" % name
	if not ResourceLoader.exists(path):
		return
	var picture: TextureRect = _picture(path)
	picture.global_position = _center(over) - picture.size / 2
	var frames: int = picture.texture.atlas.get_width() / int(picture.texture.region.size.x)
	for i in frames:
		picture.texture.region.position.x = i * picture.texture.region.size.x
		await get_tree().create_timer(1.0 / FPS).timeout
	picture.queue_free()


## Fly projectile `name` from one fighter to another.
func fly(name: String, from: Control, to: Control) -> void:
	if not Settings.animate_attacks or name == "":
		return
	var picture: TextureRect = _picture("res://assets/sprites/fx/%s.png" % name)
	picture.flip_h = _center(to).x > _center(from).x  # projectiles are drawn flying left
	picture.global_position = _center(from) - picture.size / 2
	var tween: Tween = create_tween()
	tween.tween_property(picture, "global_position", _center(to) - picture.size / 2, FLY_TIME)
	while tween.is_running():
		if picture.texture.atlas.get_width() > picture.texture.region.size.x:
			UI.animate(picture.texture, FPS)
		await get_tree().process_frame
	picture.queue_free()


## A fighter gets hit: red flash, a little shake and a number (or "Miss" / "Blocked") rising above it.
func hurt(target: Control, text: String, color: Color) -> void:
	if not Settings.animate_attacks or target == null:
		return
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.1))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	label.global_position = _center(target) - Vector2(label.get_minimum_size().x / 2, target.size.y / 2 + 10)
	var rise: Tween = create_tween().set_parallel()
	rise.tween_property(label, "global_position:y", label.global_position.y - 40, 0.7)
	rise.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	rise.finished.connect(label.queue_free)
	if text == "Miss":
		return
	var start: Vector2 = target.position
	var shake: Tween = create_tween()
	target.modulate = Color(1, 0.35, 0.35)
	for dx in [6, -6, 4, -2, 0]:
		shake.tween_property(target, "position:x", start.x + dx, 0.04)
	shake.tween_property(target, "modulate", Color.WHITE, 0.1)
	await shake.finished


## A monster's attack: its attack strip (if drawn) while it lunges toward the hero; on_hit runs on the hit frame.
func monster_attack(picture: TextureRect, sprite: String, toward: float, on_hit: Callable, folder: String = "enemies") -> void:
	var path: String = "res://assets/sprites/%s/%s_attack.png" % [folder, sprite.trim_suffix("_idle")]
	if not Settings.animate_attacks or picture == null or not ResourceLoader.exists(path):
		on_hit.call()
		return
	var idle: Texture2D = picture.texture
	var strip: AtlasTexture = UI.strip(path)
	picture.texture = strip
	var start: Vector2 = picture.position
	var pixel: float = picture.size.y / strip.region.size.y
	for i in MONSTER_LUNGE.size():
		strip.region.position.x = i * strip.region.size.x
		picture.position.x = start.x + MONSTER_LUNGE[i] * pixel * signf(toward)
		if i == MONSTER_HIT_FRAME:
			on_hit.call()
		await get_tree().create_timer(1.0 / MONSTER_FPS).timeout
	picture.position = start
	picture.texture = idle


## A monster using a skill that isn't an attack (a howl, a shield): it rises a little and glows.
func monster_cast(picture: TextureRect) -> void:
	if not Settings.animate_attacks or picture == null:
		return
	var start: Vector2 = picture.position
	var tween: Tween = create_tween()
	tween.tween_property(picture, "position:y", start.y - 8, 0.15)
	tween.parallel().tween_property(picture, "modulate", Color(1.4, 1.4, 1.2), 0.15)
	tween.tween_property(picture, "position:y", start.y, 0.2)
	tween.parallel().tween_property(picture, "modulate", Color.WHITE, 0.2)
	await tween.finished


func _picture(path: String) -> TextureRect:
	var picture: TextureRect = TextureRect.new()
	picture.texture = UI.strip(path)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.size = picture.texture.region.size * SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	return picture


func _center(node: Control) -> Vector2:
	return node.global_position + node.size / 2
