class_name VisualAssetCatalog
extends RefCounted

const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")

const HERO_WALK_SHEET := "res://assets/generated/phase1/processed/hero_walk_4dir_v2/sheet-transparent.png"
const PICKUPS_EXIT_SHEET := "res://assets/generated/phase1/processed/pickups_exit_pack/sheet-transparent.png"
const SHARED_CARD_FX_SHEET := "res://assets/generated/phase1/processed/card_fx_atlas/sheet-transparent.png"
const DEDICATED_CARD_FX_SHEET := "res://assets/generated/phase2/processed/dedicated_card_fx_atlas/sheet-transparent.png"
const MAP_TILESET_CORE_SHEET := "res://assets/generated/phase3/processed/map_tileset_core/sheet-transparent.png"
const CARD_ICON_ATLAS_A_SHEET := "res://assets/generated/phase3/processed/card_icon_atlas_a/sheet-transparent.png"
const CARD_ICON_ATLAS_B_SHEET := "res://assets/generated/phase3/processed/card_icon_atlas_b/sheet-transparent.png"
const CARD_ICON_ATLAS_C_SHEET := "res://assets/generated/phase3/processed/card_icon_atlas_c/sheet-transparent.png"
const HERO_COMBAT_IDLE_SHEET := "res://assets/generated/phase3/processed/hero_combat_idle/sheet-transparent.png"
const HERO_COMBAT_ATTACK_SHEET := "res://assets/generated/phase3/processed/hero_combat_attack/sheet-transparent.png"
const HERO_COMBAT_CAST_SHEET := "res://assets/generated/phase3/processed/hero_combat_cast/sheet-transparent.png"
const HERO_COMBAT_GUARD_SHEET := "res://assets/generated/phase3/processed/hero_combat_guard/sheet-transparent.png"
const HERO_COMBAT_HURT_SHEET := "res://assets/generated/phase3/processed/hero_combat_hurt/sheet-transparent.png"
const HERO_COMBAT_DEATH_SHEET := "res://assets/generated/phase3/processed/hero_combat_death/sheet-transparent.png"
const HERO_WALK_DOWN_FRAMES := [1, 2, 3, 4]
const HERO_COMBAT_IDLE_FRAMES := [1, 2, 3, 4]
const HERO_COMBAT_ATTACK_FRAMES := [1, 2, 3, 4, 5, 6]
const HERO_COMBAT_CAST_FRAMES := [1, 2, 3, 4, 5, 6]
const HERO_COMBAT_GUARD_FRAMES := [1, 2, 3, 4]
const HERO_COMBAT_HURT_FRAMES := [1, 2, 3, 4]
const HERO_COMBAT_DEATH_FRAMES := [1, 2, 3, 4, 5, 6, 7, 8, 9]
const ENEMY_IDLE_FRAMES := [1, 2, 3, 4]
const ENEMY_HURT_FRAMES := [5, 6, 7, 8]
const ENEMY_DEATH_FRAMES := [9, 10, 11, 12]
const ENEMY_ATTACK_FRAMES := [1, 2, 3, 4, 5, 6]
const ENEMY_GUARD_FRAMES := [1, 2, 3, 4]
const CARD_ICON_FRAMES_PER_CARD := 4

const ENEMY_COMBAT_SHEETS := {
	"grunt": "res://assets/generated/phase1/processed/enemy_grunt_combat/sheet-transparent.png",
	"bat": "res://assets/generated/phase1/processed/enemy_bat_combat/sheet-transparent.png",
	"guard": "res://assets/generated/phase1/processed/enemy_guard_combat/sheet-transparent.png",
	"brute": "res://assets/generated/phase1/processed/enemy_brute_combat/sheet-transparent.png",
	"boss_guard": "res://assets/generated/phase1/processed/enemy_boss_guard_combat/sheet-transparent.png",
	"stage_boss": "res://assets/generated/phase1/processed/enemy_stage_boss_combat/sheet-transparent.png",
}

const ENEMY_ATTACK_SHEETS := {
	"grunt": "res://assets/generated/phase2/processed/enemy_grunt_attack/sheet-transparent.png",
	"bat": "res://assets/generated/phase2/processed/enemy_bat_attack/sheet-transparent.png",
	"guard": "res://assets/generated/phase2/processed/enemy_guard_attack/sheet-transparent.png",
	"brute": "res://assets/generated/phase2/processed/enemy_brute_attack/sheet-transparent.png",
	"boss_guard": "res://assets/generated/phase2/processed/enemy_boss_guard_attack/sheet-transparent.png",
	"stage_boss": "res://assets/generated/phase2/processed/enemy_stage_boss_attack/sheet-transparent.png",
}

