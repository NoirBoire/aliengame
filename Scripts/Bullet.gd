extends KinematicBody2D

var motion = Vector2()
var motion_x = 0
var motion_y = 0

func _ready():
	$LifeTimer.wait_time = 3
	$LifeTimer.start()

func _physics_process(delta):
	move_and_slide(motion)
	motion.x = motion_x
	motion.y = motion_y
	if $Area2D.overlaps_area(Global.player.get_node("Hurtbox")):
		Global.player.take_damage()
		queue_free()
	for body in $Area2D.get_overlapping_bodies():
		if body is TileMap:
			queue_free()


func _on_LifeTimer_timeout() -> void:
	queue_free()
