class_name MainMenu
extends Control
## Title screen: VS match, Cooperative (not available yet), Settings (sound and
## music volume) and Quit. Plays the menu music on the "Music" bus.

## Scene started by "VS MATCH".
@export_file("*.tscn") var vs_match_scene := "res://scenes/game.tscn"
@export var music: AudioStream = preload("res://assets/audio/bossa_antigua.mp3")
## Played on the "SFX" bus when the sound slider is let go, to preview the volume.
@export var sound_preview: AudioStream = preload("res://assets/audio/frog_hop.mp3")

const FONT_REGULAR := preload("res://assets/fonts/pixelify-sans-latin-400-normal.woff2")
const FONT_SEMIBOLD := preload("res://assets/fonts/pixelify-sans-latin-600-normal.woff2")
const FONT_BOLD := preload("res://assets/fonts/pixelify-sans-latin-700-normal.woff2")
const FROG_ART := preload("res://assets/ui/frog_title.png")

const TEXT := Color("f3efd9")
const TEXT_DIM := Color("c9c4ad")
const BLUE := Color("2a47f5")
const RED := Color("d6332b")
const POND := Color("3d6b6c")
const POND_LINE := Color("36605f")
const FOCUS := Color("f2c14e")

var _main: Control
var _settings: Control
var _vs_button: Button
var _settings_back: Button
var _toast: PanelContainer
var _toast_tween: Tween
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sound_value: Label
var _music_value: Label


func _ready() -> void:
	GameSettings.load_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_main()
	_build_settings()
	_build_toast()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = GameSettings.MUSIC_BUS
	if music is AudioStreamMP3:
		music.loop = true
	_music_player.stream = music
	add_child(_music_player)
	_music_player.play()
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = GameSettings.SFX_BUS
	_sfx_player.stream = sound_preview
	add_child(_sfx_player)
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _settings.visible:
		_show_main()
		get_viewport().set_input_as_handled()


# --- actions --------------------------------------------------------------------

func _on_vs_match() -> void:
	get_tree().change_scene_to_file(vs_match_scene)


func _on_cooperative() -> void:
	_show_toast("Cooperative isn't available yet.")


func _on_quit() -> void:
	get_tree().quit()


func _show_main() -> void:
	if _settings.visible:
		GameSettings.save_settings()
	_settings.hide()
	_main.show()
	_vs_button.grab_focus()


func _show_settings() -> void:
	_main.hide()
	_settings.show()
	_settings_back.grab_focus()


func _show_toast(message: String) -> void:
	(_toast.get_child(0).get_child(1) as Label).text = message
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast.show()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.9)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(_toast.hide)


# --- building -------------------------------------------------------------------

func _build_background() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func() -> void:
		bg.draw_rect(Rect2(Vector2.ZERO, bg.size), POND)
		var line := Color(POND_LINE, 0.7)
		var x := 0.0
		while x < bg.size.x:
			bg.draw_rect(Rect2(x, 0, 2, bg.size.y), line)
			x += 48.0
		var y := 0.0
		while y < bg.size.y:
			bg.draw_rect(Rect2(0, y, bg.size.x, 2), line)
			y += 48.0)
	bg.resized.connect(bg.queue_redraw)
	add_child(bg)


func _build_main() -> void:
	_main = Control.new()
	_main.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_main)

	# key art: paint blobs in the two player colours behind the frog
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = Vector2(600, 60)
	art.size = Vector2(500, 480)
	art.draw.connect(func() -> void:
		_blob(art, Vector2(210, 200), Vector2(190, 190), BLUE, 1.0)
		_blob(art, Vector2(320, 325), Vector2(160, 150), RED, 2.0)
		art.draw_circle(Vector2(410, 110), 20, BLUE)
		art.draw_circle(Vector2(53, 423), 13, RED))
	_main.add_child(art)
	var frog := TextureRect.new()
	frog.texture = FROG_ART
	frog.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frog.position = Vector2(600, 60)
	frog.size = Vector2(500, 470)
	frog.pivot_offset = frog.size * 0.5
	frog.rotation_degrees = -12.0
	_main.add_child(frog)

	var title := _label("KALOULA", FONT_BOLD, 104, TEXT)
	title.add_theme_color_override("font_shadow_color", Color("0b0f0e"))
	title.add_theme_constant_override("shadow_offset_x", 6)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.position = Vector2(80, 58)
	_main.add_child(title)
	for i in 2:
		var stripe := ColorRect.new()
		stripe.color = [BLUE, RED][i]
		stripe.position = Vector2(86 + i * 56, 182)
		stripe.size = Vector2(46, 14)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_main.add_child(stripe)

	var menu := VBoxContainer.new()
	menu.position = Vector2(80, 250)
	menu.custom_minimum_size = Vector2(360, 0)
	menu.add_theme_constant_override("separation", 14)
	_main.add_child(menu)
	_vs_button = _menu_button("VS MATCH", BLUE, Color("4d67ff"), Color.WHITE)
	_vs_button.pressed.connect(_on_vs_match)
	menu.add_child(_vs_button)
	var coop := _menu_button("COOPERATIVE", Color("2f3b39"), Color("3a4745"), Color("8d9893"))
	coop.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	coop.tooltip_text = "Not available yet"
	coop.pressed.connect(_on_cooperative)
	var soon := PanelContainer.new()
	var soon_style := StyleBoxFlat.new()
	soon_style.bg_color = Color("1c2423")
	soon_style.set_content_margin_all(5)
	soon_style.content_margin_left = 8
	soon_style.content_margin_right = 8
	soon.add_theme_stylebox_override("panel", soon_style)
	soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soon.add_child(_label("SOON", FONT_SEMIBOLD, 13, TEXT_DIM))
	soon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	soon.offset_left = -78
	soon.offset_right = -22
	soon.offset_top = -13
	soon.offset_bottom = 13
	coop.add_child(soon)
	menu.add_child(coop)
	var settings := _menu_button("SETTINGS", Color("1c2423"), Color("2c3937"), TEXT)
	settings.pressed.connect(_show_settings)
	menu.add_child(settings)
	var quit := _menu_button("QUIT", Color("1c2423"), Color("2c3937"), TEXT)
	quit.pressed.connect(_on_quit)
	menu.add_child(quit)


