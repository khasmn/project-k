class_name Peddler
## The Peddler's Cart (path Shop door): 4 random offers each visit, different from the town Shop:
## graded gear (also forge-only pieces), material bundles and potions. Haggle once per visit.
## An offer is {"kind": "gear" / "material" / "item", "id", "count", "grade" (gear only), "price"}.

const OFFERS: int = 4
const HAGGLE_DC: int = 12
const HAGGLE_RATES: Dictionary = {"haggle_win": 0.75, "haggle_fail": 1.0, "haggle_bad": 1.25}
const GEAR_MARKUP: int = 15  # extra gold per grade above Common
const MATERIAL_PRICE: int = 4  # per piece
const SHARD_PRICE: int = 80
const SHARD_CHANCE: int = 20  # a material offer is a Starmetal Shard on a natural 20

static var offers: Array[Dictionary] = []
static var rate: float = 1.0  # haggling changes all prices
static var haggled: bool = false


## A new visit: fresh offers, normal prices, haggling allowed again.
static func open_cart() -> void:
	rate = 1.0
	haggled = false
	offers = []
	for i in OFFERS:
		match Dice.roll(3, false):
			1: offers.append(_gear_offer())
			2: offers.append(_material_offer())
			3: offers.append(_item_offer())


static func price(offer: Dictionary) -> int:
	return ceili(offer.price * rate)


static func can_buy(offer: Dictionary) -> bool:
	return Run.gold >= price(offer)


static func buy(offer: Dictionary) -> void:
	Run.gold -= price(offer)
	offers.erase(offer)
	match offer.kind:
		"gear": Run.bag.append(Gear.piece(offer.id, offer.grade))
		"material": Run.materials[offer.id] = Run.materials.get(offer.id, 0) + offer.count
		"item": Run.items[offer.id] = Run.items.get(offer.id, 0) + offer.count


## d20 + Charisma vs DC 12: success = 25% off, natural 1 = 25% more. Returns {"outcome", "text"}.
static func haggle() -> Dictionary:
	haggled = true
	var result: Dictionary = Dice.check(Run.hero.charisma, HAGGLE_DC, Run.hero.roll_mode())
	var outcome: String = "haggle_bad" if result.fumble else ("haggle_win" if result.success else "haggle_fail")
	rate = HAGGLE_RATES[outcome]
	var effect: Dictionary = {"haggle_win": "25% off everything!", "haggle_fail": "no deal.", "haggle_bad": "a natural 1, prices up 25%!"}
	return {"outcome": outcome, "text": "Haggle: rolled %d %+d Charisma = %d vs DC %d: %s" % [
		result.natural, Run.hero.charisma, result.total, HAGGLE_DC, effect[outcome]]}


## "Rare Bandit Hood", "Iron Scrap x3", "Energy Tonic".
static func title(offer: Dictionary) -> String:
	match offer.kind:
		"gear": return Gear.title(Gear.piece(offer.id, offer.grade))
		"material": return "%s x%d" % [Run.data("materials")[offer.id].name, offer.count]
	return Run.data("items")[offer.id].name


## Gear that fits your class, already graded: d20 1-12 Uncommon, 13-18 Rare, 19-20 Epic.
## Never Starmetal gear: that stays the boss's reward.
static func _gear_offer() -> Dictionary:
	var recipes: Dictionary = Run.data("recipes")
	var ids: Array = Run.data("gear").keys().filter(func(id: String) -> bool:
		return Gear.fits(id) and recipes.get(id, {}).get("section", "") != "starmetal")
	var id: String = ids[Dice.roll(ids.size(), false) - 1]
	var rolled: int = Dice.roll(20, false)
	var grade: int = 2 if rolled <= 12 else (3 if rolled <= 18 else Gear.EPIC)
	return {"kind": "gear", "id": id, "grade": grade, "count": 1,
		"price": int(Gear.entry(id).price) + GEAR_MARKUP * Gear.GRADES[grade][2]}


static func _material_offer() -> Dictionary:
	if Dice.roll(SHARD_CHANCE, false) == SHARD_CHANCE:
		return {"kind": "material", "id": "starmetal_shard", "count": 1, "price": SHARD_PRICE}
	var ids: Array = Run.data("materials").keys().filter(func(id: String) -> bool: return not Run.data("materials")[id].get("kept", false))
	var count: int = Dice.roll(3, false) + 1
	return {"kind": "material", "id": ids[Dice.roll(ids.size(), false) - 1], "count": count, "price": MATERIAL_PRICE * count}


## Only potions the town Shop doesn't sell.
static func _item_offer() -> Dictionary:
	var ids: Array = Run.data("items").keys().filter(func(id: String) -> bool: return id != GearWindow.POTION)
	var id: String = ids[Dice.roll(ids.size(), false) - 1]
	return {"kind": "item", "id": id, "count": 1, "price": int(Run.data("items")[id].price)}
