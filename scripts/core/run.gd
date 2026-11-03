class_name Run
## The current run: the hero (kept between fights and screens), which fight we're on, level and EXP.
## Static variables stay alive when Godot switches scenes, so every screen can read them.

## Fight order for now; the chapter map (build step 4) replaces this.
const FIGHTS: Array[String] = ["giant_rat", "bandit", "wolf", "skeleton", "bandit_chief"]
const POINTS_PER_LEVEL: int = 3

static var hero: Combatant
static var hero_title: String = ""
static var fight_number: int = 1
static var level: int = 1
static var experience: int = 0


static func start(draft: CharacterDraft) -> void:
	hero = Combatant.new(draft.hero_data())
	hero_title = "%s %s with %s" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name]
	_reset()


## For running the combat scene on its own (F6 or the play tool without a run).
static func start_test() -> void:
	hero = Combatant.load_from("res://data/heroes.json", "test_hero")
	hero_title = "Test hero"
	_reset()


static func _reset() -> void:
	fight_number = 1
	level = 1
	experience = 0


static func enemy() -> Combatant:
	return Combatant.load_from("res://data/enemies.json", FIGHTS[fight_number - 1])


static func is_last_fight() -> bool:
	return fight_number == FIGHTS.size()


## Add EXP; every full bar is a level up worth POINTS_PER_LEVEL stat points. Returns levels gained.
static func gain_exp(amount: int) -> int:
	experience += amount
	var levels: int = 0
	while experience >= exp_needed():
		experience -= exp_needed()
		level += 1
		levels += 1
	return levels


## EXP to fill the bar at the current level: 8, 12, 16, ...
static func exp_needed() -> int:
	return 8 + 4 * (level - 1)
