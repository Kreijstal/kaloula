@tool
class_name PixelStyleBox
extends StyleBox
## Chunky pixel-art panel: hard drop shadow, dark outer border, lighter inner line, flat fill.

@export var fill := Color("1c2423")
@export var border := Color("0b0f0e")
@export var inner := Color("2c3937")
@export var border_width := 3.0
@export var inner_width := 3.0
@export var shadow := Color(0, 0, 0, 0.3)
@export var shadow_offset := Vector2(5, 5)


func _init(padding: float = 10.0) -> void:
	set_content_margin_all(padding)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	if shadow.a > 0.0:
		rs.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + shadow_offset, rect.size), shadow)
	rs.canvas_item_add_rect(to_canvas_item, rect, border)
	var r := rect.grow(-border_width)
	if inner_width > 0.0:
		rs.canvas_item_add_rect(to_canvas_item, r, inner)
		r = r.grow(-inner_width)
	rs.canvas_item_add_rect(to_canvas_item, r, fill)
