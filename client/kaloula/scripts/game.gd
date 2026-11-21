class_name Game
extends Node2D

@export var logic: GameLogic
@export var score: Score
@export var hud: HUD
@export var music: AudioStream

func _ready() -> void:
	assert(logic != null, "Game needs its logic export set")
	assert(score != null, "Game needs score component")
	assert(hud != null, "Game needs its hud export set")
	logic.cell_painted.connect(score.on_cell_painted)
	# After score.on_cell_painted (connected first), so shape completions are already counted.
	logic.cell_painted.connect(func(_cell, _player_id): _update_hud_scores())
	logic.paint_changed.connect(func(player_id, amount): hud.update_frog(player_id, logic.frogs[player_id], amount))
	logic.ticked.connect(hud.set_timer)
	hud.paint_max = logic.paint_budget
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
