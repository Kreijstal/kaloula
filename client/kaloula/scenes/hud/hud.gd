class_name HUD
extends CanvasLayer
## Match HUD: tug-of-war bar along the top, round timer, and a dock along the bottom
## with one paint can per player (mini frog copying the real frog, paint level, tiles).
##
## Instance hud.tscn anywhere in the game scene, then call:
##     hud.update_frog(player_id, frog, paint_left)   # register / refresh a player
##     hud.update_points([[player_id, tiles], ...], total_tiles)
##     hud.set_timer(seconds_left)

## Paint a frog holds when full (the can is full at this many).
@export var paint_max := 3
## Seconds left at which the timer turns red and pulses.
@export var warning_seconds := 10

const FONT_REGULAR := preload("res://assets/fonts/pixelify-sans-latin-400-normal.woff2")
const FONT_SEMIBOLD := preload("res://assets/fonts/pixelify-sans-latin-600-normal.woff2")
const FONT_BOLD := preload("res://assets/fonts/pixelify-sans-latin-700-normal.woff2")
const TEXT := Color("f3efd9")
const TEXT_DIM := Color("c9c4ad")

var _root: Control
var _bar: TugBar
var _timer_panel: PanelContainer
var _timer_label: Label
var _left_pct: Label
var _right_pct: Label
var _unpainted_label: Label
var _dock_row: HBoxContainer
var _timer_style: PixelStyleBox
var _timer_warn_style: PixelStyleBox

var _order: Array[int] = []
var _cards: Dictionary[int, PlayerCard] = {}
var _colors: Dictionary[int, Color] = {}
var _names: Dictionary[int, String] = {}
var _tiles: Dictionary[int, int] = {}
var _total_tiles := 0
var _pulse: Tween


func _ready() -> void:
	_build()
	set_timer(0)


# --- public API -------------------------------------------------------------

## Show the time left, in whole seconds. Red and pulsing near the end; "TIME!" at 0.
func set_timer(seconds: int) -> void:
	seconds = maxi(seconds, 0)
	var warn := seconds > 0 and seconds <= warning_seconds
	var over := seconds == 0 and _started
	_timer_label.text = "TIME!" if over else "%d:%02d" % [seconds / 60, seconds % 60]
	_timer_label.add_theme_color_override("font_color", Color("f2c14e") if over else TEXT)
	_timer_panel.add_theme_stylebox_override("panel", _timer_warn_style if warn else _timer_style)
	if warn:
		_timer_panel.pivot_offset = _timer_panel.size * 0.5
		if _pulse:
			_pulse.kill()
		_pulse = create_tween()
		_pulse.tween_property(_timer_panel, "scale", Vector2.ONE * 1.12, 0.12)
		_pulse.tween_property(_timer_panel, "scale", Vector2.ONE, 0.25)
	if seconds > 0:
		_started = true

var _started := false


## Tiles currently in each player's colour: `points` = [[player_id, tiles], ...]
## (arrays or any 2-item list). `total_tiles` = tiles that can be painted (pools
## excluded); leave -1 to keep the last value. The grey middle of the bar = the rest.
func update_points(points: Array, total_tiles: int = -1) -> void:
	if total_tiles >= 0:
		_total_tiles = total_tiles
	for entry in points:
		var player_id: int = entry[0]
		_ensure_player(player_id)
		_tiles[player_id] = int(entry[1])
		_cards[player_id].set_score(_tiles[player_id])
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
	_order.append(player_id)
	_names[player_id] = "Player %d" % _order.size()
	_tiles[player_id] = 0
	_rebuild_dock()


func _rebuild_dock() -> void:
	for child in _dock_row.get_children():
		_dock_row.remove_child(child)
		if not child is PlayerCard:
			child.queue_free()
	var old := _cards.duplicate()
	_cards.clear()
	for i in _order.size():
		var player_id := _order[i]
		var mirrored := i == _order.size() - 1 and _order.size() > 1
		var card: PlayerCard = old.get(player_id)
		if card == null or (card.get_meta("mirrored", false) != mirrored):
			var fresh := PlayerCard.new(mirrored)
			fresh.set_meta("mirrored", mirrored)
			if card != null:  # keep its state when it switches sides
				fresh.ready.connect(func() -> void:
					fresh.can.follow(card.can.mini.mirror_of)
					fresh.can.color = card.can.color
					fresh.set_paint(card._paint_left, card._paint_max)
					card.queue_free(), CONNECT_ONE_SHOT)
			card = fresh
		if i > 0:
			var gap := Control.new()
			gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dock_row.add_child(gap)
		_dock_row.add_child(card)
		card.set_player(_names[player_id], _colors.get(player_id, TEXT))
		card.set_score(_tiles.get(player_id, 0))
		_cards[player_id] = card


