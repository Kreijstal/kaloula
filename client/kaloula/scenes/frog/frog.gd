extends CharacterBody2D
class_name Frog

@export var jump_distance: float = 40;
## The paint colour the frog carries (it paints tiles with it). The colour it
## starts with is its team colour: its toes keep that colour for the whole game.
@export var color: Color = Color.BLUE:
	set(value):
		color = value
		if is_node_ready():
			_apply_color()
## Body colour when the frog has no paint left.
@export var base_color: Color = Color("6aab3f"):
	set(value):
		base_color = value
		if is_node_ready():
			_apply_color()
@export var rotation_speed: float = 6.0;
@export var map: Map;
@export var jump_cooldown: float = 0.1;
@export var jump_duration: float = 0.2;

@onready var rig: FrogRig = $Rig;
@onready var jump_highlight: Polygon2D = $JumpHighlight

## Paint the frog has left (the game logic keeps this up to date). At 0 the
## frog's body turns back to `base_color`.
var paint_left: int = 1:
	set(value):
		paint_left = value
		if is_node_ready():
			_apply_color()
## The frog's team colour (its starting `color`); used for its toes.
var team_color: Color

var _time_since_last_jump = 0;
var _hopping := false
var _hop_start := Vector2.ZERO
var _hop_cell := Vector2i.ZERO

signal jumped(cell: Vector2i)

enum Direction {
	LEFT,
	RIGHT
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(map != null, "Frog needs its map export set")
	team_color = color
	jump_highlight.modulate = color
	_apply_color()
	rig.jump_duration = jump_duration
	rig.cycle_finished.connect(_on_rig_cycle_finished)


func _apply_color() -> void:
	var palette := FrogPalette.from_color(color if paint_left > 0 else base_color)
	palette.toes = team_color
	palette.toe_pads = team_color
	palette.derive_belly_colors()  # belly-up toe tips follow the toes too
	rig.palette = palette


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _hopping:
		global_position = _hop_start + Vector2.UP.rotated(global_rotation) * rig.get_travel() * rig.global_scale.y
	var cell := get_jump_cell_map_coords()
	var is_visible := not _hopping and map.get_cell_source_id(cell) != -1
	jump_highlight.visible = is_visible
	if is_visible:
		jump_highlight.global_position = map.to_global(map.map_to_local(cell))
		jump_highlight.global_rotation = 0.0
	
	_time_since_last_jump += delta;


func get_jump_cell_map_coords() -> Vector2i:
	var target := global_position + Vector2.UP.rotated(global_rotation) * jump_distance
	return map.local_to_map(map.to_local(target))

func jump() -> bool:
	if _hopping or _time_since_last_jump < jump_cooldown:
		return false
	var target_cell := get_jump_cell_map_coords()
	if map.get_cell_source_id(target_cell) == -1:
		return false
	if target_cell == map.local_to_map(map.to_local(global_position)):
		return false
	var to_target := map.to_global(map.map_to_local(target_cell)) - global_position
	
	global_rotation = Vector2.UP.angle_to(to_target)
	rig.hop_stride = to_target.length() / rig.global_scale.y
	rig.play_once(FrogRig.Anim.HOP)
	_hop_start = global_position
	_hop_cell = target_cell
	_hopping = true
	
	_time_since_last_jump = 0
	return true


func is_hopping() -> bool:
	return _hopping


func _on_rig_cycle_finished(animation: FrogRig.Anim) -> void:
	if animation != FrogRig.Anim.HOP or not _hopping:
		return
	_hopping = false
	global_position = map.to_global(map.map_to_local(_hop_cell))
	jumped.emit(_hop_cell)


func turn(direction: Direction, delta: float) -> void:
	if _hopping:
		return
	var sign := -1.0 if direction == Direction.LEFT else 1.0
	rotate(sign * rotation_speed * delta)
	rig.turn_by(sign * rotation_speed * delta)
