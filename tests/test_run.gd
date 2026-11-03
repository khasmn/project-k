extends SceneTree
## Run and passives self-check, plus a balance report. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_run.gd

const RUNS: int = 2000
const LEVEL_UP: Script = preload("res://scripts/combat/level_up_panel.gd")
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
	_check("automatic miss" in lucky.strike(Combatant.new(DUMMY)), "Lucky rerolled twice in one fight")
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

	# Balance: auto-play whole runs (always attack, points spent at random), per class.
	Dice.forced_rolls = []
	var report: PackedStringArray = []
	for class_id in draft.classes:
		var wins: int = 0
		var reached: Array[int] = [0, 0, 0, 0, 0, 0]
		for i in RUNS:
			var d: CharacterDraft = CharacterDraft.new()
			d.class_id = class_id
			Run.start(d)
			var result: int = _auto_run()
			_check(result >= 1 and result <= Run.FIGHTS.size() + 1, "run ended at a weird fight")
			reached[result - 1] += 1
			if result > Run.FIGHTS.size():
				wins += 1
		report.append("%s %d%% (died at fight 1-5: %s)" % [class_id, 100 * wins / RUNS, reached.slice(0, 5)])

	if failed:
		quit(1)
		return
	print("Run OK  win rates: " + ", ".join(report))
	quit()


## Plays one run with the current Run.hero. Returns the fight it died in, or 6 for a full clear.
func _auto_run() -> int:
	var hero: Combatant = Run.hero
	while true:
		var enemy: Combatant = Run.enemy()
		hero.start_fight()
		var hero_init: int = Dice.roll_d20(hero.roll_mode()) + hero.speed
		var enemy_init: int = Dice.roll_d20() + enemy.speed
		if hero_init < enemy_init or (hero_init == enemy_init and not hero.wins_ties):
			enemy.strike(hero)
		while hero.is_alive() and enemy.is_alive():
			hero.start_turn()
			hero.strike(enemy)
			if enemy.is_alive():
				enemy.strike(hero)
		if not hero.is_alive():
			return Run.fight_number
		hero.win_fight()
		if Run.is_last_fight():
			return Run.FIGHTS.size() + 1
		for point in Run.gain_exp(enemy.exp_reward) * Run.POINTS_PER_LEVEL:
			var entry: Array = LEVEL_UP.STATS[Dice.roll(LEVEL_UP.STATS.size()) - 1]
			hero.raise_stat(entry[0], entry[2])
		Run.fight_number += 1
	return 0


func _hero(effects: Dictionary) -> Combatant:
	return Combatant.new({"name": "Hero", "hp": 30, "attack": 3, "defense": 2, "speed": 2, "damage_die": 8, "effects": effects})


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
