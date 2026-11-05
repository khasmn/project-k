extends SceneTree
## Run and passives self-check, plus a balance report. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_run.gd

const RUNS: int = 2000
const PANEL: Script = preload("res://scripts/ui/character_panel.gd")
const DUMMY: Dictionary = {"name": "Dummy", "hp": 500, "attack": 0, "defense": 0, "speed": 0, "damage_die": 4}

var failed: bool = false


func _init() -> void:
	# Keen Eye: a 19 is a crit (rolls 2 damage dice).
	var keen: Combatant = _hero({"crit_min": 19})
	Dice.forced_rolls = [19, 3, 4]
	_check("CRITICAL" in keen.strike(Combatant.new(DUMMY)), "Keen Eye 19 not a crit")

	# Chosen One: attack rolls keep the higher of two d20s.
	var chosen: Combatant = _hero({"advantage": true})
	Dice.forced_rolls = [2, 15, 3]
	_check(chosen.strike(Combatant.new(DUMMY)).contains("2 and 15 (Advantage keeps 15)"), "Chosen One didn't keep the high roll")

	# Lucky: the first nat 1 of a fight is rerolled, the second isn't; a new fight resets it.
	var lucky: Combatant = _hero({"lucky": true})
	Dice.forced_rolls = [1, 12, 3]
	_check("Lucky rerolls" in lucky.strike(Combatant.new(DUMMY)), "Lucky didn't reroll")
	Dice.forced_rolls = [1]
	var second: String = lucky.strike(Combatant.new(DUMMY))
	_check("natural 1!" in second and not "rerolls" in second, "Lucky rerolled twice in one fight")
	lucky.start_fight()
	Dice.forced_rolls = [1, 12, 3]
	_check("Lucky rerolls" in lucky.strike(Combatant.new(DUMMY)), "Lucky didn't reset for a new fight")

	# Second Wind: first lethal hit leaves 1 HP, the next one kills.
	var tough: Combatant = _hero({"second_wind": true})
	tough.take_damage(999)
	_check(tough.hp == 1, "Second Wind didn't save")
	tough.take_damage(999)
	_check(tough.hp == 0, "Second Wind saved twice")

	# Mossfolk regen and Bloodlust never heal past max HP.
	var moss: Combatant = _hero({"regen": 1, "heal_on_win": 4})
	moss.hp = moss.max_hp - 2
	moss.start_turn()
	_check(moss.hp == moss.max_hp - 1, "regen wrong")
	moss.win_fight()
	_check(moss.hp == moss.max_hp, "Bloodlust healed past max")

	# Glass Cannon: -6 HP from the talent's stats, +2 damage.
	var draft: CharacterDraft = CharacterDraft.new()
	draft.race_id = "human"
	draft.talent_id = "glass_cannon"
	draft.class_id = "warrior"
	var cannon: Combatant = Combatant.new(draft.hero_data())
	_check(cannon.max_hp == 26 and cannon.damage_bonus == 2, "Glass Cannon wrong")

	# Stat points: more Max HP also heals the same amount.
	cannon.hp = 10
	cannon.raise_stat("max_hp", 3)
	_check(cannon.max_hp == 29 and cannon.hp == 13, "Max HP point wrong")
	cannon.raise_stat("attack", 2)
	_check(cannon.attack == 5, "attack point wrong")

	# EXP: bar is 8, 12, 16...; leftover EXP carries over; a big gain can give two levels.
	Run.start(draft)
	_check(Run.gain_exp(7) == 0 and Run.level == 1, "leveled too early")
	_check(Run.gain_exp(1) == 1 and Run.level == 2 and Run.experience == 0, "level up at 8 EXP wrong")
	_check(Run.gain_exp(30) == 2 and Run.level == 4 and Run.experience == 2, "double level up wrong")
	_check(Run.points == 3 * Run.POINTS_PER_LEVEL, "stat points not saved")

	# Doors: always 3, never two of the same type. Elites are tougher and pay double.
	for i in 200:
		var types: Array = Run.door_choices().map(func(door: Dictionary) -> String: return door.type)
		_check(types.size() == 3 and types.size() == _unique(types).size(), "doors wrong: %s" % [types])
	# Groups: 1-4 monsters that live in this room; elite rooms lead with an elite; the boss has guards.
	var all: Dictionary = Run.data("enemies")
	var elite_names: Array = all.values().filter(func(e: Dictionary) -> bool: return not e.has("rooms")).map(
		func(e: Dictionary) -> String: return e.name)
	for room in range(1, Run.ROOMS + 1):
		Run.room = room
		for i in 50:
			Run.room_type = ""
			var group: Array[Combatant] = Run.enemies()
			_check(group.size() >= 1 and group.size() <= Run.MAX_ENEMIES, "group size %d" % group.size())
			_check(room > 2 or group.all(func(c: Combatant) -> bool: return not c.display_name.begins_with("Wolf")), "wolf too early")
			_check_collars(group)
			Run.room_type = "elite"
			group = Run.enemies()
			_check(group[0].display_name in elite_names and group.size() <= Run.MAX_ENEMIES - 1, "elite room wrong")
			_check_collars(group)
	Run.room = Run.ROOMS + 1
	var boss_group: Array = Run.enemies().map(func(c: Combatant) -> String: return c.display_name)
	_check(Run.is_boss() and boss_group == ["Bandit Chief", "Bandit 1", "Bandit 2"], "boss group wrong: %s" % [boss_group])

	# Defend: attacks against a defender roll with disadvantage (keep the low die).
	var defender: Combatant = _hero({})
	defender.defending = true
	Dice.forced_rolls = [18, 3]
	_check("keeps 3" in Combatant.new(DUMMY).strike(defender), "defend didn't give disadvantage")

	# Rest heals 30% (not past max).
	Run.hero.hp = Run.hero.max_hp - 2
	_check(Run.rest_amount() == 2, "rest healed past max")

	# Balance: auto-play whole runs (always attack, points spent at random), per class.
	Dice.forced_rolls = []
	var report: PackedStringArray = []
	for class_id in draft.classes:
		var wins: int = 0
		var wins_2: int = 0
		var reached: Array[int] = []
		reached.resize(Run.ROOMS + 2)
		for i in RUNS:
			var d: CharacterDraft = CharacterDraft.new()
			d.class_id = class_id
			Run.start(d)
			var result: int = _auto_run()
			_check(result >= 1 and result <= Run.ROOMS + 2, "run ended in a weird room")
			reached[result - 1] += 1
			if result == Run.ROOMS + 2:
				wins += 1
				# Chapter 2 with the same hero (healed in town, no new gear: real players will be a bit stronger).
				Run.chapter = "2"
				Run.restart_chapter()
				Run.hero.hp = Run.hero.max_hp
				if _auto_run() == Run.ROOMS + 2:
					wins_2 += 1
		report.append("%s %d%% (died in room 1-8, boss: %s), chapter 2: %d%% of them" % [class_id, 100 * wins / RUNS,
			reached.slice(0, Run.ROOMS + 1), 100 * wins_2 / maxi(wins, 1)])

	# 3 lives: a death costs a life and half the gold, heals, restarts the chapter, keeps level and gear.
	var hero_draft: CharacterDraft = CharacterDraft.new()
	hero_draft.class_id = "warrior"
	Run.start(hero_draft)
	Gear.buy("bandit_hood")
	Run.level = 4
	Run.gold = 51
	Run.room = 6
	Run.hero.hp = 0
	_check(Run.lose_life() == 25 and Run.gold == 26 and Run.lives == 2, "a death costs a life and half the gold")
	_check(Run.room == 1 and Run.hero.hp == Run.hero.max_hp and Run.level == 4 and Run.bag.size() == 1, "restart at room 1, healed, keeping level and gear")
	Run.start(hero_draft)
	_check(Run.lives == Run.LIVES, "a new hero has 3 lives")

	if failed:
		quit(1)
		return
	print("Run OK  win rates: " + ", ".join(report))
	quit()


