extends SceneTree
## Text play tool: runs the real combat scene headless, clicks buttons in order, prints the log.
## Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/play.gd -- [--seed N] [--force 20,1,...] attack defend ...
## Actions: attack, defend, restart. Same seed + same actions = same fight, so you can replay
## and add one action at a time. --force makes the next dice come out as those numbers, in order.

const BUTTONS: Dictionary = {"attack": "%AttackButton", "defend": "%DefendButton", "restart": "%RestartButton"}

var screen: Control


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var seed_value: int = randi()
	var actions: Array[String] = []
	var i: int = 0
	while i < args.size():
		if args[i] in ["--seed", "--force"] and (i + 1 >= args.size() or not _is_number_list(args[i + 1])):
			printerr("%s needs a number after it (--force takes a list like 20,1,8)" % args[i])
			quit(1)
			return
		if args[i] == "--seed":
			seed_value = int(args[i + 1])
			i += 1
		elif args[i] == "--force":
			for n in args[i + 1].split(","):
				Dice.forced_rolls.append(int(n))
			i += 1
		else:
			actions.append(args[i].to_lower())
		i += 1
	Dice.rng.seed = seed_value
	print("Seed: %d" % seed_value)
	Engine.time_scale = 20.0  # skip the enemy's thinking pause
	_play(actions)


func _play(actions: Array[String]) -> void:
	await process_frame  # the tree isn't running yet during _initialize
	screen = load("res://scenes/combat/combat.tscn").instantiate()
	root.add_child(screen)
	for action in actions:
		await _wait_for_input()
		var button: Button = screen.get_node_or_null(BUTTONS.get(action, ""))
		if button == null:
			print(">> unknown action '%s' (use attack, defend, restart)" % action)
		elif button.disabled or not button.visible:
			print(">> can't %s right now" % action)
		else:
			print(">> click %s" % action)
			button.pressed.emit()
	await _wait_for_input()
	print("----- LOG -----")
	print(screen.get_node("%Log").get_parsed_text().strip_edges())
	print("----- STATE -----")
	print(screen.get_node("%HeroLabel").text + "   |   " + screen.get_node("%EnemyLabel").text)
	if screen.get_node("%RestartButton").visible:
		print("Fight over. Possible: restart")
	else:
		print("Your turn. Possible: attack, defend")
	quit()


func _is_number_list(text: String) -> bool:
	for n in text.split(","):
		if not n.is_valid_int():
			return false
	return true


## Wait until the hero can act or the fight is over (the enemy's turn takes a moment).
func _wait_for_input() -> void:
	while screen.get_node("%AttackButton").disabled and not screen.get_node("%RestartButton").visible:
		await process_frame
