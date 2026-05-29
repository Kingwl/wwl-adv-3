class_name StarterCardCatalog
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")

const CARD_ID_WHIP := "whip"
const CARD_ID_MAGIC_WAND := "magic_wand"
const CARD_ID_LAUREL := "laurel"
const CARD_ID_EMPTY_TOME := "empty_tome"
const CARD_ID_KNIFE := "knife"
const CARD_ID_AXE := "axe"
const CARD_ID_CROSS := "cross"
const CARD_ID_KING_BIBLE := "king_bible"
const CARD_ID_FIRE_WAND := "fire_wand"
const CARD_ID_GARLIC := "garlic"
const CARD_ID_SANTA_WATER := "santa_water"
const CARD_ID_RUNETRACER := "runetracer"
const CARD_ID_LIGHTNING_RING := "lightning_ring"
const CARD_ID_PENTAGRAM := "pentagram"
const CARD_ID_PEACHONE := "peachone"
const CARD_ID_EBONY_WINGS := "ebony_wings"
const CARD_ID_SONG_OF_MANA := "song_of_mana"
const CARD_ID_BONE := "bone"
const CARD_ID_CHERRY_BOMB := "cherry_bomb"
const CARD_ID_SPELLBINDER := "spellbinder"
const CARD_ID_DUPLICATOR := "duplicator"


static func create_whip() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_WHIP,
		"鞭子",
		1,
		6,
		0,
		0,
		CardDefinition.TargetMode.FRONT_ROW
	)


static func create_magic_wand() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_MAGIC_WAND,
		"魔杖",
		2,
		9,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY
	)


static func create_laurel() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_LAUREL,
		"月桂",
		1,
		0,
		6,
		0,
		CardDefinition.TargetMode.SELF
	)


static func create_empty_tome() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_EMPTY_TOME,
		"空白之书",
		0,
		0,
		0,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_knife() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_KNIFE,
		"飞刀",
		0,
		3,
		0,
		0,
		CardDefinition.TargetMode.SINGLE_ENEMY,
		2
	)


static func create_axe() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_AXE,
		"斧头",
		2,
		8,
		0,
		0,
		CardDefinition.TargetMode.BOUNCE,
		3
	)


static func create_cross() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_CROSS,
		"十字架",
		1,
		5,
		0,
		0,
		CardDefinition.TargetMode.BOUNCE,
		2
	)


static func create_king_bible() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_KING_BIBLE,
		"国王圣经",
		2,
		5,
		7,
		0,
		CardDefinition.TargetMode.FRONT_ROW
	)


static func create_fire_wand() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_FIRE_WAND,
		"火焰魔杖",
		2,
		14,
		0,
		0,
		CardDefinition.TargetMode.RANDOM_ENEMIES
	)


static func create_garlic() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_GARLIC,
		"大蒜",
		1,
		3,
		5,
		0,
		CardDefinition.TargetMode.FRONT_ROW
	)


static func create_santa_water() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SANTA_WATER,
		"圣水",
		2,
		4,
		0,
		0,
		CardDefinition.TargetMode.RANDOM_ENEMIES,
		3
	)


static func create_runetracer() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_RUNETRACER,
		"符文追踪器",
		2,
		4,
		0,
		0,
		CardDefinition.TargetMode.BOUNCE,
		4
	)


static func create_lightning_ring() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_LIGHTNING_RING,
		"闪电戒指",
		2,
		8,
		0,
		0,
		CardDefinition.TargetMode.RANDOM_ENEMIES,
		2
	)


static func create_pentagram() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_PENTAGRAM,
		"五芒星",
		3,
		10,
		0,
		0,
		CardDefinition.TargetMode.ALL_ENEMIES
	)


static func create_peachone() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_PEACHONE,
		"白鸽",
		1,
		3,
		0,
		0,
		CardDefinition.TargetMode.RANDOM_ENEMIES,
		4
	)


static func create_ebony_wings() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_EBONY_WINGS,
		"黑翼",
		1,
		3,
		0,
		0,
		CardDefinition.TargetMode.RANDOM_ENEMIES,
		4
	)


static func create_song_of_mana() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SONG_OF_MANA,
		"法力之歌",
		2,
		5,
		0,
		1,
		CardDefinition.TargetMode.ALL_ENEMIES
	)


