extends KinematicBody2D

onready var alien := owner.get_node("Alien")
onready var timer = alien.coyote_timer
var timer_duration := 0.0005
var wait_time := 0.35
var hp := 2
var on_drone := false
var can_slowmo := true

func _ready():
	$SlowmoTimer.wait_time = wait_time
	
func _process(delta):
	
	if name == "Drone2":
		print($SlowmoTimer.time_left)
	
	if $Area2D.overlaps_body(alien):
		on_drone = true
		
		# Allow alien jumping
		timer.wait_time = timer_duration
		timer.start()
		
		# Slowmo
		if alien.dash_anim && alien.motion.y >= 0:
			alien.slowmo.start_slowmo()
			if can_slowmo:
				$SlowmoTimer.start()
				can_slowmo = false
	else:
		can_slowmo = true
	
	# Check for jump on alien
	if Input.is_action_just_pressed(Global.button_jump) && on_drone:
		if alien.position.y > position.y+3:
			alien.position.y = position.y
		alien.can_dash = true
	
	if timer.is_stopped():
		on_drone = false
		alien.slowmo.end_slowmo()
	
	if hp <= 0:
		$DeathTimer.start()

func _on_DeathTimer_timeout():
	alien.slowmo.end_slowmo()
	die()
	
func die():
	queue_free()

func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()
