class_name DiceTray
extends HBoxContainer
## Dice tumbling in the middle of the battle area, landing on rolls the Dice module already made.
## Only for show: the results are decided before the animation starts.

const SPIN_TIME: float = 0.6
const HOLD_TIME: float = 0.25
const DIE_SIZE: int = 72
const INK: Color = Color(0.16, 0.12, 0.12)


## Show the rolls noted since the last call. Rolls of the same die land together
## (both d20s of advantage, or both initiative d20s); a different die starts a new throw.
func show_rolls() -> void:
	var rolls: Array = Dice.history.duplicate()
	Dice.history.clear()
	while not rolls.is_empty():
		var sides: int = rolls[0][0]
		var results: Array[int] = []
		while not rolls.is_empty() and rolls[0][0] == sides:
			results.append(rolls.pop_front()[1])
		await _throw(sides, results)


func _throw(sides: int, results: Array[int]) -> void:
	var numbers: Array[Label] = []
	for value in results:
		var die: TextureRect = TextureRect.new()
		die.texture = load("res://assets/sprites/ui/%s.png" % ("d20" if sides == 20 else "die"))
		die.custom_minimum_size = Vector2(DIE_SIZE, DIE_SIZE)
		die.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # keep the die square, not stretched to the area
		die.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		die.pivot_offset = Vector2(DIE_SIZE, DIE_SIZE) / 2  # spin around the middle
		var number: Label = Label.new()
		number.set_anchors_preset(Control.PRESET_FULL_RECT)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 24)
		number.add_theme_color_override("font_color", INK)
		die.add_child(number)
		add_child(die)
		numbers.append(number)
		# A tween animates a property over time: here two fast turns slowing to a stop.
		create_tween().tween_property(die, "rotation", 0.0, SPIN_TIME).from(TAU * 2) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var start: int = Time.get_ticks_msec()
	var step: int = 0
	while Time.get_ticks_msec() - start < SPIN_TIME * 1000:
		for i in numbers.size():
			numbers[i].text = str((results[i] + step * 7) % sides + 1)  # flicking faces, not a real roll
		step += 1
		await get_tree().create_timer(0.04 + 0.1 * (Time.get_ticks_msec() - start) / (SPIN_TIME * 1000)).timeout
	for i in numbers.size():
		numbers[i].text = str(results[i])
		if sides == 20 and results[i] in [1, 20]:  # natural 20 gold, natural 1 red
			numbers[i].get_parent().modulate = Color(1, 0.85, 0.35) if results[i] == 20 else Color(1, 0.5, 0.45)
	await get_tree().create_timer(HOLD_TIME).timeout
	for die in get_children():
		die.queue_free()
