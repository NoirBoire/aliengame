extends KinematicBody2D

onready var player = owner.get_node("Alien")

func _process(delta):
	pass


func _on_Area2D_body_entered(body):
	if body == player:
		player.die()
	if (body.get("hp")) != null:
		body.hp = 0
		body.get_node("Enemy").state = body.get_node("Enemy").DAMAGED