func _refresh_bar() -> void:
	var colors: Array[Color] = []
	var values: Array[float] = []
	var painted := 0
	for player_id in _order:
		colors.append(_colors.get(player_id, Color.GRAY))
		values.append(float(_tiles.get(player_id, 0)))
		painted += _tiles.get(player_id, 0)
	var total := maxi(_total_tiles, painted)
	var unpainted := total - painted
	_bar.set_values(colors, values, float(unpainted))
	_unpainted_label.text = "%d tiles still unpainted" % unpainted if total > 0 else ""
	var first: int = _order[0] if _order.size() > 0 else -1
	var last: int = _order[_order.size() - 1] if _order.size() > 1 else -1
	_left_pct.text = "%s %d%%" % [_names[first].to_upper(), roundi(100.0 * _tiles[first] / total)] if first >= 0 and total > 0 else ""
	_right_pct.text = "%d%% %s" % [roundi(100.0 * _tiles[last] / total), _names[last].to_upper()] if last >= 0 and total > 0 else ""


func _build() -> void:
	layer = 10
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_timer_style = PixelStyleBox.new(6.0)
	_timer_style.content_margin_left = 18
	_timer_style.content_margin_right = 18
	_timer_warn_style = _timer_style.duplicate()
	_timer_warn_style.fill = Color("7a1f1f")
	_timer_warn_style.inner = Color("a33636")

	# dock along the bottom
	var dock := Panel.new()
	var dock_style := StyleBoxFlat.new()
	dock_style.bg_color = Color("1c2423")
	dock_style.border_width_top = 6
	dock_style.border_color = Color("0b0f0e")
	dock.add_theme_stylebox_override("panel", dock_style)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -140
	_root.add_child(dock)
	var dock_line := ColorRect.new()
	dock_line.color = Color("2c3937")
	dock_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock_line.offset_top = -137
	dock_line.offset_bottom = -134
	_root.add_child(dock_line)

	_dock_row = HBoxContainer.new()
	_dock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dock_row.offset_top = -164
	_dock_row.offset_bottom = -14
	_dock_row.offset_left = 24
	_dock_row.offset_right = -24
	_root.add_child(_dock_row)

	_unpainted_label = _label(FONT_REGULAR, 15, TEXT_DIM)
	_unpainted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unpainted_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_unpainted_label.offset_left = -240
	_unpainted_label.offset_right = 240
	_unpainted_label.offset_top = -72
	_unpainted_label.offset_bottom = -50
	_root.add_child(_unpainted_label)

	# tug-of-war bar along the top
	_bar = TugBar.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bar.offset_bottom = 26
	_root.add_child(_bar)

	_left_pct = _label(FONT_SEMIBOLD, 15, TEXT)
	_left_pct.position = Vector2(12, 34)
	_root.add_child(_left_pct)
	_right_pct = _label(FONT_SEMIBOLD, 15, TEXT)
	_right_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_right_pct.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_right_pct.offset_left = -300
	_right_pct.offset_right = -12
	_right_pct.offset_top = 34
	_root.add_child(_right_pct)
	for l in [_left_pct, _right_pct]:
		l.add_theme_color_override("font_shadow_color", Color("0b0f0e"))
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 2)

	# timer, centred under the bar
	var timer_row := CenterContainer.new()
	timer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	timer_row.offset_left = -120
	timer_row.offset_right = 120
	timer_row.offset_top = 34
	timer_row.offset_bottom = 84
	_root.add_child(timer_row)
	_timer_panel = PanelContainer.new()
	_timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_panel.add_theme_stylebox_override("panel", _timer_style)
	timer_row.add_child(_timer_panel)
	_timer_label = _label(FONT_BOLD, 34, TEXT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_panel.add_child(_timer_label)


static func _label(font: Font, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
