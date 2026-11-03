extends SceneTree
## Character creation self-check. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_character.gd

const ROLLS: int = 20000

var failed: bool = false


func _init() -> void:
	var draft: CharacterDraft = CharacterDraft.new()

	# Races: each rarity comes up about as often as its chance.
	var counts: Dictionary = _rarity_counts(draft.races)
	for rarity in CharacterDraft.RARITY_CHANCES:
		var percent: float = 100.0 * counts.get(rarity, 0) / ROLLS
		_check(absf(percent - CharacterDraft.RARITY_CHANCES[rarity]) < 1.5, "race %s at %.1f%%" % [rarity, percent])

	# A rarity with no entries never comes up; the others scale up (Common becomes 50/98).
	var no_legendary: Dictionary = draft.talents.duplicate()
	no_legendary.erase("chosen_one")
	var talent_counts: Dictionary = _rarity_counts(no_legendary)
	_check(not talent_counts.has("legendary"), "rolled a talent rarity that doesn't exist")
	_check(absf(100.0 * talent_counts.common / ROLLS - 51.0) < 1.5, "talent chances didn't scale up")

	# 5 rerolls shared between race and talent, then no more.
	for i in 3:
		_check(draft.reroll_race(), "race reroll refused early")
	for i in 2:
		_check(draft.reroll_talent(), "talent reroll refused early")
	_check(draft.rerolls_left == 0, "reroll counter wrong")
	_check(not draft.reroll_race() and not draft.reroll_talent(), "6th reroll allowed")

	# Stats = class base + race change.
	draft.race_id = "glimmerfae"
	draft.class_id = "mage"
	var stats: Dictionary = draft.stats()
	_check(stats.hp == 16 and stats.magic == 7 and stats.attack == 0, "stats math wrong: %s" % stats)

	if failed:
		quit(1)
		return
	print("Character OK  (races: %s)" % counts)
	quit()


func _rarity_counts(entries: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for i in ROLLS:
		var rarity: String = entries[CharacterDraft.roll_by_rarity(entries)].rarity
		counts[rarity] = counts.get(rarity, 0) + 1
	return counts


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
