extends Node

onready var ghost_scene = preload("res://Scenes/Nodes/DashGhost.tscn")
onready var sprite = get_parent().get_node("Sprite")

func _ready():
	$DashTimer.process_mode = Timer.TIMER_PROCESS_IDLE
	$DashAnimTimer.process_mode = Timer.TIMER_PROCESS_IDLE

func _process(delta):
	if $DashTimer.is_stopped():
		get_parent().stop_dashing()
	if $DashAnimTimer.is_stopped():
		get_parent().stop_dash_anim()

func instance_ghost():
	
	var ghost: Sprite = ghost_scene.instance()
	get_parent().get_parent().add_child(ghost)
	
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
