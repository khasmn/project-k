extends SceneTree
## Event self-check: every event in data/events.json is valid, and checks, costs and outcomes work.
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_events.gd

const OUTCOME_KEYS: Array[String] = ["text", "gold", "heal_percent", "damage", "exp", "items", "materials",
	"first", "stun_foes", "poison", "ally", "elite", "skip"]

var failed: bool = false


func _init() -> void:
	var draft: CharacterDraft = CharacterDraft.new()
	draft.class_id = "warrior"
	Run.start(draft)
	var events: Dictionary = Run.data("events")
	for id: String in events:
		for choice: Dictionary in events[id].choices:
			_check(choice.has("success"), "%s: every choice needs a success outcome" % id)
			_check(not choice.has("stat") or (choice.dc >= 10 and choice.dc <= 16 and choice.stat in Run.hero), "%s: bad check" % id)
			for outcome: Dictionary in [choice.success, choice.get("fail", {})]:
				for key: String in outcome:
					_check(key in OUTCOME_KEYS, "%s: unknown outcome %s" % [id, key])
				for item: String in outcome.get("items", {}):
					_check(Run.data("items").has(item), "%s: unknown item %s" % [id, item])
				for material: String in outcome.get("materials", {}):
					_check(Run.data("materials").has(material), "%s: unknown material %s" % [id, material])
				_check(not outcome.has("ally") or Run.data("allies").has(outcome.ally), "%s: unknown ally" % id)

	var bridge: Array = events.toll_bridge.choices
	Run.gold = 15
	_check(not RoomEvent.can_choose(bridge[0]), "can't pay a 20 gold toll with 15 gold")
	Run.hero.charisma = 1
	Dice.forced_rolls = [13]
	var result: Dictionary = RoomEvent.choose(bridge[1])
	_check(result.success and Run.next_fight.stun_foes and result.text.begins_with("Rolled 13 +1 Charisma = 14 vs DC 14: success!"),
		"13 + 1 meets DC 14: monsters start stunned")
	Dice.forced_rolls = [2]
	RoomEvent.choose(bridge[1])
	_check(Run.gold == 5, "a failed persuade costs 10 gold")
	Dice.forced_rolls = [2]
	RoomEvent.choose(bridge[1])
	_check(Run.gold == 0, "gold never goes below 0")
	Dice.forced_rolls = [1]
	RoomEvent.choose(bridge[2])
	_check(Run.room_type == "elite", "a failed intimidate makes the next fight elite")
	Run.hero.hp = 3
	Dice.forced_rolls = [1]
	RoomEvent.choose(bridge[3])
	_check(Run.hero.hp == 1, "an event's damage never kills")
	Dice.forced_rolls = [20]
	_check(RoomEvent.choose(bridge[3]).skip, "a good sneak skips the fight")

	Run.gold = 30
	RoomEvent.choose(events.hooded_stranger.choices[0])
	_check(Run.gold == 5 and Run.next_fight.ally == "sellsword", "hiring Bram costs 25 gold")
	Run.items = {}
	Dice.forced_rolls = [20]
	RoomEvent.choose(events.trapped_chest.choices[0])
	_check(Run.items.healing_potion == 1 and Run.materials.iron_scrap >= 2, "the disarmed chest gives a potion and scrap")
	Run.hero.advantage = true  # Chosen One: advantage on every check, events included
	Dice.forced_rolls = [2, 18]
	_check(RoomEvent.choose(events.old_shrine.choices[0]).success, "Chosen One keeps the higher of two d20s")
	Run.hero.advantage = false
	Run.events_seen.assign(events.keys().slice(1))
	_check(RoomEvent.pick() == events.keys()[0], "the last unseen event is picked without a die")
	Run.start(draft)
	_check(Run.next_fight.is_empty() and Run.events_seen.is_empty(), "a new hero starts clean")
	for i in 20:
		var door: String = RoomEvent.pick()
		_check(not door in Run.events_seen or Run.events_seen.size() == events.size(), "events don't repeat until all are seen")
		if not door in Run.events_seen:
			Run.events_seen.append(door)
	if failed:
		quit(1)
		return
	print("Events OK")
	quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + what)
