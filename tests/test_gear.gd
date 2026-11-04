extends SceneTree
## Gear self-check: buying, wearing, swapping, taking off, selling, class limits, jewelry slots,
## forging grades, loot drops and what survives a new hero.
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
	var cap: Dictionary = Gear.piece("leather_cap")
	_check(Run.gold == Run.START_GOLD - 15 and Run.bag == [cap], "buying failed")
	Gear.wear(cap)
	_check(hero.defense == defense + 1 and Run.hero_look.helmet == "leather_cap", "wearing the cap failed")
	var helm: Dictionary = Gear.piece("iron_helm")
	Run.bag.append(helm)
	Gear.wear(helm)  # swaps: the cap goes back to the bag
	_check(hero.defense == defense + 2 and Run.bag == [cap], "swapping helmets failed")
	Gear.take_off("helmet")
	_check(hero.defense == defense and Run.hero_look.helmet == "" and Run.bag.size() == 2, "taking off failed")
	Gear.sell(helm)
	_check(Run.gold == Run.START_GOLD - 15 + 17, "selling should pay half (17)")

	_check(not Gear.fits("wooden_shield") and Gear.fits("hunting_bow"), "archer can't use a shield, can use a bow")
	var max_hp: int = hero.max_hp
	var charm: Dictionary = Gear.piece("bone_charm")
	Run.bag.append_array([charm, charm, Gear.piece("copper_ring")])
	Gear.wear(charm)
	Gear.wear(charm)
	_check(hero.max_hp == max_hp + 8 and Run.gear.has("jewelry2"), "two jewelry slots failed")
	Gear.wear(Gear.piece("copper_ring"))  # both full: swaps out the first
	_check(hero.max_hp == max_hp + 4 and Run.bag.has(charm), "third jewelry should swap the first")

	# Forging: costs paid, d20 + Luck picks the grade, a natural 20 is at least Epic.
	Run.materials = {"iron_scrap": 6}
	Run.gold = 100
	hero.luck = 0
	_check(Gear.can_forge("steel_helm") and not Gear.can_forge("studded_armor"), "forge costs check wrong")
	Dice.forced_rolls = [17]
	Gear.forge("steel_helm")
	_check(Run.materials.iron_scrap == 3 and Run.gold == 85 and Run.bag.back() == Gear.piece("steel_helm", 3), "17 should forge Rare")
	_check(Gear.stats(Run.bag.back()).defense == 5, "Rare adds +2 to the main stat")
	Dice.forced_rolls = [20]
	Gear.forge("steel_helm")
	_check(Run.bag.back().grade == Gear.EPIC, "a natural 20 should be at least Epic")
	_check(not Gear.known("bandit_hood") and not Gear.known("steel_sword"), "blueprints unknown, other classes hidden")

	# Loot: material always, blueprint on a high enough d20.
	var wolf: Combatant = Combatant.new(Run.data("enemies").wolf)
	Dice.forced_rolls = [20]
	Gear.loot(wolf)
	_check(Run.materials.wolf_pelt == 1 and Run.blueprints.has("wolf_pelt_cloak"), "wolf loot failed")
	Run.materials.starmetal_shard = 1
	Run.start(draft)  # a new hero: blueprints and shards stay, other materials go
	_check(Run.blueprints.has("wolf_pelt_cloak") and Run.materials == {"starmetal_shard": 1}, "new hero should keep blueprints and shards only")

	if failed:
		quit(1)
		return
	print("Gear OK")
	quit()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		print("FAIL: " + message)
