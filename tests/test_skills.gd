extends SceneTree
## Skills, Energy and status effects self-check. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_skills.gd

const DUMMY: Dictionary = {"name": "Dummy", "hp": 50, "attack": 0, "defense": 0, "speed": 0, "damage_die": 4}

var failed: bool = false


func _init() -> void:
	var skills: Dictionary = Run.data("skills")

	# Every class and monster skill id exists, and hero skills have a cost and a description.
	for file in ["classes", "enemies"]:
		for entry: Dictionary in Run.data(file).values():
			for id: String in entry.get("skills", [entry.skill] if entry.has("skill") else []):
				_check(skills.has(id), "unknown skill %s" % id)
	for entry: Dictionary in Run.data("classes").values():
		for id: String in entry.skills:
			_check(skills[id].has("cost") and skills[id].has("description"), "hero skill %s without cost" % id)

	# Energy: starts full, a skill costs its cost, +1 each turn up to the max.
	var warrior: Combatant = _fighter("shield_bash", 3)
	warrior.start_fight()
	Dice.forced_rolls = [1]  # a natural 1: miss
	warrior.use_skill(warrior.skills[0], [_dummy()], [warrior])
	_check(warrior.energy == 1, "Shield Bash didn't cost 2 Energy")
	warrior.start_turn()
	warrior.start_turn()
	warrior.start_turn()
	_check(warrior.energy == Combatant.MAX_ENERGY, "Energy went past the max")

	# Shield Bash: a hit and a failed save stun the target; a stunned fighter loses one turn.
	var foe: Combatant = _dummy()
	Dice.forced_rolls = [15, 2, 3]  # attack hits, damage 2, save 3 vs 13 fails
	_check("stunned" in warrior.strike(foe, skills.shield_bash), "Shield Bash didn't stun")
	_check(foe.shake_off_stun() and not foe.shake_off_stun(), "stun didn't last exactly one turn")

	# Poison: 1 damage at the start of each turn for 3 turns, not blocked by a shield.
	Dice.forced_rolls = [15, 2, 3]
	_fighter("poison_arrow", 3).strike(foe, skills.poison_arrow)
	foe.shield = 5
	var hp: int = foe.hp
	for i in 4:
		foe.start_turn()
	_check(foe.hp == hp - 3 and foe.statuses.is_empty() and foe.shield == 5, "poison wrong: %d HP, %s" % [hp - foe.hp, foe.statuses])

	# Shield soaks attack damage first.
	foe.shield = 3
	hp = foe.hp
	foe.take_damage(5)
	_check(foe.shield == 0 and foe.hp == hp - 2, "shield didn't soak 3")

	# Fireball: no attack roll; a passed save takes half, a failed one full damage and burns.
	var mage: Combatant = _fighter("fireball", 4)
	var near: Combatant = _dummy()
	var far: Combatant = _dummy()
	Dice.forced_rolls = [20, 8, 2, 8]  # near saves (nat 20): 8 + 2 = 10, half 5; far fails (2): 10, burns
	mage.use_skill(mage.skills[0], [near, far], [mage])
	_check(near.hp == 45 and far.hp == 40, "Fireball damage wrong: %d, %d" % [near.hp, far.hp])
	_check(far.statuses.has("burn") and not near.statuses.has("burn"), "Fireball burn wrong")

	# Flurry: two attacks, each at -2 to hit (Attack 3 - 2 = +1: a 9 makes 10 = Armor 10).
	var brawler: Combatant = _fighter("flurry", 3)
	foe = _dummy()
	Dice.forced_rolls = [9, 1, 8]  # first hits (9 + 1 = 10), second misses (8 + 1 = 9)
	var flurry: String = brawler.use_skill(brawler.skills[0], [foe], [brawler])
	_check(flurry.count("attacks Dummy") == 2 and foe.hp == 48, "Flurry wrong: %d HP" % foe.hp)

	# Monster skills: Cleave adds a d4; Rally shields every ally.
	var orc: Combatant = _fighter("cleave", 0)
	foe = _dummy()
	Dice.forced_rolls = [15, 2, 3]
	orc.use_skill(orc.skills[0], [foe], [orc])
	_check(foe.hp == 45, "Cleave extra die wrong: %d" % foe.hp)
	var captain: Combatant = _fighter("rally", 0)
	var guard: Combatant = _dummy()
	captain.use_skill(captain.skills[0], [foe], [captain, guard])
	_check(captain.shield == 3 and guard.shield == 3, "Rally didn't shield everyone")

	# Second skills: Iron Guard shields only the user; Uppercut adds a d8.
	var guard_user: Combatant = _fighter("iron_guard", 0)
	guard_user.use_skill(guard_user.skills[0], [foe], [guard_user, guard])
	_check(guard_user.shield == 6 and guard.shield == 3, "Iron Guard shield wrong")
	var boxer: Combatant = _fighter("uppercut", 3)
	foe = _dummy()
	Dice.forced_rolls = [9, 2, 5]  # 9 + 3 - 2 = 10 hits Armor 10; d8 2 + half Attack 1 + d8 5
	boxer.use_skill(boxer.skills[0], [foe], [boxer])
	_check(foe.hp == 42, "Uppercut damage wrong: %d HP" % foe.hp)

	# A new fight clears Energy, statuses and shields.
	far.start_fight()
	_check(far.statuses.is_empty() and far.shield == 0 and far.energy == Combatant.MAX_ENERGY, "start_fight didn't reset")

	if failed:
		quit(1)
		return
	print("Skills OK")
	quit()


func _fighter(skill: String, attack: int) -> Combatant:
	return Combatant.new({"name": "User", "hp": 30, "attack": attack, "defense": 2, "speed": 2, "damage_die": 8, "skill": skill})


func _dummy() -> Combatant:
	return Combatant.new(DUMMY)


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
