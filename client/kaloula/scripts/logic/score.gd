extends Node
class_name Score

signal shape_completed(player_id: int, points: int)

@export var map: Map
@export var outline_scene: PackedScene
@export var shapes: Dictionary[PackedVector2Array, Dictionary] = {
	PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]): {probability = 0.25, points = 5},
	PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)]): {probability = 0.5, points = 9},
	PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)]): {probability = 0.25, points = 14},
}

var _shape_scores: Dictionary[int, int] = {}
var _player_by_starting_color: Dictionary[Color, int] = {}
var _blocked_cells: Array[Vector2i] = []
var _shape_cells: Array[Vector2i] = []
var _shape_points := 0
var _outline: ShapeOutline
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	assert(map != null, "Score needs its map export set")
	assert(outline_scene != null, "Score needs its outline_scene export set")
	assert(not shapes.is_empty(), "Score needs at least one shape")
	for template in shapes:
		var entry := shapes[template]
		assert(entry.get("probability") is float and entry.get("points") is int,
				"shape %s needs a float probability and an int points, got %s" % [template, entry])
	_rng.randomize()
	_outline = outline_scene.instantiate()
	map.add_child(_outline)


func start(starting_colors: Dictionary[int, Color], blocked_cells: Array[Vector2i]) -> void:
	for player_id in starting_colors:
		var color := starting_colors[player_id]
		assert(color not in _player_by_starting_color, "players %s and %s share starting colour %s" % [_player_by_starting_color.get(color), player_id, color])
		_player_by_starting_color[color] = player_id
		_shape_scores[player_id] = 0
	_blocked_cells = blocked_cells
	_place_shape()


## Each player's score: points from completed shapes plus the tiles currently in their starting colour,
## whoever painted them.
func get_scores() -> Dictionary[int, int]:
	var scores := _shape_scores.duplicate()
	for color in _player_by_starting_color:
		scores[_player_by_starting_color[color]] += map.count_cells_with_color(color)
	return scores


## Scoring goes by the cell's colour, so who painted it (`_player_id`) doesn't matter.
func on_cell_painted(cell: Vector2i, _player_id: int) -> void:
	if _shape_cells.is_empty():
		_place_shape()  # no free spot last time; the board has changed since
	elif cell in _shape_cells:
		var color := _single_color(_shape_cells)
		if color != Color.TRANSPARENT:
			_complete(color)


func _complete(color: Color) -> void:
	assert(color in _player_by_starting_color, "shape completed in %s, which is no player's starting colour" % color)
	var player_id := _player_by_starting_color[color]
	_shape_scores[player_id] += _shape_points
	shape_completed.emit(player_id, _shape_points)
	_place_shape()


## The colour all `cells` share, or TRANSPARENT if they differ or any is unpainted.
func _single_color(cells: Array[Vector2i]) -> Color:
	var first := map.get_cell_color(cells[0])
	for cell in cells:
		if map.get_cell_color(cell) != first:
			return Color.TRANSPARENT
	return first


func _place_shape() -> void:
	var templates: Array = shapes.keys()
	var weights := PackedFloat32Array(shapes.values().map(func(entry): return entry.probability))
	# Try shapes in weighted-random order until one fits somewhere.
	while not templates.is_empty():
		var i := _rng.rand_weighted(weights)
		assert(i != -1, "Score's shape probabilities must be positive")
		var placements := _placements(templates[i])
		if not placements.is_empty():
			_shape_cells = placements[_rng.randi() % placements.size()]
			_shape_points = shapes[templates[i]].points
			_outline.cells = _shape_cells
			_outline.visible = true
			return
		templates.remove_at(i)
		weights.remove_at(i)
	_shape_cells = []
	_shape_points = 0
	_outline.visible = false

################### Shape placement #######################

## All possible placements of a shape
func _placements(template: PackedVector2Array) -> Array:
	var tiles: Dictionary[Vector2i, bool] = {}
	for cell in map.get_used_cells():
		if cell not in _blocked_cells:
			tiles[cell] = true
	var result := []
	for shape in _orientations(template):
		for origin in tiles:
			var placed: Array[Vector2i] = []
			for offset in shape:
				placed.append(origin + offset)
			if placed.all(func(c): return tiles.has(c)) and _single_color(placed) == Color.TRANSPARENT:
				result.append(placed)
	return result


## The distinct rotations and mirror images of `template`, each shifted so its minimum x and y are 0.
static func _orientations(template: PackedVector2Array) -> Array:
	var result := []
	for mirror in [false, true]:
		for turns in 4:
			var cells: Array[Vector2i] = []
			for point in template:
				var c := Vector2i(point)
				if mirror:
					c.x = -c.x
				for t in turns:
					c = Vector2i(-c.y, c.x)
				cells.append(c)
			var low := Vector2i(cells.map(func(c): return c.x).min(), cells.map(func(c): return c.y).min())
			for k in cells.size():
				cells[k] -= low
			cells.sort()
			if cells not in result:
				result.append(cells)
	return result
