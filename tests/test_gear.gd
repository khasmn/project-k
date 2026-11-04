extends SceneTree
## Gear self-check: buying, wearing, swapping, taking off, selling, class limits and jewelry slots.
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_gear.gd

var failed: bool = false


func _init() -> void:
	var draft: CharacterDraft = CharacterDraft.new()
	draft.class_id = "archer"
	Run.start(draft)
	var hero: Combatant = Run.hero
	var defense: int = hero.defense
	_check(Run.gold == Run.START_GOLD, "start gold wrong")

	Gear.buy("leather_cap")
	_check(Run.gold == Run.START_GOLD - 15 and Run.bag == ["leather_cap"], "buying failed")
	Gear.wear("leather_cap")
	_check(hero.defense == defense + 1 and Run.hero_look.helmet == "leather_cap", "wearing the cap failed")
	Run.bag.append("iron_helm")
	Gear.wear("iron_helm")  # swaps: the cap goes back to the bag
	_check(hero.defense == defense + 2 and Run.bag == ["leather_cap"], "swapping helmets failed")
	Gear.take_off("helmet")
	_check(hero.defense == defense and Run.hero_look.helmet == "" and Run.bag.size() == 2, "taking off failed")
	Gear.sell("iron_helm")
	_check(Run.gold == Run.START_GOLD - 15 + 17, "selling should pay half (17)")

	_check(not Gear.fits("wooden_shield") and Gear.fits("hunting_bow"), "archer can't use a shield, can use a bow")
	var max_hp: int = hero.max_hp
	Run.bag.append_array(["bone_charm", "bone_charm", "copper_ring"])
	Gear.wear("bone_charm")
	Gear.wear("bone_charm")
	_check(hero.max_hp == max_hp + 8 and Run.gear.has("jewelry2"), "two jewelry slots failed")
	Gear.wear("copper_ring")  # both full: swaps out the first
	_check(hero.max_hp == max_hp + 4 and Run.bag.has("bone_charm"), "third jewelry should swap the first")

	if failed:
		quit(1)
		return
	print("Gear OK")
	quit()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		print("FAIL: " + message)
