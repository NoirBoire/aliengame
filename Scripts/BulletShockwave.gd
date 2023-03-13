extends Node2D


func _process(_delta):
	if !$Sprite2D/AnimationPlayer.is_playing():
		queue_free()
