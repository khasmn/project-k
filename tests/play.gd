extends SceneTree
## Text play tool: starts a run with the real scenes headless, clicks buttons in order, prints the screen.
## Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/play.gd -- [options] actions...
## Options: --seed N, --force 20,1,..., --race elf, --talent lucky, --class mage (ids from data/*.json;
## race and talent are rolled and class is warrior if not given).
## Actions in a fight: attack, defend, 1 to click a choice ("Continue", "New hero").
## On the path screen: 1/2/3 to pick a door (or Rest/Train), character to open the stat panel,
## then +hp, +attack, +defense, +speed to add a point (-hp etc. to take it back), confirm or close.
## Same seed + same options + same actions = same run, so you can replay and add one action at a time.
## --force makes the next dice (any die, in roll order, after the hero is rolled) come out as those numbers.

const BUTTONS: Dictionary = {
	"attack": "%AttackButton", "defend": "%DefendButton", "character": "%CharacterButton",
	"confirm": "%CharacterPanel/%ConfirmButton", "close": "%CharacterPanel/%CloseButton",
}
const STAT_IDS: Dictionary = {"hp": "max_hp", "attack": "attack", "defense": "defense", "speed": "speed"}



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
	var first: Control = load("res://scenes/combat/combat.tscn").instantiate()
	root.add_child(first)
	current_scene = first  # so change_scene_to_file can swap it for the path screen and back
	for action in actions:
		await _wait_for_input()
		var button: Button = _button_for(action)
		if button == null:
			print(">> can't '%s' here (fight: attack, defend, 1; path: 1/2/3, character, +stat/-stat, confirm, close)" % action)
		elif button.disabled:
			print(">> can't %s right now" % action)
		elif button.text == "New hero":
			print(">> click New hero (goes back to character creation; the play tool stops here)")
			break
		else:
			print(">> click %s" % _button_name(action, button))
			button.pressed.emit()
	await _wait_for_input()
	if _on_path():
		_print_path()
	else:
		_print_fight()
	quit()


func _print_fight() -> void:
	print("----- LOG -----")
	print(_node("%Log").get_parsed_text().strip_edges())
	print("----- STATE -----")
	print(_node("%Title").text)
	for n in ["%HeroName", "%HeroHP", "%HeroStats", "%Level"]:
		print("  Hero: " + _node(n).text.replace("\n", "  |  "))
	for n in ["%EnemyName", "%EnemyHP", "%EnemyStats"]:
		print("  Enemy: " + _node(n).text)
	var choices: Array = _node("%Choices").get_children()
	if choices.is_empty():
		print(_node("%TurnLabel").text + ". Possible: attack, defend")
	else:
		print("Choices: 1) " + choices[0].text)


func _print_path() -> void:
	print("----- PATH -----")
	print("%s   %s" % [_node("%Progress").text, _node("%Gold").text])
	for n in ["%HeroName", "%HeroHP", "%Level", "%HeroStats"]:
		print("  Hero: " + _node(n).text.replace("\n", "  |  "))
	if _node("%CharacterPanel").visible:
		print(_node("%CharacterPanel/%PointsLabel").text)
		for row in _node("%CharacterPanel/%StatRows").get_children():
			print("  %s %s" % [row.get_node("Name").text, row.get_node("Value").text])
		print("Possible: +hp +attack +defense +speed (or -stat to undo), then confirm, or close")
		return
	print(_node("%HeadingTitle").text)
	var cards: Array = _node("%Doors").get_children()
	for n in cards.size():
		var lines: Array = cards[n].get_child(0).get_children().map(func(label: Label) -> String: return label.text)
		print("  %d) %s" % [n + 1, "  |  ".join(lines)])
	print("Possible: 1-%d, or %s" % [cards.size(), _node("%CharacterButton").text.to_lower()])


func _button_for(action: String) -> Button:
	if BUTTONS.has(action):
		return current_scene.get_node_or_null(BUTTONS[action])
	if action.length() > 1 and action[0] in "+-" and STAT_IDS.has(action.substr(1)):
		var panel: Node = current_scene.get_node_or_null("%CharacterPanel")
		if panel == null or not panel.visible:
			return null
		return _node("%CharacterPanel/%StatRows").get_node("Row_" + STAT_IDS[action.substr(1)]).get_node("Plus" if action[0] == "+" else "Minus")
	var options: Array = _node("%Doors" if _on_path() else "%Choices").get_children()
	if action.is_valid_int() and int(action) >= 1 and int(action) <= options.size():
		return options[int(action) - 1]
	return null


func _button_name(action: String, button: Button) -> String:
	if action[0] in "+-":
		return action
	if button.get_child_count() > 0:
		return button.get_child(0).get_child(0).text  # a door card: its title line
	return button.text


func _node(path: String) -> Node:
	return current_scene.get_node(path)


func _on_path() -> bool:
	return current_scene.name == "Path"


## A whole number small enough to fit (huge ones would silently turn into a different number).
func _is_number(text: String) -> bool:
	return text.is_valid_int() and text.trim_prefix("-").length() <= 18


## Wait until a scene change is done and the player can click something (the enemy's turn takes a moment).
func _wait_for_input() -> void:
	while true:
		await process_frame
		var scene: Node = current_scene
		if scene == null or not scene.is_node_ready():
			continue
		if scene.name == "Path":
			if scene.get_node("%Doors").get_child_count() > 0 or scene.get_node("%CharacterPanel").visible:
				return
		elif not scene.get_node("%AttackButton").disabled or scene.get_node("%Choices").get_child_count() > 0:
			return
