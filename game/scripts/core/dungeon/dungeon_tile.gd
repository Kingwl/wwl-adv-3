class_name DungeonTile
extends RefCounted

enum TileType {
	WALL,
	FLOOR,
	ENTRANCE,
	EXIT,
	TREASURE,
	HEALING,
	SHRINE,
	FORGE,
	HAZARD,
	ENEMY,
	ELITE,
	BOSS,
}

var tile_type: int
var occupant_id: String
var seen: bool
var visible: bool


func _init(
	p_tile_type: int = TileType.FLOOR,
	p_occupant_id: String = "",
	p_seen: bool = false,
	p_visible: bool = false
) -> void:
	tile_type = p_tile_type
	occupant_id = p_occupant_id
	seen = p_seen
	visible = p_visible


func duplicate_tile():
	return get_script().new(tile_type, occupant_id, seen, visible)


func is_enemy_tile() -> bool:
	return tile_type == TileType.ENEMY or tile_type == TileType.ELITE or tile_type == TileType.BOSS


func is_pickup_tile() -> bool:
	return (
		tile_type == TileType.TREASURE
		or tile_type == TileType.HEALING
		or tile_type == TileType.SHRINE
		or tile_type == TileType.FORGE
		or tile_type == TileType.HAZARD
	)


func is_exit_tile() -> bool:
	return tile_type == TileType.EXIT


func blocks_movement() -> bool:
	return tile_type == TileType.WALL or is_enemy_tile()


func clear_to_floor() -> void:
	tile_type = TileType.FLOOR
	occupant_id = ""