const ENEMY_GUARD_SHEETS := {
	"guard": "res://assets/generated/phase2/processed/enemy_guard_guard/sheet-transparent.png",
	"brute": "res://assets/generated/phase2/processed/enemy_brute_guard/sheet-transparent.png",
	"boss_guard": "res://assets/generated/phase2/processed/enemy_boss_guard_guard/sheet-transparent.png",
}

const CARD_ICON_ROWS := {
	"whip": [CARD_ICON_ATLAS_A_SHEET, 0],
	"magic_wand": [CARD_ICON_ATLAS_A_SHEET, 1],
	"laurel": [CARD_ICON_ATLAS_A_SHEET, 2],
	"empty_tome": [CARD_ICON_ATLAS_A_SHEET, 3],
	"knife": [CARD_ICON_ATLAS_A_SHEET, 4],
	"axe": [CARD_ICON_ATLAS_A_SHEET, 5],
	"cross": [CARD_ICON_ATLAS_A_SHEET, 6],
	"king_bible": [CARD_ICON_ATLAS_B_SHEET, 0],
	"fire_wand": [CARD_ICON_ATLAS_B_SHEET, 1],
	"garlic": [CARD_ICON_ATLAS_B_SHEET, 2],
	"santa_water": [CARD_ICON_ATLAS_B_SHEET, 3],
	"runetracer": [CARD_ICON_ATLAS_B_SHEET, 4],
	"lightning_ring": [CARD_ICON_ATLAS_B_SHEET, 5],
	"pentagram": [CARD_ICON_ATLAS_B_SHEET, 6],
	"peachone": [CARD_ICON_ATLAS_C_SHEET, 0],
	"ebony_wings": [CARD_ICON_ATLAS_C_SHEET, 1],
	"song_of_mana": [CARD_ICON_ATLAS_C_SHEET, 2],
	"bone": [CARD_ICON_ATLAS_C_SHEET, 3],
	"cherry_bomb": [CARD_ICON_ATLAS_C_SHEET, 4],
	"spellbinder": [CARD_ICON_ATLAS_C_SHEET, 5],
	"duplicator": [CARD_ICON_ATLAS_C_SHEET, 6],
}

var _base_texture_cache: Dictionary = {}
var _region_texture_cache: Dictionary = {}


func player_map_texture(frame_index: int = 0) -> Texture2D:
	return _sheet_frame_from_sequence(HERO_WALK_SHEET, 4, 4, HERO_WALK_DOWN_FRAMES, frame_index)


func player_combat_texture(action: String = "idle", frame_index: int = 0) -> Texture2D:
	if action == "attack":
		return _sheet_frame_from_sequence(HERO_COMBAT_ATTACK_SHEET, 2, 3, HERO_COMBAT_ATTACK_FRAMES, frame_index)
	if action == "cast":
		return _sheet_frame_from_sequence(HERO_COMBAT_CAST_SHEET, 2, 3, HERO_COMBAT_CAST_FRAMES, frame_index)
	if action == "guard":
		return _sheet_frame_from_sequence(HERO_COMBAT_GUARD_SHEET, 2, 2, HERO_COMBAT_GUARD_FRAMES, frame_index)
	if action == "hurt":
		return _sheet_frame_from_sequence(HERO_COMBAT_HURT_SHEET, 2, 2, HERO_COMBAT_HURT_FRAMES, frame_index)
	if action == "death":
		return _sheet_frame_from_sequence(HERO_COMBAT_DEATH_SHEET, 3, 3, HERO_COMBAT_DEATH_FRAMES, frame_index)
	return _sheet_frame_from_sequence(HERO_COMBAT_IDLE_SHEET, 2, 2, HERO_COMBAT_IDLE_FRAMES, frame_index)


func tile_texture(tile_type: int, exit_unlocked: bool = false, frame_index: int = 0, stage_id: String = "") -> Texture2D:
	var is_graveyard := stage_id == "stage_2"
	if tile_type == DungeonTile.TileType.FLOOR:
		return _sheet_frame(MAP_TILESET_CORE_SHEET, 4, 4, 9 if is_graveyard else 1)
	if tile_type == DungeonTile.TileType.WALL:
		return _sheet_frame(MAP_TILESET_CORE_SHEET, 4, 4, 10 if is_graveyard else 2)
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
		if is_graveyard:
			return _sheet_frame(MAP_TILESET_CORE_SHEET, 4, 4, 15 if exit_unlocked else 14)
		return _sheet_frame(MAP_TILESET_CORE_SHEET, 4, 4, 6 if exit_unlocked else 5)
	if tile_type == DungeonTile.TileType.ENTRANCE:
		return _sheet_frame(MAP_TILESET_CORE_SHEET, 4, 4, 16 if is_graveyard else 7)
	if tile_type == DungeonTile.TileType.ENEMY:
		return enemy_texture("grunt", "idle", frame_index)
	if tile_type == DungeonTile.TileType.ELITE:
		return enemy_texture("brute", "idle", frame_index)
	if tile_type == DungeonTile.TileType.BOSS:
		return enemy_texture("stage_boss", "idle", frame_index)
	return null