static func create_bone() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_BONE,
		"骨头",
		1,
		4,
		0,
		0,
		CardDefinition.TargetMode.BOUNCE,
		3
	)


static func create_cherry_bomb() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_CHERRY_BOMB,
		"樱桃炸弹",
		2,
		5,
		0,
		0,
		CardDefinition.TargetMode.ALL_ENEMIES
	)


static func create_spellbinder() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_SPELLBINDER,
		"拼写器",
		1,
		0,
		4,
		1,
		CardDefinition.TargetMode.SELF
	)


static func create_duplicator() -> CardDefinition:
	return CardDefinition.new(
		CARD_ID_DUPLICATOR,
		"复制器",
		1,
		0,
		0,
		2,
		CardDefinition.TargetMode.SELF
	)


static func create_starter_deck() -> Array:
	return create_cards_from_ids(starter_deck_card_ids())


static func starter_deck_card_ids() -> Array:
	return [
		CARD_ID_WHIP,
		CARD_ID_WHIP,
		CARD_ID_WHIP,
		CARD_ID_MAGIC_WAND,
		CARD_ID_MAGIC_WAND,
		CARD_ID_LAUREL,
		CARD_ID_LAUREL,
		CARD_ID_EMPTY_TOME,
	]


static func create_stage_1_reward_pool() -> Array:
	return create_cards_from_ids(stage_1_reward_card_ids())


static func stage_1_reward_card_ids() -> Array:
	return [
		CARD_ID_KNIFE,
		CARD_ID_AXE,
		CARD_ID_CROSS,
		CARD_ID_KING_BIBLE,
		CARD_ID_FIRE_WAND,
		CARD_ID_GARLIC,
		CARD_ID_SANTA_WATER,
		CARD_ID_RUNETRACER,
		CARD_ID_LIGHTNING_RING,
		CARD_ID_PENTAGRAM,
		CARD_ID_PEACHONE,
		CARD_ID_EBONY_WINGS,
		CARD_ID_SONG_OF_MANA,
		CARD_ID_BONE,
		CARD_ID_CHERRY_BOMB,
		CARD_ID_SPELLBINDER,
		CARD_ID_DUPLICATOR,
	]


static func create_card_by_id(card_id: String) -> CardDefinition:
	if card_id == CARD_ID_WHIP:
		return create_whip()
	if card_id == CARD_ID_MAGIC_WAND:
		return create_magic_wand()
	if card_id == CARD_ID_LAUREL:
		return create_laurel()
	if card_id == CARD_ID_EMPTY_TOME:
		return create_empty_tome()
	if card_id == CARD_ID_KNIFE:
		return create_knife()
	if card_id == CARD_ID_AXE:
		return create_axe()
	if card_id == CARD_ID_CROSS:
		return create_cross()
	if card_id == CARD_ID_KING_BIBLE:
		return create_king_bible()
	if card_id == CARD_ID_FIRE_WAND:
		return create_fire_wand()
	if card_id == CARD_ID_GARLIC:
		return create_garlic()
	if card_id == CARD_ID_SANTA_WATER:
		return create_santa_water()
	if card_id == CARD_ID_RUNETRACER:
		return create_runetracer()
	if card_id == CARD_ID_LIGHTNING_RING:
		return create_lightning_ring()
	if card_id == CARD_ID_PENTAGRAM:
		return create_pentagram()
	if card_id == CARD_ID_PEACHONE:
		return create_peachone()
	if card_id == CARD_ID_EBONY_WINGS:
		return create_ebony_wings()
	if card_id == CARD_ID_SONG_OF_MANA:
		return create_song_of_mana()
	if card_id == CARD_ID_BONE:
		return create_bone()
	if card_id == CARD_ID_CHERRY_BOMB:
		return create_cherry_bomb()
	if card_id == CARD_ID_SPELLBINDER:
		return create_spellbinder()
	if card_id == CARD_ID_DUPLICATOR:
		return create_duplicator()
	return null


static func create_cards_from_ids(card_ids: Array) -> Array:
	var cards: Array = []
	for raw_card_id in card_ids:
		var card := create_card_by_id(str(raw_card_id))
		if card != null:
			cards.append(card)
	return cards


static func has_card_id(card_id: String) -> bool:
	return create_card_by_id(card_id) != null
