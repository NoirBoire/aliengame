extends KinematicBody2D

var motion = Vector2()
var motion_x = 0
var motion_y = 0

func _ready():
	yield(get_tree().create_timer(8), "timeout")
	queue_free()

func _physics_process(delta):
	move_and_slide(motion)
	motion.x = motion_x
	motion.y = motion_y
