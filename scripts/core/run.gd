class_name Run
## The current run: the hero (kept between screens), which room we're in, level, EXP, gold, points.
## Static variables stay alive when Godot switches scenes, so every screen can read them.

const ROOMS: int = 8  # rooms before the boss
const BOSS: String = "bandit_chief"
const DOOR_TYPES: Array[String] = ["elite", "rest", "shop", "event"]
const TYPE_NAMES: Dictionary = {"elite": "ELITE", "rest": "REST", "shop": "SHOP", "event": "EVENT", "boss": "BOSS"}
const DOORS: int = 3
const POINTS_PER_LEVEL: int = 3
const REST_HEAL_PERCENT: int = 30
const TRAIN_EXP_PERCENT: int = 10

static var hero: Combatant
static var hero_title: String = ""
static var room: int = 1  # 1..ROOMS, then ROOMS + 1 is the boss
static var room_type: String = ""  # the door picked for this room
static var room_note: String = ""  # shown at the start of the next battle log
static var level: int = 1
static var experience: int = 0
static var points: int = 0  # unspent stat points
static var gold: int = 0


static func start(draft: CharacterDraft) -> void:
	hero = Combatant.new(draft.hero_data())
	hero_title = "%s %s with %s" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name]
	_reset()


## For running a scene on its own (F6 or the play tool without a run).
static func start_test() -> void:
	hero = Combatant.load_from("res://data/heroes.json", "test_hero")
	hero_title = "Test hero"
	_reset()


static func _reset() -> void:
	room = 1
	room_type = ""
	room_note = ""
	level = 1
	experience = 0
	points = 0
	gold = 0


static func is_boss() -> bool:
	return room > ROOMS


## 3 doors of different types, each with a random name and description from data/rooms.json.
static func door_choices() -> Array:
	var texts: Dictionary = _load("res://data/rooms.json")
	var types: Array = DOOR_TYPES.duplicate()
	var doors: Array = []
	for i in DOORS:
		var type: String = types.pop_at(Dice.roll(types.size()) - 1)
		var options: Array = texts[type]
		var door: Dictionary = options[Dice.roll(options.size()) - 1].duplicate()
		door.type = type
		doors.append(door)
	return doors


## The enemy for this room: the boss, or a random enemy that fits how far in we are (Elite = tougher).
static func enemy() -> Combatant:
	var all: Dictionary = _load("res://data/enemies.json")
	if is_boss():
		return Combatant.new(all[BOSS])
	# Rooms 1-3 use tier 1 enemies, 4-6 tiers 1-2, 7-8 tiers 2-3.
	var top_tier: int = ceili(room / 3.0)
	var ids: Array = []
	for id in all:
		if all[id].tier > 0 and all[id].tier >= top_tier - 1 and all[id].tier <= top_tier:
			ids.append(id)
	var foe: Combatant = Combatant.new(all[ids[Dice.roll(ids.size()) - 1]])
	if room_type == "elite":
		foe.display_name = "Elite " + foe.display_name
		foe.max_hp = ceili(foe.max_hp * 1.5)
		foe.hp = foe.max_hp
		foe.attack += 1
		foe.defense += 1
		foe.exp_reward *= 2
		foe.gold_reward *= 2
	return foe


## Add EXP; every full bar is a level up worth POINTS_PER_LEVEL stat points. Returns levels gained.
static func gain_exp(amount: int) -> int:
	experience += amount
	var levels: int = 0
	while experience >= exp_needed():
		experience -= exp_needed()
		level += 1
		levels += 1
	points += levels * POINTS_PER_LEVEL
	return levels


## EXP to fill the bar at the current level: 8, 12, 16, ...
static func exp_needed() -> int:
	return 8 + 4 * (level - 1)


## Rest room, option 1: heal 30% of max HP (never past max). Returns HP healed.
static func rest_amount() -> int:
	return mini(ceili(hero.max_hp * REST_HEAL_PERCENT / 100.0), hero.max_hp - hero.hp)


## Rest room, option 2: 10% of the current EXP bar.
static func train_amount() -> int:
	return ceili(exp_needed() * TRAIN_EXP_PERCENT / 100.0)


static func _load(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