func _build_settings() -> void:
	_settings = CenterContainer.new()
	_settings.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings)
	var panel := PanelContainer.new()
	var style := PixelStyleBox.new(0.0)
	style.shadow_offset = Vector2(8, 8)
	style.shadow = Color(0, 0, 0, 0.35)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 34
	style.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(560, 0)
	_settings.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	panel.add_child(box)
	box.add_child(_label("SETTINGS", FONT_BOLD, 44, TEXT))
	_sound_value = _volume_row(box, "Sound effects", Color("b6c4ff"), BLUE, GameSettings.sound,
			func(v: float) -> void:
				GameSettings.set_sound(v)
				_sound_value.text = "%d%%" % roundi(v * 100.0),
			func() -> void: _sfx_player.play())
	_music_value = _volume_row(box, "Music", Color("f2a29c"), RED, GameSettings.music,
			func(v: float) -> void:
				GameSettings.set_music(v)
				_music_value.text = "%d%%" % roundi(v * 100.0),
			Callable())
	_settings_back = _menu_button("BACK", Color("2f3b39"), Color("3a4745"), TEXT, 56, 24)
	_settings_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_settings_back.custom_minimum_size.x = 150
	_settings_back.pressed.connect(_show_main)
	box.add_child(_settings_back)


## A labelled volume slider. Returns the label showing the percentage.
func _volume_row(parent: Control, title: String, value_color: Color, fill: Color, start: float,
		on_change: Callable, on_release: Callable) -> Label:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var head := HBoxContainer.new()
	row.add_child(head)
	var name_label := _label(title, FONT_SEMIBOLD, 22, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var value := _label("%d%%" % roundi(start * 100.0), FONT_BOLD, 22, value_color)
	head.add_child(value)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = start
	slider.custom_minimum_size = Vector2(0, 30)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0b0f0e")
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	var filled := StyleBoxFlat.new()
	filled.bg_color = fill
	filled.border_color = Color("0b0f0e")
	filled.border_width_top = 3
	filled.border_width_bottom = 3
	filled.border_width_left = 3
	filled.content_margin_top = 8
	filled.content_margin_bottom = 8
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = FOCUS
	focus.set_border_width_all(3)
	focus.set_expand_margin_all(4)
	slider.add_theme_stylebox_override("focus", focus)
	var knob := _knob_texture(Color(TEXT))
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", _knob_texture(Color.WHITE))
	slider.value_changed.connect(on_change)
	if on_release.is_valid():
		slider.drag_ended.connect(func(_changed: bool) -> void: on_release.call())
	row.add_child(slider)
	return value


func _build_toast() -> void:
	_toast = PanelContainer.new()
	var style := PixelStyleBox.new(14.0)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.shadow_offset = Vector2(6, 6)
	_toast.add_theme_stylebox_override("panel", style)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = -88
	_toast.offset_bottom = -40
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_toast.add_child(row)
	var bang := _label("!", FONT_BOLD, 22, FOCUS)
	row.add_child(bang)
	row.add_child(_label("", FONT_SEMIBOLD, 20, TEXT))
	_toast.hide()
	add_child(_toast)


func _menu_button(text: String, fill: Color, inner: Color, text_color: Color, height: int = 64,
		font_size: int = 28) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, text_color)
	var normal := PixelStyleBox.new(0.0)
	normal.fill = fill
	normal.inner = inner
	normal.shadow = Color(0, 0, 0, 0.35)
	normal.shadow_offset = Vector2(6, 6)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	var hover: PixelStyleBox = normal.duplicate()
	hover.fill = fill.lightened(0.12)
	hover.inner = inner.lightened(0.12)
	var pressed: PixelStyleBox = normal.duplicate()
	pressed.shadow_offset = Vector2(2, 2)
	pressed.fill = fill.darkened(0.1)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = FOCUS
	focus.set_border_width_all(3)
	focus.set_expand_margin_all(5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	return b


static func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _knob_texture(color: Color) -> ImageTexture:
	var img := Image.create(22, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color("0b0f0e"))
	img.fill_rect(Rect2i(3, 3, 16, 24), color)
	return ImageTexture.create_from_image(img)


## An organic paint blob.
static func _blob(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color, seed_value: float) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var wobble := 1.0 + 0.06 * sin(a * 3.0 + seed_value) + 0.04 * sin(a * 5.0 + seed_value * 2.0)
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y) * wobble)
	canvas.draw_colored_polygon(pts, color)
