class_name Gear
## Gear rules: buying, selling, wearing and taking off (data/gear.json). The state lives in Run:
## Run.bag (ids you carry) and Run.gear (slot -> id you wear). Worn gear adds its "stats" to the hero
## and shows on the hero sprite (helmet, armor, shield; a weapon gets a "tint").

const SLOTS: Array[String] = ["helmet", "armor", "weapon", "offhand", "jewelry1", "jewelry2"]
const SELL_RATE: float = 0.5  # gear sells back for half its price
const STAT_NAMES: Dictionary = {"defense": "Defense", "max_hp": "Max HP", "speed": "Speed"}


static func entry(id: String) -> Dictionary:
	return Run.data("gear")[id]


## Some gear is for certain classes only ("classes"); everything else fits anyone.
static func fits(id: String) -> bool:
	var classes: Array = entry(id).get("classes", [])
	return classes.is_empty() or Run.hero_look.get("class", "") in classes


static func buy(id: String) -> void:
	Run.gold -= int(entry(id).price)
	Run.bag.append(id)


static func sell_price(id: String) -> int:
	return int(entry(id).price * SELL_RATE)


static func sell(id: String) -> void:
	Run.bag.erase(id)
	Run.gold += sell_price(id)


## Wear a piece from the bag; whatever was in its slot goes back to the bag.
static func wear(id: String) -> void:
	var slot: String = entry(id).slot
	if slot == "jewelry":  # two jewelry slots: the first free one, or swap the first
		slot = "jewelry2" if Run.gear.has("jewelry1") and not Run.gear.has("jewelry2") else "jewelry1"
	if Run.gear.has(slot):
		take_off(slot)
	Run.bag.erase(id)
	Run.gear[slot] = id
	_apply(id, 1)


static func take_off(slot: String) -> void:
	var id: String = Run.gear[slot]
	Run.gear.erase(slot)
	Run.bag.append(id)
	_apply(id, -1)


## "+1 Defense, -1 Speed". Attack says Magic for a Mage.
static func bonus_text(id: String) -> String:
	var parts: PackedStringArray = []
	var stats: Dictionary = entry(id).stats
	for stat in stats:
		parts.append("%+d %s" % [stats[stat], Run.hero.attack_name if stat == "attack" else STAT_NAMES[stat]])
	return ", ".join(parts)


## Add (direction 1) or remove (-1) a piece's stats, then update what the hero sprite shows.
static func _apply(id: String, direction: int) -> void:
	var stats: Dictionary = entry(id).stats
	for stat in stats:
		Run.hero.raise_stat(stat, direction * int(stats[stat]))
	Run.hero.hp = clampi(Run.hero.hp, 1, Run.hero.max_hp)
	for slot in ["helmet", "armor", "offhand"]:
		Run.hero_look[slot] = Run.gear.get(slot, "")
	var tint: Array = entry(Run.gear.weapon).get("tint", [1, 1, 1]) if Run.gear.has("weapon") else [1, 1, 1]
	Run.hero_look.weapon_tint = Color(tint[0], tint[1], tint[2])
