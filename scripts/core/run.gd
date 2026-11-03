class_name Run
## The current run: the hero (kept between fights and screens), which fight we're on, level-up choices.
## Static variables stay alive when Godot switches scenes, so every screen can read them.

## Fight order for now; the chapter map (build step 4) replaces this.
const FIGHTS: Array[String] = ["giant_rat", "bandit", "wolf", "skeleton", "bandit_chief"]
const UPGRADE_CHOICES: int = 3

static var hero: Combatant
static var hero_title: String = ""
static var fight_number: int = 1  # also the hero's level: one level up per win


static func start(draft: CharacterDraft) -> void:
	hero = Combatant.new(draft.hero_data())
	hero_title = "%s %s with %s" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name]
	fight_number = 1


## For running the combat scene on its own (F6 or the play tool without a run).
static func start_test() -> void:
	hero = Combatant.load_from("res://data/heroes.json", "test_hero")
	hero_title = "Test hero"
	fight_number = 1


static func enemy() -> Combatant:
	return Combatant.load_from("res://data/enemies.json", FIGHTS[fight_number - 1])


static func is_last_fight() -> bool:
	return fight_number == FIGHTS.size()


## 3 different random upgrades from data/upgrades.json.
static func upgrade_choices() -> Array:
	var pool: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	var choices: Array = []
	for i in UPGRADE_CHOICES:
		choices.append(pool.pop_at(Dice.roll(pool.size()) - 1))
	return choices