## Plays one run with the current Run.hero: random doors, rests when hurt, points spent at random.
## Returns the room it died in (ROOMS + 1 = the boss), or ROOMS + 2 for a full clear.
func _auto_run() -> int:
	var hero: Combatant = Run.hero
	while true:
		if Run.is_boss():
			Run.room_type = "boss"
		elif Run.room > 1:
			var doors: Array = Run.door_choices()
			Run.room_type = doors[Dice.roll(doors.size()) - 1].type
			if Run.room_type == "rest":
				if hero.hp < hero.max_hp * 0.7:
					hero.hp += Run.rest_amount()
				else:
					Run.points += Run.TRAIN_POINTS
		var group: Array[Combatant] = Run.enemies()
		hero.start_fight()
		var hero_init: int = Dice.roll_d20(hero.roll_mode()) + hero.speed
		var enemy_init: int = Dice.roll_d20() + group.map(func(c: Combatant) -> int: return c.speed).max()
		var enemies_first: bool = hero_init < enemy_init or (hero_init == enemy_init and not hero.wins_ties)
		while hero.is_alive() and group.any(func(c: Combatant) -> bool: return c.is_alive()):
			if not enemies_first:
				hero.start_turn()
				# Always attack the weakest living monster.
				var alive: Array = group.filter(func(c: Combatant) -> bool: return c.is_alive())
				alive.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.hp < b.hp)
				hero.strike(alive[0])
			enemies_first = false
			for foe in group:
				if foe.is_alive() and hero.is_alive():
					foe.strike(hero)
		if not hero.is_alive():
			return Run.room
		hero.win_fight()
		if Run.is_boss():
			return Run.ROOMS + 2
		for foe in group:
			Run.gain_exp(foe.exp_reward)
			Run.gold += foe.gold_reward
		for point in Run.points:
			var entry: Array = PANEL.STATS[Dice.roll(PANEL.STATS.size()) - 1]
			hero.raise_stat(entry[0], entry[2])
		Run.points = 0
		Run.room += 1
	return 0


func _unique(items: Array) -> Array:
	var seen: Array = []
	for item in items:
		if not item in seen:
			seen.append(item)
	return seen


func _hero(effects: Dictionary) -> Combatant:
	return Combatant.new({"name": "Hero", "hp": 30, "attack": 3, "defense": 2, "speed": 2, "damage_die": 8, "effects": effects})


## Wolves wear a collar exactly when a Bandit or Bandit Captain is in the same fight.
func _check_collars(group: Array[Combatant]) -> void:
	var with_bandit: bool = group.any(func(c: Combatant) -> bool: return c.display_name.begins_with("Bandit"))
	for foe in group:
		if foe.display_name.begins_with("Wolf"):
			_check((foe.sprite == "wolf_collar_idle") == with_bandit, "wolf collar wrong: %s" % foe.sprite)


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
