extends SceneTree
## Farm self-check: buying, growing up, the companion's stats, eggs, release, and the 6 animal skills.
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_farm.gd

var failed: bool = false


func _init() -> void:
	var draft: CharacterDraft = CharacterDraft.new()
	draft.class_id = "warrior"
	Run.start(draft)
	Run.gold = 500
	_check(Farm.companion() == null, "no animals: no companion")
	var dog: Dictionary = Farm.buy("dog")
	_check(Run.gold == 460 and Run.companion == 0, "buying a puppy costs 40g and the first animal comes along")
	Farm.buy("chicken")
	Farm.buy("boar")
	Farm.buy("dog")
	_check(Run.companion == 0 and not Farm.can_buy("chicken"), "the barn holds 4")
	_check(Farm.stage(dog) == 0 and Farm.companion().max_hp == 8, "a puppy has 8 HP")
	_check(Farm.gain_exp(20).ends_with("grew into a Young Dog!") and Farm.companion().max_hp == 14, "20 EXP makes a Young Dog")
	Farm.gain_exp(40)
	_check(Farm.stage(dog) == 2 and Farm.companion().display_name == dog.name, "60 EXP makes an adult, with its name")

	var hero: Combatant = Run.hero
	var foe: Combatant = Combatant.new(Run.data("enemies").giant_rat)
	var pet: Combatant = Farm.companion()  # Dog: power 2
	pet.use_skill(pet.skills[0], [foe], [hero])
	_check(hero.statuses.inspired.power == 2, "Howl inspires the hero")
	Dice.forced_rolls = [10, 1]
	var line: String = hero.strike(foe)
	_check(line.contains("Inspired") and hero.statuses.inspired.turns == 1, "an inspired attack adds the bonus and uses 1 of 2")
	Dice.forced_rolls = [10, 1]
	hero.strike(foe)
	_check(not hero.statuses.has("inspired"), "Inspired ends after 2 attacks")

	Run.companion = 1  # the chick: Warm Egg heals 3
	pet = Farm.companion()
	hero.hp = hero.max_hp - 10
	pet.use_skill(pet.skills[0], [foe], [hero])
	_check(hero.hp == hero.max_hp - 7, "Warm Egg heals the hero by its power")

	Run.companion = 2  # the piglet: Charge stuns only on a crit
	pet = Farm.companion()
	foe.hp = 99
	Dice.forced_rolls = [19, 1, 1]
	pet.use_skill(pet.skills[0], [foe], [hero])
	_check(not foe.statuses.has("stun"), "a normal Charge hit doesn't stun")
	pet.ready_on.clear()
	Dice.forced_rolls = [20, 1, 1, 1]
	pet.use_skill(pet.skills[0], [foe], [hero])
	_check(foe.statuses.has("stun"), "a critical Charge stuns")

	Run.start(draft)
	var bandit: Combatant = Combatant.new(Run.data("enemies").bandit)
	Dice.forced_rolls = [19]
	_check(Farm.egg_drop(bandit) == "" and Run.eggs.is_empty(), "a bandit drops its egg only on a 20")
	Dice.forced_rolls = [20]
	_check(Farm.egg_drop(bandit).contains("Raven Egg") and Run.eggs == ["raven"], "a 20 drops a Raven Egg")
	var raven: Dictionary = Farm.hatch()[0]
	_check(Run.eggs.is_empty() and raven.kind == "raven" and Run.companion == 0, "the egg hatches and the chick comes along")
	Run.gold = 0
	pet = Farm.companion()
	foe = Combatant.new(Run.data("enemies").giant_rat)
	foe.hp = 99
	Dice.forced_rolls = [20, 1, 1, 3]  # a crit (damage rolled twice), then steals 3 x power 1
	pet.use_skill(pet.skills[0], [foe], [Run.hero])
	_check(Run.gold == 3, "Snatch steals d3 x power gold on a hit")
	Run.eggs = ["owl"]
	var owl: Combatant = Combatant.new(Farm.stats(Farm.hatch()[0]))
	owl.use_skill(owl.skills[0], [foe], [Run.hero])
	_check(Run.hero.charmed, "Keen Sight gives the hero's next attack advantage")
	Run.eggs = ["drake"]
	var drake: Combatant = Combatant.new(Farm.stats(Farm.hatch()[0]))
	var foe2: Combatant = Combatant.new(Run.data("enemies").giant_rat)
	Dice.forced_rolls = [1, 1, 1, 1]  # both fail the Speed save
	drake.use_skill(drake.skills[0], [foe, foe2], [Run.hero])
	_check(foe.statuses.has("burn") and foe2.statuses.has("burn"), "Fire Breath burns every monster that fails")
	Farm.buy("dog")
	Dice.forced_rolls = [20]
	_check(Farm.egg_drop(bandit).contains("full") and Run.eggs.is_empty(), "a full barn loses the egg")
	Run.companion = 2
	Farm.release(0)
	_check(Run.animals.size() == 3 and Run.companion == 1 and Run.animals[1].kind == "drake", "release keeps the same companion")
	Farm.release(1)
	_check(Run.companion == -1, "releasing the companion leaves nobody coming along")
	Run.start(draft)
	_check(Run.animals.is_empty() and Run.companion == -1, "a new hero starts with an empty farm")
	if failed:
		quit(1)
		return
	print("Farm OK")
	quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + what)
