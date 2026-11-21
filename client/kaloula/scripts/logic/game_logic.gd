class_name GameLogic
extends Node
## The match rules: paint budgets, paint pools, stomps and the round timer.

## The round's time ran out; the frogs can no longer move.
signal round_over
## Emitted whenever the whole seconds left in the round change, ending with 0.
signal ticked(seconds_left: int)
signal stomped(victim_id: int, by_id: int)

@export var map: Map
@export var frogs: Dictionary[int, Frog] = {}
@export var paint_budget: int = 10000
## Each player's paint pool cell; the pool takes that frog's starting colour.
@export var pool_cells: Dictionary[int, Vector2i] = {}
@export var pool_scene: PackedScene
## One-shot Timer for the round; its wait_time is the round length. Leave unset for no time limit.
@export var round_timer: Timer

## Seconds left in the round (0 without a time limit).
var time_left: float:
	get:
		return round_timer.time_left if round_timer != null else 0.0
var _round_over := false
var _last_tick := -1

var _paint_budgets: Dictionary[int, int] = {}
var _pool_cells: Dictionary[Vector2i, PaintPool] = {}
var _player_colors: Dictionary[int, Color] = {}

signal cell_painted(cell: Vector2i, player_id: int)
signal paint_changed(player_id: int, amount: int)

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
	if round_timer != null:
		assert(round_timer.one_shot, "GameLogic's round_timer must be one-shot")
		round_timer.timeout.connect(_end_round)
		round_timer.start()


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
			stomped.emit(other_id, player_id)
	var pool: PaintPool = _pool_cells.get(cell)
	if pool != null:
		frogs[player_id].color = pool.color
		_set_paint(player_id, paint_budget)
		return
	if _paint_budgets[player_id] > 0 and map.paint_cell(cell, frogs[player_id].color):
		_set_paint(player_id, _paint_budgets[player_id] - 1)
		cell_painted.emit(cell, player_id)


## Every paint budget change goes through here so the frog knows how much paint
## it has (it turns back to its base green at 0).
func _set_paint(player_id: int, amount: int) -> void:
	_paint_budgets[player_id] = amount
	frogs[player_id].paint_left = amount
	paint_changed.emit(player_id, amount)


func get_paint_left(player_id: int) -> int:
	return _paint_budgets.get(player_id, 0)


func _process(_delta: float) -> void:
	if round_timer == null or _round_over:
		return
	var seconds := ceili(round_timer.time_left)
	if seconds != _last_tick:
		_last_tick = seconds
		ticked.emit(seconds)


## Tiles currently in the player's team colour.
func get_tiles(player_id: int) -> int:
	return map.count_cells_with_color(_player_colors[player_id])


func is_round_over() -> bool:
	return _round_over


func _end_round() -> void:
	_round_over = true
	ticked.emit(0)
	for player_id in frogs:
		frogs[player_id].can_move = false
	round_over.emit()


func get_starting_colors() -> Dictionary[int, Color]:
	return _player_colors.duplicate()


func get_pool_cells() -> Array[Vector2i]:
	return Array(_pool_cells.keys(), TYPE_VECTOR2I, &"", null)


func get_players_on(cell: Vector2i) -> Array[int]:
	var ids: Array[int] = []
	for player_id in frogs:
		if map.local_to_map(map.to_local(frogs[player_id].global_position)) == cell:
			ids.append(player_id)
	return ids
