extends CharacterBody2D

@onready var alien := owner.get_node("Alien")
@onready var timer := alien.get_node("CoyoteTimer")
@onready var particle = preload("res://Scenes/Nodes/Secret.tscn")
@onready var particol = particle.instantiate()

func _on_Area2D_body_entered(body):
	if body == alien:
		get_parent().add_child(particol)
		particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("GPUParticles2D").emitting = true
		particol.position = position
		queue_free()
