extends SceneTree
## Peddler's Cart self-check: 4 offers, buying each kind, haggling (win, fail, natural 1), once per visit.
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_peddler.gd

var failed: bool = false


func _init() -> void:
	var draft: CharacterDraft = CharacterDraft.new()
	draft.class_id = "mage"
	Run.start(draft)
	Run.gold = 500
	for visit in 50:
		Peddler.open_cart()
		_check(Peddler.offers.size() == Peddler.OFFERS, "a visit should have 4 offers")
		for offer in Peddler.offers:
			_check(offer.kind != "gear" or (Gear.fits(offer.id) and offer.grade >= 2 and not offer.id.begins_with("starmetal")),
				"gear offers fit the class, are Uncommon+ and never Starmetal")
			_check(offer.id != GearWindow.POTION, "the cart doesn't sell the Shop's potion")
	var offer: Dictionary = {"kind": "item", "id": "energy_tonic", "count": 1, "price": 20}
	Peddler.offers = [offer]
	Peddler.buy(offer)
	_check(Run.gold == 480 and Run.items.energy_tonic == 1 and Peddler.offers.is_empty(), "buying a potion failed")
	var gear: Dictionary = {"kind": "gear", "id": "ash_staff", "grade": 3, "count": 1, "price": 80}
	Peddler.buy(gear)
	_check(Run.bag.back() == Gear.piece("ash_staff", 3), "buying gear should add the graded piece")

	Run.hero.charisma = 2
	Dice.forced_rolls = [10]
	_check(Peddler.haggle().outcome == "haggle_win" and Peddler.price(gear) == 60 and Peddler.haggled, "10 + 2 vs DC 12 should win 25% off")
	Peddler.open_cart()
	_check(not Peddler.haggled and Peddler.rate == 1.0, "a new visit resets haggling")
	Dice.forced_rolls = [9]
	_check(Peddler.haggle().outcome == "haggle_fail" and Peddler.rate == 1.0, "9 + 2 should fail")
	Dice.forced_rolls = [1]
	_check(Peddler.haggle().outcome == "haggle_bad" and Peddler.price(gear) == 100, "a natural 1 raises prices 25%")

	if failed:
		quit(1)
		return
	print("Peddler OK")
	quit()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		print("FAIL: " + message)
