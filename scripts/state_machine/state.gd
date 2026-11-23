class_name State
extends Node

## Base state class for the reusable StateMachine.

var state_machine: StateMachine
var actor: Node


func enter(_data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
