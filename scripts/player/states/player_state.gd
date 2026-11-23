class_name PlayerState
extends State

## Convenience base state for CourierController states.

var courier: CourierController:
	get:
		return actor as CourierController
