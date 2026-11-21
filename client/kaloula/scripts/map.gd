extends TileMapLayer
class_name Map

## How saturated painted tiles look, relative to the paint (frog) colour: 1 = the same,
## lower = paler, so the frogs stand out on their own colour. Only the look changes;
## the stored paint colours (used for scoring) stay exact.
@export_range(0.0, 1.0) var tile_saturation := 0.55:
	set(v):
		tile_saturation = v
		notify_runtime_tile_data_update()
## Mixes painted tiles a little toward white (0 = not at all).
@export_range(0.0, 1.0) var tile_lighten := 0.12:
	set(v):
		tile_lighten = v
		notify_runtime_tile_data_update()

var _paint: Dictionary[Vector2i, Color] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func paint_cell(cell: Vector2i, color: Color) -> bool:
	assert(get_cell_source_id(cell) != -1, "cannot paint empty cell %s" % cell)
	var will_change: bool = _paint.get(cell) != color
	_paint[cell] = color
	notify_runtime_tile_data_update()
	return will_change

## Number of tiles currently painted `color`.
func count_cells_with_color(color: Color) -> int:
	var n := 0
	for c in _paint.values():
		if c.is_equal_approx(color):
			n += 1
	return n

func get_cell_color(cell: Vector2i) -> Color:
	return _paint.get(cell, Color.TRANSPARENT)

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return coords in _paint


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate = tile_color(_paint[coords])


## The colour a tile painted `paint` is drawn in (paler than the paint itself).
func tile_color(paint: Color) -> Color:
	var c := Color.from_hsv(paint.h, paint.s * tile_saturation, paint.v, paint.a)
	return c.lerp(Color.WHITE, tile_lighten)
