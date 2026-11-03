extends SceneTree
## Text play tool: starts a run with the real combat scene headless, clicks buttons in order, prints the log.
## Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/play.gd -- [options] actions...
## Options: --seed N, --force 20,1,..., --race elf, --talent lucky, --class mage (ids from data/*.json;
## race and talent are rolled and class is warrior if not given).
## Actions: attack, defend, 1/2/3 to click a choice ("Next fight", "New hero"), and on level-up:
## +hp, +attack, +defense, +speed to add a point (-hp etc. to take it back), then confirm.
## Same seed + same options + same actions = same run, so you can replay and add one action at a time.
## --force makes the next dice (any die, in roll order, after the hero is rolled) come out as those numbers.

const BUTTONS: Dictionary = {"attack": "%AttackButton", "defend": "%DefendButton", "confirm": "%ConfirmButton"}
const STAT_IDS: Dictionary = {"hp": "max_hp", "attack": "attack", "defense": "defense", "speed": "speed"}

var screen: Control


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var seed_value: int = randi()
	var forced: Array[int] = []
	var picks: Dictionary = {}
	var actions: Array[String] = []
	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		if not arg.begins_with("--"):
			actions.append(arg.to_lower())
			i += 1
			continue
		var error: String = ""
		var value: String = args[i + 1] if i + 1 < args.size() else ""
		if not arg in ["--seed", "--force", "--race", "--talent", "--class"]:
			error = "unknown option %s (use --seed, --force, --race, --talent, --class)" % arg
		elif value == "":
			error = "%s needs a value after it" % arg
		elif arg == "--seed" and not _is_number(value):
			error = "--seed needs one whole number, like 42"
		elif arg == "--force" and not Array(value.split(",")).all(_is_number):
			error = "--force needs a list of numbers, like 20,1,8"
		if error != "":
			printerr(error)
			quit(1)
			return
		if arg == "--seed":
			seed_value = int(value)
		elif arg == "--force":
			for n in value.split(","):
				forced.append(int(n))
		else:
			picks[arg.trim_prefix("--")] = value.to_lower()
		i += 2
	Dice.rng.seed = seed_value

	var draft: CharacterDraft = CharacterDraft.new()
	draft.class_id = "warrior"
	for kind in picks:
		var options: Dictionary = {"race": draft.races, "talent": draft.talents, "class": draft.classes}[kind]
		if not options.has(picks[kind]):
			printerr("unknown %s '%s', use one of: %s" % [kind, picks[kind], ", ".join(options.keys())])
			quit(1)
			return
		draft.set(kind + "_id", picks[kind])
	Run.start(draft)
	Dice.forced_rolls = forced
	print("Seed: %d   Hero: %s" % [seed_value, Run.hero_title])
	Engine.time_scale = 20.0  # skip the enemy's thinking pause
	_play(actions)


func _play(actions: Array[String]) -> void:
	await process_frame  # the tree isn't running yet during _initialize
	screen = load("res://scenes/combat/combat.tscn").instantiate()
	root.add_child(screen)
	for action in actions:
		await _wait_for_input()
		var button: Button = _button_for(action)
		if button == null:
			print(">> can't '%s' right now (use attack, defend, a choice number, or +stat/-stat/confirm on level-up)" % action)
		elif button.disabled:
			print(">> can't %s right now" % action)
		elif button.text == "New hero":
			print(">> click New hero (goes back to character creation; the play tool stops here)")
			break
		else:
			print(">> click %s" % (action if action[0] in "+-" else button.text))
			button.pressed.emit()
	await _wait_for_input()
	print("----- LOG -----")
	print(screen.get_node("%Log").get_parsed_text().strip_edges())
	print("----- STATE -----")
	print(screen.get_node("%Title").text)
	for n in ["%HeroName", "%HeroHP", "%HeroStats", "%Level"]:
		print("  Hero: " + screen.get_node(n).text.replace("\n", "  |  "))
	for n in ["%EnemyName", "%EnemyHP", "%EnemyStats"]:
		print("  Enemy: " + screen.get_node(n).text)
	var choices: Array = screen.get_node("%Choices").get_children()
	if screen.get_node("%LevelUpPanel").visible:
		print(screen.get_node("%PointsLabel").text)
		for row in screen.get_node("%StatRows").get_children():
			print("  %s %s" % [row.get_node("Name").text, row.get_node("Value").text])
		print("Possible: +hp +attack +defense +speed (or -stat to undo), then confirm")
	elif choices.is_empty():
		print(screen.get_node("%TurnLabel").text + ". Possible: attack, defend")
	else:
		var texts: PackedStringArray = []
		for n in choices.size():
			texts.append("%d) %s" % [n + 1, choices[n].text])
		print("Choices: " + "   ".join(texts))
	quit()


func _button_for(action: String) -> Button:
	if BUTTONS.has(action):
		return screen.get_node(BUTTONS[action])
	if action.length() > 1 and action[0] in "+-" and STAT_IDS.has(action.substr(1)):
		var row: Node = screen.get_node("%StatRows").get_node_or_null("Row_" + STAT_IDS[action.substr(1)])
		if row != null and screen.get_node("%LevelUpPanel").visible:
			return row.get_node("Plus" if action[0] == "+" else "Minus")
		return null
	var choices: Array = screen.get_node("%Choices").get_children()
	if action.is_valid_int() and int(action) >= 1 and int(action) <= choices.size():
		return choices[int(action) - 1]
	return null


## A whole number small enough to fit (huge ones would silently turn into a different number).
func _is_number(text: String) -> bool:
	return text.is_valid_int() and text.trim_prefix("-").length() <= 18


## Wait until the hero can act, there are choices, or the level-up panel is open (the enemy's turn takes a moment).
func _wait_for_input() -> void:
	while (screen.get_node("%AttackButton").disabled and screen.get_node("%Choices").get_child_count() == 0
			and not screen.get_node("%LevelUpPanel").visible):
		await process_frame
