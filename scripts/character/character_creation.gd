extends Control
## Character creation screen: shows the rolled race and talent with their rerolls, and class buttons.

const RARITY_COLORS: Dictionary = {
	"common": Color(0.75, 0.75, 0.75), "uncommon": Color(0.4, 0.85, 0.4), "rare": Color(0.4, 0.6, 1.0),
	"epic": Color(0.75, 0.45, 1.0), "legendary": Color(1.0, 0.65, 0.2),
}

var draft: CharacterDraft
var class_group: ButtonGroup = ButtonGroup.new()


func _ready() -> void:
	%RerollRaceButton.pressed.connect(func() -> void: draft.reroll_race(); _refresh())
	%RerollTalentButton.pressed.connect(func() -> void: draft.reroll_talent(); _refresh())
	%NewHeroButton.pressed.connect(_new_hero)
	# One toggle button per class in classes.json. A ButtonGroup keeps only one pressed at a time.
	for id in CharacterDraft.new().classes:
		var button: Button = Button.new()
		button.toggle_mode = true
		button.button_group = class_group
		button.custom_minimum_size = Vector2(0, 36)
		button.pressed.connect(func() -> void: draft.class_id = id; _refresh())
		%ClassButtons.add_child(button)
	_new_hero()


func _new_hero() -> void:
	draft = CharacterDraft.new()
	for button in %ClassButtons.get_children():
		button.button_pressed = false
	_refresh()


func _refresh() -> void:
	var race: Dictionary = draft.races[draft.race_id]
	_show_rolled(%RaceName, race)
	%RaceInfo.text = "%s\n%s\nPassive: %s\nCheck: %s" % [
		race.role, _stat_changes(race.stats), race.passive, race.check_bonus]

	var talent: Dictionary = draft.talents[draft.talent_id]
	_show_rolled(%TalentName, talent)
	%TalentInfo.text = talent.effect

	var class_ids: Array = draft.classes.keys()
	for i in class_ids.size():
		%ClassButtons.get_child(i).text = draft.classes[class_ids[i]].name
	if draft.class_id == "":
		%ClassInfo.text = "Pick a class."
	else:
		var hero_class: Dictionary = draft.classes[draft.class_id]
		%ClassInfo.text = "%s\nWeapon: %s (d%d)\nEvolves at level 15: %s" % [
			hero_class.role, hero_class.weapon, hero_class.damage_die, hero_class.evolves]

	%RerollRaceButton.text = "Reroll race (%d left)" % draft.race_rerolls_left
	%RerollTalentButton.text = "Reroll talent (%d left)" % draft.talent_rerolls_left
	%RerollRaceButton.disabled = draft.race_rerolls_left == 0
	%RerollTalentButton.disabled = draft.talent_rerolls_left == 0
	%HeroSummary.text = _summary()


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
		return "Your hero: %s with %s. Pick a class to see the final stats." % [
			draft.races[draft.race_id].name, draft.talents[draft.talent_id].name]
	var s: Dictionary = draft.stats()
	return "Your hero: %s %s with %s\nHP %d   Attack %d   Magic %d   Defense %d   Speed %d   Charisma %d   Luck %d" % [
		draft.races[draft.race_id].name, draft.classes[draft.class_id].name, draft.talents[draft.talent_id].name,
		s.hp, s.attack, s.magic, s.defense, s.speed, s.charisma, s.luck]
