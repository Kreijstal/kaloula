class_name Game
extends Node2D

@export var logic: GameLogic
@export var score: Score
@export var hud: HUD
@export var game_over: GameOver
## Seconds between the round ending and the game-over screen, so the losers' flip shows.
@export var game_over_delay := 1.5
@export var music: AudioStream

func _ready() -> void:
	assert(logic != null, "Game needs its logic export set")
	assert(score != null, "Game needs score component")
	assert(hud != null, "Game needs its hud export set")
	assert(game_over != null, "Game needs its game_over export set")
	logic.cell_painted.connect(score.on_cell_painted)
	# After score.on_cell_painted (connected first), so shape completions are already counted.
	logic.cell_painted.connect(func(_cell, _player_id): _update_hud_scores())
	logic.paint_changed.connect(func(player_id, amount): hud.update_frog(player_id, logic.frogs[player_id], amount))
	logic.ticked.connect(hud.set_timer)
	hud.paint_max = logic.paint_budget
	logic.round_over.connect(_on_round_over)
	score.start(logic.get_starting_colors(), logic.get_pool_cells())
	score.shape_completed.connect(_on_shape_completed)
	for player_id in logic.frogs:
		hud.update_frog(player_id, logic.frogs[player_id], logic.get_paint_left(player_id))
	_update_hud_scores()
	if music != null:
		Music.play(music)


func _update_hud_scores() -> void:
	var tiles := []
	for player_id in logic.frogs:
		tiles.append([player_id, logic.get_tiles(player_id)])
	hud.update_points(tiles, logic.map.get_used_cells().size() - logic.get_pool_cells().size())
	hud.update_scores(score.get_scores())

func _on_shape_completed(player_id: int, points: int):
	print("Player %d scored %d", player_id, points)


## Highest score wins; everyone else flips belly up before the game-over screen shows.
func _on_round_over() -> void:
	var scores := score.get_scores()
	var best: int = scores.values().max()
	for player_id in scores:
		if scores[player_id] != best:
			logic.frogs[player_id].lose()
	await get_tree().create_timer(game_over_delay).timeout
	game_over.show_result(scores, logic.get_starting_colors())
