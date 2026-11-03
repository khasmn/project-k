extends SceneTree
## Text play tool: starts a run with the real combat scene headless, clicks buttons in order, prints the log.
## Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/play.gd -- [options] actions...
## Options: --seed N, --force 20,1,..., --race elf, --talent lucky, --class mage (ids from data/*.json;
## race and talent are rolled and class is warrior if not given).
## Actions: attack, defend, and 1/2/3 to click a choice (level-up upgrades, "New hero").
## Same seed + same options + same actions = same run, so you can replay and add one action at a time.
## --force makes the next dice (any die, in roll order, after the hero is rolled) come out as those numbers.

const BUTTONS: Dictionary = {"attack": "%AttackButton", "defend": "%DefendButton"}

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
		if arg.begins_with("--") and i + 1 >= args.size():
			printerr("%s needs a value after it" % arg)
			quit(1)
			return
		if arg in ["--seed", "--force"] and not _is_number_list(args[i + 1]):
			printerr("%s needs a number after it (--force takes a list like 20,1,8)" % arg)
			quit(1)
			return
		if arg == "--seed":
			seed_value = int(args[i + 1])
		elif arg == "--force":
			for n in args[i + 1].split(","):
				forced.append(int(n))
		elif arg in ["--race", "--talent", "--class"]:
			picks[arg.trim_prefix("--")] = args[i + 1].to_lower()
		else:
			actions.append(arg.to_lower())
			i -= 1  # actions have no value after them
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
			print(">> can't '%s' right now (use attack, defend, or a choice number)" % action)
		elif button.disabled:
			print(">> can't %s right now" % action)
		elif button.text == "New hero":
			print(">> click New hero (goes back to character creation; the play tool stops here)")
			break
		else:
			print(">> click %s" % button.text)
			button.pressed.emit()
	await _wait_for_input()
	print("----- LOG -----")
	print(screen.get_node("%Log").get_parsed_text().strip_edges())
	print("----- STATE -----")
	print(screen.get_node("%Title").text)
	print(screen.get_node("%HeroLabel").text + "   |   " + screen.get_node("%EnemyLabel").text)
	var choices: Array = screen.get_node("%Choices").get_children()
	if choices.is_empty():
		print("Your turn. Possible: attack, defend")
	else:
		var texts: PackedStringArray = []
		for n in choices.size():
			texts.append("%d) %s" % [n + 1, choices[n].text])
		print("Choices: " + "   ".join(texts))
	quit()


func _button_for(action: String) -> Button:
	if BUTTONS.has(action):
		return screen.get_node(BUTTONS[action])
	var choices: Array = screen.get_node("%Choices").get_children()
	if action.is_valid_int() and int(action) >= 1 and int(action) <= choices.size():
		return choices[int(action) - 1]
	return null


func _is_number_list(text: String) -> bool:
	for n in text.split(","):
		if not n.is_valid_int():
			return false
	return true


## Wait until the hero can act or there are choices to click (the enemy's turn takes a moment).
func _wait_for_input() -> void:
	while screen.get_node("%AttackButton").disabled and screen.get_node("%Choices").get_child_count() == 0:
		await process_frame
