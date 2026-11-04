class_name Run
## The current run: the hero (kept between screens), which room we're in, level, EXP, gold, points.
## Static variables stay alive when Godot switches scenes, so every screen can read them.

const ROOMS: int = 8  # rooms before the boss
const BOSS: String = "bandit_chief"
const BACKGROUND: String = "woods"  # chapter 1, in assets/backgrounds/
const BOSS_BACKGROUND: String = "bandit_fortress"  # the boss fight: the bandits' fortress at night
const DOOR_TYPES: Array[String] = ["elite", "rest", "shop", "event"]
const DOORS: int = 3
const MAX_ENEMIES: int = 4
const POINTS_PER_LEVEL: int = 3
const REST_HEAL_PERCENT: int = 30
const TRAIN_POINTS: int = 1
const START_ITEMS: Dictionary = {"healing_potion": 2}
const START_GOLD: int = 30  # enough for a first piece of gear in the town Shop

static var hero: Combatant
static var hero_title: String = ""
static var hero_look: Dictionary = {}  # for HeroSprite; empty for the test hero
static var room: int = 1  # 1..ROOMS, then ROOMS + 1 is the boss
static var room_type: String = ""  # the door picked for this room
static var room_note: String = ""  # shown at the start of the next battle log
static var level: int = 1
static var experience: int = 0
static var points: int = 0  # unspent stat points
static var gold: int = 0
static var items: Dictionary = {}  # item id -> how many, see data/items.json
static var bag: Array[Dictionary] = []  # gear pieces you carry but don't wear (see Gear.piece)
static var gear: Dictionary = {}  # slot (helmet, armor, weapon, offhand, jewelry1, jewelry2) -> piece you wear
static var materials: Dictionary = {}  # material id -> how many, see data/materials.json
## Kept for every future hero (not reset): blueprints found and "kept" materials (Starmetal Shards).
## ponytail: lost when the game closes until saving exists (build step 5).
static var blueprints: Array[String] = []
static var animals: Array[Dictionary] = []  # the Farm: {"kind", "name", "exp"}, see Farm
static var companion: int = -1  # index in animals of the one that comes along, -1 = none


static func start(draft: CharacterDraft) -> void:
	hero = Combatant.new(draft.hero_data())
	hero_look = draft.sprite_look()
	hero_title = ("%s, " % draft.look.name if draft.look.name else "") + "%s %s with %s" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name]
	_reset()


## For running a scene on its own (F6 or the play tool without a run).
static func start_test() -> void:
	hero = Combatant.new(data("heroes").test_hero)
	hero_title = "Test hero"
	hero_look = {}
	_reset()


static func _reset() -> void:
	room = 1
	room_type = ""
	room_note = ""
	level = 1
	experience = 0
	points = 0
	gold = START_GOLD
	items = START_ITEMS.duplicate()
	bag = []
	gear = {}
	animals = []
	companion = -1
	for material: String in materials.keys():
		if not data("materials")[material].get("kept", false):
			materials.erase(material)


## Back to town (path screen, or after the boss): the chapter starts again from room 1. The hero keeps everything.
static func restart_chapter() -> void:
	room = 1
	room_type = ""
	room_note = ""


static func is_boss() -> bool:
	return room > ROOMS


## 3 doors of different types, each with a random name and description from data/rooms.json.
static func door_choices() -> Array:
	var texts: Dictionary = data("rooms")
	var types: Array = DOOR_TYPES.duplicate()
	var doors: Array = []
	for i in DOORS:
		var type: String = types.pop_at(Dice.roll(types.size()) - 1)
		var options: Array = texts[type]
		var door: Dictionary = options[Dice.roll(options.size()) - 1].duplicate()
		door.type = type
		doors.append(door)
	return doors


## This room's monsters: 1-4 random ones that live in this room (data "rooms": [first, last]).
## Elite room: that room's elite (data "elite") plus 0-2 helpers. Boss: the boss plus its "guards".
static func enemies() -> Array[Combatant]:
	var all: Dictionary = data("enemies")
	var ids: Array = []
	if is_boss():
		ids = [BOSS] + all[BOSS].guards
	else:
		var pool: Array = all.keys().filter(func(id: String) -> bool:
			return all[id].has("rooms") and room >= all[id].rooms[0] and room <= all[id].rooms[1])
		var count: int = Dice.roll(MAX_ENEMIES) if room_type != "elite" else Dice.roll(MAX_ENEMIES - 1)
		for i in count:
			ids.append(pool[Dice.roll(pool.size()) - 1])
		if room_type == "elite":
			ids[0] = all[ids[0]].elite
	var group: Array[Combatant] = []
	for id in ids:
		var foe: Combatant = Combatant.new(all[id])
		# "sprite_with": a different look when a certain monster is in the same fight (wolves with bandits wear a collar).
		var with: Dictionary = all[id].get("sprite_with", {})
		for other in with:
			if other in ids:
				foe.sprite = with[other]
		group.append(foe)
	# Two of the same monster get numbers: "Bandit 1", "Bandit 2".
	for foe in group:
		var same: Array = group.filter(func(other: Combatant) -> bool: return other.display_name == foe.display_name)
		if same.size() > 1:
			for n in same.size():
				same[n].display_name += " %d" % (n + 1)
	return group


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


## One file from data/, e.g. data("enemies").
static func data(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % file))
