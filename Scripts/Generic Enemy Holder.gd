extends CharacterBody2D

# Basic movement vars
var motion := Vector2()

# Export vars
@export var hp := 2
@export var start_flip := false

@onready var particle = preload("res://Scenes/Nodes/DeathParticle.tscn")
@onready var particol = particle.instantiate()

const UP := Vector2(0, -1)

func _physics_process(_delta):
	set_velocity(motion)
	set_up_direction(UP)
	move_and_slide()
