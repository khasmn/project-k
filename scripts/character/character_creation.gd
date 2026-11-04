extends Control
## Character creation screen: shows the rolled race and talent with their rerolls, and the class choice.

const MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const RARITY_COLORS: Dictionary = {
	"common": Color(0.75, 0.75, 0.75), "uncommon": Color(0.4, 0.85, 0.4), "rare": Color(0.4, 0.6, 1.0),
	"epic": Color(0.75, 0.45, 1.0), "legendary": Color(1.0, 0.65, 0.2),
}
const SPIN_STEPS: int = 14

var draft: CharacterDraft
var spinning: int = 0  # how many names are still spinning; buttons wait until they land
var race_button: Button
var talent_button: Button
var start_button: Button


func _ready() -> void:
	race_button = UI.menu_button("", _reroll.bind("race"))
	talent_button = UI.menu_button("", _reroll.bind("talent"))
	%RaceActions.add_child(race_button)
	%TalentActions.add_child(talent_button)
	for id in CharacterDraft.new().classes:
		%ClassButtons.add_child(UI.menu_button("", func() -> void: draft.class_id = id; _refresh(), 20))
	start_button = UI.menu_button("Start run", _start_run, 22)
	for button: Button in [UI.menu_button("Back", get_tree().change_scene_to_file.bind(MENU_SCENE), 22),
			UI.menu_button("New hero", _new_hero, 22), start_button]:
		%BottomButtons.add_child(button)
	_new_hero()


func _new_hero() -> void:
	draft = CharacterDraft.new()
	_spin(%RaceName, draft.races, "race")
	_spin(%TalentName, draft.talents, "talent")


func _reroll(kind: String) -> void:
	draft.reroll(kind)
	_spin(%RaceName if kind == "race" else %TalentName, draft.races if kind == "race" else draft.talents, kind)


## Slot-machine look: the name flicks through the other entries, slowing down, then lands on the
## real roll (already made by the draft through the dice module) and flashes.
func _spin(label: Label, entries: Dictionary, kind: String) -> void:
	spinning += 1
	_refresh()
	var ids: Array = entries.keys()
	for i in SPIN_STEPS:
		_show_rolled(label, entries[ids[i % ids.size()]])
		await get_tree().create_timer(0.03 + i * 0.012).timeout
	spinning -= 1
	_refresh()
	label.modulate = Color(2, 2, 2)  # brighter than normal, fading back = a flash
	create_tween().tween_property(label, "modulate", Color.WHITE, 0.5)


func _refresh() -> void:
	var race: Dictionary = draft.races[draft.race_id]
	var talent: Dictionary = draft.talents[draft.talent_id]
	if spinning == 0:
		_show_rolled(%RaceName, race)
		_show_rolled(%TalentName, talent)
	%RaceInfo.text = "" if spinning else "%s\n%s\nPassive: %s\nCheck: %s" % [
		race.role, _stat_changes(race.stats), race.passive, race.check_bonus]
	%TalentInfo.text = "" if spinning else talent.effect

	var class_ids: Array = draft.classes.keys()
	for i in class_ids.size():
		var button: Button = %ClassButtons.get_child(i)
		button.text = button.text.left(3) + draft.classes[class_ids[i]].name
		button.add_theme_color_override("font_color", UI.GOLD if class_ids[i] == draft.class_id else Color.WHITE)
	if draft.class_id == "":
		%ClassInfo.text = "Pick a class."
	else:
		var hero_class: Dictionary = draft.classes[draft.class_id]
		%ClassInfo.text = "%s\nWeapon: %s (d%d)\nEvolves at level 15: %s" % [
			hero_class.role, hero_class.weapon, hero_class.damage_die, hero_class.evolves]

	race_button.text = race_button.text.left(3) + "Reroll race (%d left)" % draft.race_rerolls_left
	talent_button.text = talent_button.text.left(3) + "Reroll talent (%d left)" % draft.talent_rerolls_left
	race_button.disabled = spinning > 0 or draft.race_rerolls_left == 0
	talent_button.disabled = spinning > 0 or draft.talent_rerolls_left == 0
	%HeroSummary.text = "Rolling..." if spinning else _summary()
	start_button.disabled = spinning > 0 or draft.class_id == ""


func _start_run() -> void:
	Run.start(draft)
	get_tree().change_scene_to_file("res://scenes/combat/combat.tscn")


func _show_rolled(label: Label, entry: Dictionary) -> void:
	label.text = "%s  (%s)" % [entry.name, entry.rarity.capitalize()]
	label.add_theme_color_override("font_color", RARITY_COLORS[entry.rarity])


## "+2 Attack, -1 Charisma"
func _stat_changes(changes: Dictionary) -> String:
	var parts: PackedStringArray = []
	for stat in changes:
		parts.append("%+d %s" % [int(changes[stat]), "HP" if stat == "hp" else stat.capitalize()])
	return ", ".join(parts)


func _summary() -> String:
	if draft.class_id == "":
		return "%s with %s. Pick a class to see the final stats." % [
			draft.races[draft.race_id].name, draft.talents[draft.talent_id].name]
	var s: Dictionary = draft.stats()
	return "%s %s with %s\nHP %d   Attack %d   Magic %d   Defense %d   Speed %d   Charisma %d   Luck %d" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name,
		s.hp, s.attack, s.magic, s.defense, s.speed, s.charisma, s.luck]
