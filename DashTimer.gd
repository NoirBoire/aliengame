extends Node

onready var ghost_scene = preload("res://Scenes/Nodes/DashGhost.tscn")
onready var sprite = owner.get_node("Sprite")
onready var alien = owner

func _ready():
	$DashTimer.process_mode = Timer.TIMER_PROCESS_IDLE
	$DashAnimTimer.process_mode = Timer.TIMER_PROCESS_IDLE

func instance_ghost():
	
	var ghost: Sprite = ghost_scene.instance()
	alien.owner.add_child(ghost)
	
	ghost.texture = sprite.texture
	ghost.vframes = sprite.vframes
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.set_modulate("9637ff")
	ghost.z_index = sprite.z_index - 1
	ghost.global_position = sprite.global_position
	ghost.flip_h = sprite.flip_h


func _on_GhostTimer_timeout():
	instance_ghost()


func _on_DashTimer_timeout():
	alien.stop_dashing()

func _on_DashAnimTimer_timeout():
	if alien.state != alien.DAMAGED:
		alien.stop_dash_anim(false)
