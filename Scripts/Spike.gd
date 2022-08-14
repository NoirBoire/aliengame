extends KinematicBody2D

onready var player = owner.get_node("Alien")

func _process(delta):
	pass


func _on_Area2D_body_entered(body):
	if body == player:
		player.die()
