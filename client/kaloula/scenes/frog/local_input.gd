class_name LocalInput
extends Node

@export var frog: Frog
@export var jump_distance_rate: float = 200
## Prepended to every action name, so one script serves several players ("" for player 1, "p2_" for player 2).
@export var action_prefix: String = ""

const _ACTIONS: Array[String] = ["turn_left", "turn_right", "jump", "increase_jump_distance", "decrease_jump_distance"]


func _ready() -> void:
	assert(frog != null, "LocalInput needs its frog export set")
	for action in _ACTIONS:
		assert(InputMap.has_action(action_prefix + action), "missing input action %s" % (action_prefix + action))


func _physics_process(delta: float) -> void:
	var left := Input.is_action_pressed(action_prefix + "turn_left")
	var right := Input.is_action_pressed(action_prefix + "turn_right")
	if Input.is_action_pressed(action_prefix + "jump"):
		frog.jump()
	if left != right:
		frog.turn(Frog.Direction.LEFT if left else Frog.Direction.RIGHT, delta)

	var distance_axis := Input.get_axis(action_prefix + "decrease_jump_distance", action_prefix + "increase_jump_distance")
	frog.jump_distance = maxf(0.0, frog.jump_distance + distance_axis * jump_distance_rate * delta)
