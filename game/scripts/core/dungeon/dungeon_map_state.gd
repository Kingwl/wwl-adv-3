class_name DungeonMapState
extends RefCounted

const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const StageConfig = preload("res://scripts/core/dungeon/stage_config.gd")

const EVENT_NO_OP := "no_op"
const EVENT_MOVED := "moved"
const EVENT_BLOCKED := "blocked"
const EVENT_PICKUP_COLLECTED := "pickup_collected"
const EVENT_ENCOUNTER_STARTED := "encounter_started"
const EVENT_STAGE_EXIT_REQUESTED := "stage_exit_requested"

var stage_config: StageConfig = StageConfig.new()
var width: int = 1
var height: int = 1
var tiles: Array = []
var player_position: Vector2i = Vector2i.ZERO
var entrance_position: Vector2i = Vector2i.ZERO
var exit_position: Vector2i = Vector2i.ZERO
var enemy_positions: Dictionary = {}
var pickup_positions: Dictionary = {}
var defeated_enemy_ids: Array = []
var defeated_boss_ids: Array = []
var collected_pickup_ids: Array = []


func setup_from_rows(p_stage_config: StageConfig, rows: Array) -> void:
	stage_config = p_stage_config.duplicate_config()
	width = _row_width(rows)
	height = max(rows.size(), 1)
	tiles.clear()
	enemy_positions.clear()
	pickup_positions.clear()
	defeated_enemy_ids.clear()
	defeated_boss_ids.clear()
	collected_pickup_ids.clear()
	player_position = Vector2i.ZERO
	entrance_position = Vector2i.ZERO
	exit_position = Vector2i.ZERO

	var enemy_count := 0
	var pickup_count := 0
	for y in range(height):
		var row_tiles: Array = []
		var row := ""
		if y < rows.size():
			row = str(rows[y])

		for x in range(width):
			var marker := "#"
			if x < row.length():
				marker = row.substr(x, 1)

			var position := Vector2i(x, y)
			var tile := _tile_from_marker(marker, position, enemy_count, pickup_count)
			if tile.is_enemy_tile():
				enemy_count += 1
			if tile.is_pickup_tile():
				pickup_count += 1
			row_tiles.append(tile)
		tiles.append(row_tiles)


func move_player(direction: Vector2i) -> Dictionary:
	if direction == Vector2i.ZERO:
		return _event(EVENT_NO_OP, "zero_direction", player_position, player_position)
	if abs(direction.x) + abs(direction.y) != 1:
		return _event(EVENT_BLOCKED, "non_cardinal_direction", player_position, player_position)

	var target_position := player_position + direction
	if not is_in_bounds(target_position):
		return _event(EVENT_BLOCKED, "out_of_bounds", player_position, target_position)

	var target_tile: DungeonTile = get_tile(target_position)
	if target_tile.tile_type == DungeonTile.TileType.WALL:
		return _event(EVENT_BLOCKED, "wall", player_position, target_position, target_tile)
	if target_tile.is_enemy_tile():
		return _event(EVENT_ENCOUNTER_STARTED, "enemy", player_position, target_position, target_tile)
	if target_tile.is_exit_tile():
		if is_exit_unlocked():
			return _event(EVENT_STAGE_EXIT_REQUESTED, "exit", player_position, target_position, target_tile)
		return _event(EVENT_BLOCKED, "locked_exit", player_position, target_position, target_tile)
	if target_tile.is_pickup_tile():
		player_position = target_position
		var pickup_event := _event(
			EVENT_PICKUP_COLLECTED,
			"pickup",
			player_position - direction,
			target_position,
			target_tile
		)
		_collect_pickup(target_tile.occupant_id, target_tile)
		return pickup_event

	player_position = target_position
	return _event(EVENT_MOVED, "floor", player_position - direction, target_position, target_tile)


func mark_enemy_defeated(enemy_id: String) -> bool:
	if not enemy_positions.has(enemy_id):
		return false

	var enemy_position: Vector2i = enemy_positions[enemy_id]
	var tile: DungeonTile = get_tile(enemy_position)
	if tile.tile_type == DungeonTile.TileType.BOSS and not defeated_boss_ids.has(enemy_id):
		defeated_boss_ids.append(enemy_id)
	if not defeated_enemy_ids.has(enemy_id):
		defeated_enemy_ids.append(enemy_id)

	enemy_positions.erase(enemy_id)
	tile.clear_to_floor()
	return true


func is_exit_unlocked() -> bool:
	return stage_config.is_exit_unlocked(defeated_enemy_ids.size(), not defeated_boss_ids.is_empty())


