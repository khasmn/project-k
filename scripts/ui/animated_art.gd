class_name AnimatedArt
extends TextureRect
## A full-screen picture that slowly plays its frame strip (assets/backgrounds/, 384x216 frames side by side).
## The texture is an AtlasTexture showing frame 1; the Settings switch "Background animation" stops it.

const FPS: int = 2  # slow on purpose: fast motion can cause motion sickness


func _process(_delta: float) -> void:
	if Settings.animate_background:
		UI.animate(texture, FPS)
