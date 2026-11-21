class_name GameLogic
extends Node
## The match rules: paint budgets, paint pools and stomps.

@export var map: Map
@export var frogs: Dictionary[int, Frog] = {}
@export var paint_budget: int = 10000
## Each player's paint pool cell; the pool takes that frog's starting colour.
@export var pool_cells: Dictionary[int, Vector2i] = {}
@export var pool_scene: PackedScene

var _paint_budgets: Dictionary[int, int] = {}
var _pool_cells: Dictionary[Vector2i, PaintPool] = {}
var _player_colors: Dictionary[int, Color] = {}


func _ready() -> void:
	assert(map != null, "GameLogic needs its map export set")
	assert(not frogs.is_empty(), "GameLogic needs at least one frog in its frogs export")
	assert(pool_scene != null, "GameLogic needs its pool_scene export set")
	assert(pool_cells.keys() == frogs.keys(), "GameLogic needs one pool cell per player id (frogs %s, pool_cells %s)" % [frogs.keys(), pool_cells.keys()])
	for player_id in frogs:
		var frog := frogs[player_id]
		assert(frog != null, "GameLogic's frogs export has no frog for player %d" % player_id)
		_set_paint(player_id, paint_budget)
		frog.jumped.connect(_on_frog_jumped.bind(player_id))
		_place_pool(player_id, pool_cells[player_id], frog.color)
		_player_colors[player_id] = frog.color


func _place_pool(player_id: int, cell: Vector2i, color: Color) -> void:
	assert(map.get_cell_source_id(cell) != -1, "player %d's pool cell %s is not on a tile" % [player_id, cell])
	assert(cell not in _pool_cells, "player %d's pool cell %s is taken by another pool" % [player_id, cell])
	
	# Spawn the pool
	var pool: PaintPool = pool_scene.instantiate()
	pool.name = "PaintPool%d" % player_id
	pool.color = color
	var world := map.get_parent()
	world.add_child(pool)
	# Make visible
	world.move_child(pool, map.get_index() + 1)
	pool.global_position = map.to_global(map.map_to_local(cell))
	_pool_cells[cell] = pool

func _on_frog_jumped(cell: Vector2i, player_id: int) -> void:
	for other_id in get_players_on(cell):
		if other_id != player_id:
			frogs[other_id].color = frogs[player_id].color
			_set_paint(other_id, 10_000)
	var pool: PaintPool = _pool_cells.get(cell)
	if pool != null:
		_set_paint(player_id, paint_budget)
		frogs[player_id].color = pool.color
		return
	if _paint_budgets[player_id] > 0 and map.paint_cell(cell, frogs[player_id].color):
		_set_paint(player_id, _paint_budgets[player_id] - 1)


## Every paint budget change goes through here so the frog knows how much paint
## it has (it turns back to its base green at 0).
func _set_paint(player_id: int, amount: int) -> void:
	_paint_budgets[player_id] = amount
	frogs[player_id].paint_left = amount


func get_paint_left(player_id: int) -> int:
	return _paint_budgets.get(player_id, 0)


func get_players_on(cell: Vector2i) -> Array[int]:
	var ids: Array[int] = []
	for player_id in frogs:
		if map.local_to_map(map.to_local(frogs[player_id].global_position)) == cell:
			ids.append(player_id)
	return ids
