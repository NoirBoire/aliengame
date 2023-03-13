extends CharacterBody2D

@onready var player = owner.get_node("Alien")
var check_for_bodies := false

func _on_Area2D_body_entered(body):
	if body == player:
		player.die()
	elif (body.get("hp")) != null:
		if body.get_node("Enemy").state == body.get_node("Enemy").DAMAGED:
			body.get_node("Enemy").state = body.get_node("Enemy").IDLE
			body.get_node("Enemy").taking_damage = false
			body.get_node("Enemy").state = body.get_node("Enemy").DAMAGED
			body.hp = 0
