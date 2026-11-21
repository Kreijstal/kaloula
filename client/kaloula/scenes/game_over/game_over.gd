class_name GameOver
extends CanvasLayer
## End-of-round overlay: the winner, each player's points, and a "PLAY AGAIN" button that starts a fresh game.

## Scene loaded by "PLAY AGAIN".
@export_file("*.tscn") var game_scene := "res://scenes/game.tscn"

@onready var _title: Label = %Title
@onready var _rows: VBoxContainer = %Rows
@onready var _play_again: Button = %PlayAgain


func _ready() -> void:
	_play_again.pressed.connect(func() -> void: get_tree().change_scene_to_file(game_scene))
	hide()


## Show the overlay. `scores`/`colors` per player id, in display order (Player 1 first).
func show_result(scores: Dictionary[int, int], colors: Dictionary[int, Color]) -> void:
	assert(scores.size() == _rows.get_child_count(), "GameOver has %d score rows for %d players" % [_rows.get_child_count(), scores.size()])
	assert(scores.keys().all(func(id): return colors.has(id)), "GameOver needs a colour for every player in %s" % [scores.keys()])
	var best: int = scores.values().max()
	var winners := scores.keys().filter(func(id): return scores[id] == best)
	var player_ids := scores.keys()
	for i in player_ids.size():
		var row := _rows.get_child(i)
		var player_name: Label = row.get_node("Name")
		player_name.text = "Player %d" % (i + 1)
		player_name.add_theme_color_override("font_color", colors[player_ids[i]])
		var points := scores[player_ids[i]]
		(row.get_node("Points") as Label).text = "%d point%s" % [points, "" if points == 1 else "s"]
	if winners.size() == 1:
		_title.text = "PLAYER %d WINS!" % (player_ids.find(winners[0]) + 1)
		_title.add_theme_color_override("font_color", colors[winners[0]])
	else:
		_title.text = "DRAW!"
	show()
	_play_again.grab_focus()
