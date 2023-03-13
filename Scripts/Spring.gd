extends Node2D

var alien : Ploopy


func _ready() -> void:
	alien = owner.get_node("Alien")

func _physics_process(_delta):
	if $Area2D.overlaps_body(alien):
		var statemachine = $Sprite2D/AnimationTree.get("parameters/playback")
		alien.is_jumping = true
		alien.motion.y = alien.max_jump_vel*1.7
		alien.can_dash = true
		statemachine.travel("Jump")
