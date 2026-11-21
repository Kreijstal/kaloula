class_name PlayerCard
extends HBoxContainer
## One player in the HUD dock: paint can with the mini frog, name, tile count, paint left.

const FONT_REGULAR := preload("res://assets/fonts/pixelify-sans-latin-400-normal.woff2")
const FONT_SEMIBOLD := preload("res://assets/fonts/pixelify-sans-latin-600-normal.woff2")
const FONT_BOLD := preload("res://assets/fonts/pixelify-sans-latin-700-normal.woff2")

var can: PaintCan
var name_label: Label
var score_label: Label
var paint_label: Label

var _paint_left := -1
var _paint_max := 3


## `mirrored`: can on the right, text right-aligned (for the right-hand player).
func _init(mirrored: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 14)
	alignment = BoxContainer.ALIGNMENT_END if mirrored else BoxContainer.ALIGNMENT_BEGIN
	can = PaintCan.new()
	can.size_flags_vertical = Control.SIZE_SHRINK_END
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_vertical = Control.SIZE_SHRINK_END
	text.add_theme_constant_override("separation", 0)
	var align := HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
	name_label = _label(FONT_SEMIBOLD, 16, align)
	score_label = _label(FONT_BOLD, 56, align)
	paint_label = _label(FONT_REGULAR, 14, align)
	paint_label.add_theme_color_override("font_color", Color("c9c4ad"))
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size.y = 14
	for l in [name_label, score_label, paint_label, bottom_pad]:
		text.add_child(l)
	if mirrored:
		add_child(text)
		add_child(can)
	else:
		add_child(can)
		add_child(text)
	set_score(0)


func set_player(display_name: String, color: Color) -> void:
	name_label.text = display_name.to_upper()
	name_label.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.55))


func set_score(tiles: int) -> void:
	score_label.text = str(tiles)
	_refresh_paint_label()


func set_paint(left: int, max_paint: int) -> void:
	_paint_left = left
	_paint_max = maxi(max_paint, 1)
	can.level = clampf(float(left) / _paint_max, 0.0, 1.0)
	_refresh_paint_label()


func _refresh_paint_label() -> void:
	if _paint_left < 0:
		paint_label.text = "tiles"
	elif _paint_left > _paint_max:
		paint_label.text = "tiles · lots of paint"
	else:
		paint_label.text = "tiles · %d of %d paint" % [_paint_left, _paint_max]


static func _label(font: Font, font_size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("f3efd9"))
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
