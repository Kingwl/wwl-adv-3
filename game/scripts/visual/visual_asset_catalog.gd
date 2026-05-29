class_name VisualAssetCatalog
extends RefCounted

const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")

const HERO_WALK_SHEET := "res://assets/generated/phase1/processed/hero_walk_4dir_v2/sheet-transparent.png"
const PICKUPS_EXIT_SHEET := "res://assets/generated/phase1/processed/pickups_exit_pack/sheet-transparent.png"
const SHARED_CARD_FX_SHEET := "res://assets/generated/phase1/processed/card_fx_atlas/sheet-transparent.png"
const DEDICATED_CARD_FX_SHEET := "res://assets/generated/phase2/processed/dedicated_card_fx_atlas/sheet-transparent.png"

const ENEMY_COMBAT_SHEETS := {
	"grunt": "res://assets/generated/phase1/processed/enemy_grunt_combat/sheet-transparent.png",
	"bat": "res://assets/generated/phase1/processed/enemy_bat_combat/sheet-transparent.png",
	"guard": "res://assets/generated/phase1/processed/enemy_guard_combat/sheet-transparent.png",
	"brute": "res://assets/generated/phase1/processed/enemy_brute_combat/sheet-transparent.png",
	"boss_guard": "res://assets/generated/phase1/processed/enemy_boss_guard_combat/sheet-transparent.png",
	"stage_boss": "res://assets/generated/phase1/processed/enemy_stage_boss_combat/sheet-transparent.png",
}

var _base_texture_cache: Dictionary = {}
var _region_texture_cache: Dictionary = {}


func player_map_texture() -> Texture2D:
	return _sheet_frame(HERO_WALK_SHEET, 4, 4, 1)


func tile_texture(tile_type: int, exit_unlocked: bool = false) -> Texture2D:
	if tile_type == DungeonTile.TileType.TREASURE:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 1)
	if tile_type == DungeonTile.TileType.HEALING:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 2)
	if tile_type == DungeonTile.TileType.XP_GEM:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 3)
	if tile_type == DungeonTile.TileType.FORGE:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 4)
	if tile_type == DungeonTile.TileType.SHRINE:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 5)
	if tile_type == DungeonTile.TileType.HAZARD:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 6)
	if tile_type == DungeonTile.TileType.EXIT:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 8 if exit_unlocked else 7)
	if tile_type == DungeonTile.TileType.ENTRANCE:
		return _sheet_frame(PICKUPS_EXIT_SHEET, 3, 3, 9)
	if tile_type == DungeonTile.TileType.ENEMY:
		return enemy_texture("grunt")
	if tile_type == DungeonTile.TileType.ELITE:
		return enemy_texture("brute")
	if tile_type == DungeonTile.TileType.BOSS:
		return enemy_texture("stage_boss")
	return null


func enemy_texture(visual_id: String) -> Texture2D:
	var sheet_path := str(ENEMY_COMBAT_SHEETS.get(visual_id, ""))
	if sheet_path == "":
		return null
	return _sheet_frame(sheet_path, 3, 4, 1)


func card_texture(card_id: String) -> Texture2D:
	if card_id == "whip":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 3)
	if card_id == "king_bible":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 6)
	if card_id == "garlic":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 10)
	if card_id == "santa_water":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 14)
	if card_id == "pentagram":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 18)
	if card_id == "lightning_ring":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 22)
	if card_id == "magic_wand" or card_id == "knife" or card_id == "fire_wand":
		return _sheet_frame(SHARED_CARD_FX_SHEET, 6, 4, 1)
	if card_id == "axe" or card_id == "cross" or card_id == "runetracer" or card_id == "bone":
		return _sheet_frame(SHARED_CARD_FX_SHEET, 6, 4, 17)
	if card_id == "peachone" or card_id == "ebony_wings":
		return _sheet_frame(SHARED_CARD_FX_SHEET, 6, 4, 13)
	if card_id == "cherry_bomb" or card_id == "song_of_mana":
		return _sheet_frame(SHARED_CARD_FX_SHEET, 6, 4, 21)
	if card_id == "laurel" or card_id == "spellbinder":
		return _sheet_frame(DEDICATED_CARD_FX_SHEET, 6, 4, 6)
	if card_id == "empty_tome" or card_id == "duplicator":
		return _sheet_frame(SHARED_CARD_FX_SHEET, 6, 4, 17)
	return null


func _sheet_frame(path: String, rows: int, cols: int, one_based_frame: int) -> Texture2D:
	if path == "" or rows <= 0 or cols <= 0 or one_based_frame <= 0:
		return null
	var cache_key := "%s|%s|%s|%s" % [path, rows, cols, one_based_frame]
	if _region_texture_cache.has(cache_key):
		return _region_texture_cache[cache_key]

	var base_texture := _load_texture(path)
	if base_texture == null:
		return null

	var frame_index := one_based_frame - 1
	var row := int(frame_index / cols)
	var col := int(frame_index % cols)
	if row >= rows:
		return null

	var cell_width := int(base_texture.get_width() / cols)
	var cell_height := int(base_texture.get_height() / rows)
	if cell_width <= 0 or cell_height <= 0:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = base_texture
	atlas.region = Rect2(col * cell_width, row * cell_height, cell_width, cell_height)
	_region_texture_cache[cache_key] = atlas
	return atlas


func _load_texture(path: String) -> Texture2D:
	if _base_texture_cache.has(path):
		return _base_texture_cache[path]

	if not FileAccess.file_exists(path):
		return null

	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_base_texture_cache[path] = texture
	return texture
