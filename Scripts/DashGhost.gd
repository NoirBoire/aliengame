extends Sprite2D


func _ready():
	var tween = create_tween()
	#tween.interpolate_property(self, "modulate:a", 0.8, 0.0, 0.75, 3, 1)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)


#func _on_Tween_tween_completed(object, key):
#	queue_free()

