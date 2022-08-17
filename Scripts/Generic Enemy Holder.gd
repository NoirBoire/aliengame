extends KinematicBody2D

# Basic movement vars
var motion := Vector2()

# Export vars
export var hp := 2
export var start_flip := false

const UP := Vector2(0, -1)

func _physics_process(delta):
	move_and_slide(motion, UP)
