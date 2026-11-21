@tool
class_name PaintCan
extends Control
## A round paint can seen from above. The paint inside drains as `level` goes from
## 1 (full) to 0 (empty). A mini frog copies a real frog's animation in the can.

## Paint colour (the frog's current colour).
@export var color := Color.BLUE:
	set(v):
		color = v
		queue_redraw()
## 0 = empty, 1 = full. The drawn level slides there smoothly.
@export_range(0.0, 1.0) var level := 1.0
## How far the paint's shade is from the frog's colour, so the frog stands out.
@export_range(0.0, 1.0) var paint_shade := 0.3
## Size of the mini frog relative to the can.
@export var frog_scale := 0.74

var mini: FrogRig

var _shown := 1.0
var _follow: FrogRig
var _clip: Node2D
var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(150, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_shown = level
	# The mini frog is clipped to the can's outer rim, so kicking legs stay inside.
	_clip = Node2D.new()
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_clip.draw.connect(func() -> void: _clip.draw_circle(Vector2.ZERO, 66.0 * _k(), Color.WHITE))
	add_child(_clip)
	mini = FrogRig.new()
	mini.show_shadow = true
	mini.idle_fidgets = false
	mini.preview_in_editor = false
	mini.mirror_of = _follow
	_clip.add_child(mini)
	resized.connect(_layout)
	_layout()


## Make the mini frog copy `rig` (a FrogRig, usually a Frog's $Rig).
func follow(rig: FrogRig) -> void:
	_follow = rig
	if mini:
		mini.mirror_of = rig


func _layout() -> void:
	_clip.position = size * 0.5
	mini.scale = Vector2.ONE * 96.0 / 124.0 * frog_scale / 0.74 * _k()
	_clip.queue_redraw()


func _k() -> float:
	return minf(size.x, size.y) / 160.0


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, level, 1.0 - exp(-4.0 * delta))
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var k := _k()
	draw_circle(c, 68.0 * k, Color("0b0f0e"), true, -1.0, true)
	draw_circle(c, 60.0 * k, Color("cdd6d3"), true, -1.0, true)
	draw_arc(c, 60.0 * k, 0.0, TAU, 64, Color("7d8c88"), 4.0 * k, true)
	draw_circle(c, 50.0 * k, Color("4a5754"), true, -1.0, true)
	# paint: the part of the inner circle below a gently moving wavy surface
	# paint a shade away from the frog's colour so the frog stands out:
	# darker for light colours, lighter for dark ones (like pure blue)
	var paint := color.darkened(paint_shade) if color.get_luminance() > 0.25 else color.lightened(paint_shade + 0.15)
	if _shown > 0.005:
		var inside := _circle(c, 50.0 * k, 48)
		if _shown >= 0.995:
			draw_colored_polygon(inside, paint)
		else:
			var y := c.y + (50.0 - 100.0 * _shown) * k
			var liquid := PackedVector2Array()
			for i in 25:
				var x := c.x + (-60.0 + 120.0 * i / 24.0) * k
				liquid.append(Vector2(x, y + 2.5 * k * sin(i * 0.9 + _t * 2.4)))
			liquid.append(Vector2(c.x + 60.0 * k, c.y + 60.0 * k))
			liquid.append(Vector2(c.x - 60.0 * k, c.y + 60.0 * k))
			for part in Geometry2D.intersect_polygons(inside, liquid):
				draw_colored_polygon(part, paint)
		# a little shine on the paint
		draw_arc(c, 42.0 * k, deg_to_rad(205), deg_to_rad(250), 12, Color(1, 1, 1, 0.3), 5.0 * k, true)
	draw_arc(c, 50.0 * k, 0.0, TAU, 64, Color(0.04, 0.06, 0.05, 0.35), 3.0 * k, true)


static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
