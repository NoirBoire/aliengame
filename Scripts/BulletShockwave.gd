extends Node2D


func _process(delta):
	if !$Sprite/AnimationPlayer.is_playing():
		queue_free()
