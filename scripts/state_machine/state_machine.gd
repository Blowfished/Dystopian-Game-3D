class_name StateMachine
extends Node

## Reusable hierarchical-friendly finite state machine.
## Child nodes extending State are automatically registered by their node name.

signal state_changed(previous_state: StringName, new_state: StringName)

@export var initial_state_path: NodePath

var current_state: State
var _states: Dictionary = {}
var _actor: Node


func init(actor_node: Node) -> void:
	_actor = actor_node
	_states.clear()
	for child in get_children():
		if child is State:
			child.state_machine = self
			child.actor = _actor
			_states[child.name] = child

	var start_state: State = null
	if not initial_state_path.is_empty():
		start_state = get_node_or_null(initial_state_path) as State
	if start_state == null and not _states.is_empty():
		start_state = _states.values()[0]

	if start_state != null:
		current_state = start_state
		current_state.enter({})


func transition_to(target_state_name: StringName, data: Dictionary = {}) -> void:
	if not _states.has(target_state_name):
		push_warning("StateMachine: Unknown state '%s'" % String(target_state_name))
		return
	var next_state: State = _states[target_state_name]
	if next_state == current_state:
		return
	var prev_name: StringName = current_state.name if current_state else &""
	if current_state != null:
		current_state.exit()
	current_state = next_state
	current_state.enter(data)
	state_changed.emit(prev_name, current_state.name)


func process_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)


func process_frame(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func process_physics(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func get_current_state_name() -> StringName:
	return current_state.name if current_state else &""
