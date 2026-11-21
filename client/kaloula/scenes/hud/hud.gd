class_name HUD
extends CanvasLayer
## Match HUD: tug-of-war bar along the top, round timer, and a dock along the bottom
## with one paint can per player (mini frog copying the real frog, paint level, score).
## The layout lives in hud.tscn (and player_card.tscn): move, restyle or retext the
## nodes there; this script only fills in the values.
##
## Instance hud.tscn anywhere in the game scene, then call:
##     hud.update_frog(player_id, frog, paint_left)   # register / refresh a player
##     hud.update_scores({player_id: points, ...})
##     hud.update_points([[player_id, tiles], ...], total_tiles)
##     hud.set_timer(seconds_left)

const PLAYER_CARD := preload("res://scenes/hud/player_card.tscn")
const TEXT := Color("f3efd9")

## Paint a frog holds when full (the can is full at this many).
@export var paint_max := 20
## Seconds left at which the timer turns red and pulses.
@export var warning_seconds := 10
## Timer panel look, normally and in the last `warning_seconds`.
@export var timer_style: StyleBox
@export var timer_warn_style: StyleBox

@onready var _bar: TugBar = %Bar
@onready var _timer_panel: PanelContainer = %TimerPanel
@onready var _timer_label: Label = %TimerLabel
@onready var _left_pct: Label = %LeftPct
@onready var _right_pct: Label = %RightPct
@onready var _unpainted_label: Label = %Unpainted
@onready var _dock_row: HBoxContainer = %DockRow

var _cards: Dictionary[int, PlayerCard] = {}
var _free_cards: Array[PlayerCard] = []
var _colors: Dictionary[int, Color] = {}
var _names: Dictionary[int, String] = {}
var _tiles: Dictionary[int, int] = {}
var _scores: Dictionary[int, int] = {}
var _total_tiles := 0
var _pulse: Tween
var _started := false


func _ready() -> void:
	# The cards placed in the dock are taken by players in order; unused ones stay hidden.
	for child in _dock_row.get_children():
		if child is PlayerCard:
			_free_cards.append(child)
			child.hide()
	set_timer(0)
	_refresh_bar()


# --- public API -------------------------------------------------------------

## Show the time left, in whole seconds. Red and pulsing near the end; "TIME!" at 0.
func set_timer(seconds: int) -> void:
	seconds = maxi(seconds, 0)
	var warn := seconds > 0 and seconds <= warning_seconds
	var over := seconds == 0 and _started
	_timer_label.text = "TIME!" if over else "%d:%02d" % [seconds / 60, seconds % 60]
	_timer_label.add_theme_color_override("font_color", Color("f2c14e") if over else TEXT)
	var style := timer_warn_style if warn else timer_style
	if style != null:
		_timer_panel.add_theme_stylebox_override("panel", style)
	if warn:
		_timer_panel.pivot_offset = _timer_panel.size * 0.5
		if _pulse:
			_pulse.kill()
		_pulse = create_tween()
		_pulse.tween_property(_timer_panel, "scale", Vector2.ONE * 1.12, 0.12)
		_pulse.tween_property(_timer_panel, "scale", Vector2.ONE, 0.25)
	if seconds > 0:
		_started = true


## Tiles currently in each player's colour: `points` = [[player_id, tiles], ...]
## (arrays or any 2-item list). `total_tiles` = tiles that can be painted (pools
## excluded); leave -1 to keep the last value. Drives the "tiles still unpainted" text.
func update_points(points: Array, total_tiles: int = -1) -> void:
	if total_tiles >= 0:
		_total_tiles = total_tiles
	for entry in points:
		var player_id: int = entry[0]
		_ensure_player(player_id)
		_tiles[player_id] = int(entry[1])
	_refresh_bar()


## Each player's score, `scores` = {player_id: points}: shown on their card and sizes their part of the bar.
func update_scores(scores: Dictionary) -> void:
	for player_id in scores:
		_ensure_player(player_id)
		_scores[player_id] = int(scores[player_id])
		_cards[player_id].set_score(_scores[player_id])
	_refresh_bar()


## Register or refresh a player's card. `frog`: the player's Frog (or a FrogRig):
## the mini frog in the can copies its animation and the paint takes its current
## colour. `paint_left`: paint the frog has left (-1 = leave as is).
func update_frog(player_id: int, frog: Object = null, paint_left: int = -1) -> void:
	_ensure_player(player_id)
	var card := _cards[player_id]
	if frog != null:
		var rig: FrogRig = frog if frog is FrogRig else frog.get("rig")
		var color: Color = frog.get("color") if frog.get("color") != null else rig.palette.skin
		if rig != null:
			card.can.follow(rig)
		card.can.color = color
		if not _colors.has(player_id):
			_colors[player_id] = color
			card.set_player(_names[player_id], color)
			_refresh_bar()
	if paint_left >= 0:
		card.set_paint(paint_left, paint_max)


## Name shown on a player's card (default "Player 1", "Player 2", ...).
func set_player_name(player_id: int, display_name: String) -> void:
	_ensure_player(player_id)
	_names[player_id] = display_name
	_cards[player_id].set_player(display_name, _colors.get(player_id, TEXT))
	_refresh_bar()


# --- internals ----------------------------------------------------------------

func _ensure_player(player_id: int) -> void:
	if _cards.has(player_id):
		return
	var card: PlayerCard
	if not _free_cards.is_empty():
		card = _free_cards.pop_front()
	else:
		# more players than cards in the scene: add one before the right-hand card
		card = PLAYER_CARD.instantiate()
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var last := _dock_row.get_child_count() - 1
		_dock_row.add_child(card)
		_dock_row.move_child(card, last)
		_dock_row.add_child(spacer)
		_dock_row.move_child(spacer, last + 1)
	card.show()
	_cards[player_id] = card
	_names[player_id] = "Player %d" % _cards.size()
	_tiles[player_id] = 0
	card.set_player(_names[player_id], TEXT)
	card.set_score(0)


## Players in the order their cards sit in the dock, left to right.
func _order() -> Array[int]:
	var order: Array[int] = []
	for child in _dock_row.get_children():
		for player_id in _cards:
			if _cards[player_id] == child:
				order.append(player_id)
	return order


func _refresh_bar() -> void:
	var order := _order()
	var colors: Array[Color] = []
	var scores: Array[float] = []
	var painted := 0
	var total_score := 0
	for player_id in order:
		colors.append(_colors.get(player_id, Color.GRAY))
		scores.append(float(_scores.get(player_id, 0)))
		painted += _tiles.get(player_id, 0)
		total_score += _scores.get(player_id, 0)
	if not order.is_empty():
		_bar.set_values(colors, scores)
	var total_tiles := maxi(_total_tiles, painted)
	_unpainted_label.text = "%d tiles still unpainted" % (total_tiles - painted) if total_tiles > 0 else ""
	var share := func(player_id: int) -> int:
		return roundi(100.0 * _scores.get(player_id, 0) / total_score) if total_score > 0 else roundi(100.0 / order.size())
	var first: int = order[0] if order.size() > 0 else -1
	var last: int = order[order.size() - 1] if order.size() > 1 else -1
	_left_pct.text = "%s %d%%" % [_names[first].to_upper(), share.call(first)] if first >= 0 else ""
	_right_pct.text = "%d%% %s" % [share.call(last), _names[last].to_upper()] if last >= 0 else ""