func is_in_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < width and position.y < height


func get_tile(position: Vector2i) -> DungeonTile:
	if not is_in_bounds(position):
		return null
	return tiles[position.y][position.x]


func active_enemy_count() -> int:
	return enemy_positions.size()


func active_pickup_count() -> int:
	return pickup_positions.size()


func to_debug_string() -> String:
	var lines: Array = []
	for y in range(height):
		var line := ""
		for x in range(width):
			var position := Vector2i(x, y)
			if position == player_position:
				line += "P"
			else:
				line += _marker_from_tile(tiles[y][x])
		lines.append(line)
	return "\n".join(lines)


func _collect_pickup(pickup_id: String, tile: DungeonTile) -> void:
	if pickup_id != "":
		if not collected_pickup_ids.has(pickup_id):
			collected_pickup_ids.append(pickup_id)
		pickup_positions.erase(pickup_id)
	tile.clear_to_floor()


func _event(
	event_type: String,
	reason: String,
	from_position: Vector2i,
	to_position: Vector2i,
	tile: DungeonTile = null
) -> Dictionary:
	var result := {
		"type": event_type,
		"reason": reason,
		"from": from_position,
		"to": to_position,
		"tile_type": -1,
		"occupant_id": "",
	}
	if tile != null:
		result["tile_type"] = tile.tile_type
		result["occupant_id"] = tile.occupant_id
	return result


func _tile_from_marker(
	marker: String,
	position: Vector2i,
	enemy_count: int,
	pickup_count: int
) -> DungeonTile:
	if marker == "#":
		return DungeonTile.new(DungeonTile.TileType.WALL)
	if marker == "P":
		player_position = position
		entrance_position = position
		return DungeonTile.new(DungeonTile.TileType.ENTRANCE)
	if marker == "E":
		exit_position = position
		return DungeonTile.new(DungeonTile.TileType.EXIT)
	if marker == "m":
		return _create_enemy_tile(DungeonTile.TileType.ENEMY, "enemy_%02d" % [enemy_count + 1], position)
	if marker == "e":
		return _create_enemy_tile(DungeonTile.TileType.ELITE, "elite_%02d" % [enemy_count + 1], position)
	if marker == "B":
		return _create_enemy_tile(DungeonTile.TileType.BOSS, "boss_%02d" % [enemy_count + 1], position)
	if marker == "C":
		return _create_pickup_tile(DungeonTile.TileType.TREASURE, "treasure_%02d" % [pickup_count + 1], position)
	if marker == "H":
		return _create_pickup_tile(DungeonTile.TileType.HEALING, "healing_%02d" % [pickup_count + 1], position)
	if marker == "S":
		return _create_pickup_tile(DungeonTile.TileType.SHRINE, "shrine_%02d" % [pickup_count + 1], position)
	if marker == "F":
		return _create_pickup_tile(DungeonTile.TileType.FORGE, "forge_%02d" % [pickup_count + 1], position)
	if marker == "^":
		return _create_pickup_tile(DungeonTile.TileType.HAZARD, "hazard_%02d" % [pickup_count + 1], position)

	return DungeonTile.new(DungeonTile.TileType.FLOOR)


func _create_enemy_tile(tile_type: int, enemy_id: String, position: Vector2i) -> DungeonTile:
	enemy_positions[enemy_id] = position
	return DungeonTile.new(tile_type, enemy_id)


func _create_pickup_tile(tile_type: int, pickup_id: String, position: Vector2i) -> DungeonTile:
	pickup_positions[pickup_id] = position
	return DungeonTile.new(tile_type, pickup_id)


func _marker_from_tile(tile: DungeonTile) -> String:
	if tile.tile_type == DungeonTile.TileType.WALL:
		return "#"
	if tile.tile_type == DungeonTile.TileType.ENTRANCE:
		return "."
	if tile.tile_type == DungeonTile.TileType.EXIT:
		return "E"
	if tile.tile_type == DungeonTile.TileType.ENEMY:
		return "m"
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return "e"
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return "B"
	if tile.tile_type == DungeonTile.TileType.TREASURE:
		return "C"
	if tile.tile_type == DungeonTile.TileType.HEALING:
		return "H"
	if tile.tile_type == DungeonTile.TileType.SHRINE:
		return "S"
	if tile.tile_type == DungeonTile.TileType.FORGE:
		return "F"
	if tile.tile_type == DungeonTile.TileType.HAZARD:
		return "^"
	return "."


func _row_width(rows: Array) -> int:
	var row_width := stage_config.width
	for row in rows:
		row_width = max(row_width, str(row).length())
	return max(row_width, 1)