func enemy_texture(visual_id: String, action: String = "idle", frame_index: int = 0) -> Texture2D:
	if action == "attack":
		var attack_sheet_path := str(ENEMY_ATTACK_SHEETS.get(visual_id, ""))
		if attack_sheet_path != "":
			return _sheet_frame_from_sequence(attack_sheet_path, 2, 3, ENEMY_ATTACK_FRAMES, frame_index)
	if action == "guard":
		var guard_sheet_path := str(ENEMY_GUARD_SHEETS.get(visual_id, ""))
		if guard_sheet_path != "":
			return _sheet_frame_from_sequence(guard_sheet_path, 2, 2, ENEMY_GUARD_FRAMES, frame_index)

	var sheet_path := str(ENEMY_COMBAT_SHEETS.get(visual_id, ""))
	if sheet_path == "":
		return null
	if action == "hurt":
		return _sheet_frame_from_sequence(sheet_path, 3, 4, ENEMY_HURT_FRAMES, frame_index)
	if action == "death":
		return _sheet_frame_from_sequence(sheet_path, 3, 4, ENEMY_DEATH_FRAMES, frame_index)
	return _sheet_frame_from_sequence(sheet_path, 3, 4, ENEMY_IDLE_FRAMES, frame_index)


func card_texture(card_id: String, frame_index: int = 0) -> Texture2D:
	var card_icon := _card_icon_texture(card_id, frame_index)
	if card_icon != null:
		return card_icon

	if card_id == "whip":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [1, 2, 3, 4], frame_index)
	if card_id == "king_bible":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [5, 6, 7, 8], frame_index)
	if card_id == "garlic":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [9, 10, 11, 12], frame_index)
	if card_id == "santa_water":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [13, 14, 15, 16], frame_index)
	if card_id == "pentagram":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [17, 18, 19, 20], frame_index)
	if card_id == "lightning_ring":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [21, 22, 23, 24], frame_index)
	if card_id == "magic_wand" or card_id == "knife" or card_id == "fire_wand":
		return _sheet_frame_from_sequence(SHARED_CARD_FX_SHEET, 6, 4, [1, 2, 3, 4], frame_index)
	if card_id == "axe" or card_id == "cross" or card_id == "runetracer" or card_id == "bone":
		return _sheet_frame_from_sequence(SHARED_CARD_FX_SHEET, 6, 4, [17, 18, 19, 20], frame_index)
	if card_id == "peachone" or card_id == "ebony_wings":
		return _sheet_frame_from_sequence(SHARED_CARD_FX_SHEET, 6, 4, [13, 14, 15, 16], frame_index)
	if card_id == "cherry_bomb" or card_id == "song_of_mana":
		return _sheet_frame_from_sequence(SHARED_CARD_FX_SHEET, 6, 4, [21, 22, 23, 24], frame_index)
	if card_id == "laurel" or card_id == "spellbinder":
		return _sheet_frame_from_sequence(DEDICATED_CARD_FX_SHEET, 6, 4, [5, 6, 7, 8], frame_index)
	if card_id == "empty_tome" or card_id == "duplicator":
		return _sheet_frame_from_sequence(SHARED_CARD_FX_SHEET, 6, 4, [17, 18, 19, 20], frame_index)
	return null


func _card_icon_texture(card_id: String, frame_index: int) -> Texture2D:
	if not CARD_ICON_ROWS.has(card_id):
		return null
	var card_info: Array = CARD_ICON_ROWS[card_id]
	var sheet_path := str(card_info[0])
	var row_index := int(card_info[1])
	var first_frame := row_index * CARD_ICON_FRAMES_PER_CARD + 1
	return _sheet_frame_from_sequence(
		sheet_path,
		7,
		CARD_ICON_FRAMES_PER_CARD,
		[first_frame, first_frame + 1, first_frame + 2, first_frame + 3],
		frame_index
	)


func _sheet_frame_from_sequence(path: String, rows: int, cols: int, frames: Array, frame_index: int) -> Texture2D:
	if frames.is_empty():
		return null
	var sequence_index := frame_index % frames.size()
	if sequence_index < 0:
		sequence_index += frames.size()
	return _sheet_frame(path, rows, cols, int(frames[sequence_index]))


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

	if ResourceLoader.exists(path, "Texture2D"):
		var imported_texture := load(path) as Texture2D
		if imported_texture != null:
			_base_texture_cache[path] = imported_texture
			return imported_texture

	if not FileAccess.file_exists(path):
		return null

	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_base_texture_cache[path] = texture
	return texture
