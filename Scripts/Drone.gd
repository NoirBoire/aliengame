extends KinematicBody2D

onready var alien := owner.get_node("Alien")
onready var timer = alien.coyote_timer
#var timer_duration := 0.01
var wait_time := 0.35
var hp := 2
var on_drone := false
var was_on_drone := false
var can_slowmo := true

func _physics_process(delta):
	
	# Check for jump on alien
	if (Input.is_action_just_pressed(Global.button_jump) || !alien.jump_buffer.is_stopped()) && on_drone:
		if alien.position.y > position.y+3:
			alien.position.y = position.y
		alien.can_dash = true
	
	if $Area2D.overlaps_body(alien):
		on_drone = true
		was_on_drone = true

		# Allow alien jumping
		timer.start()
		
		# Slowmo
		if alien.dash_anim && alien.motion.y >= 0:
			if can_slowmo:
				alien.slowmo.start_slowmo()
				$SlowmoTimer.start()
				can_slowmo = false
	else:
		on_drone = false
		can_slowmo = true
		if !on_drone && was_on_drone:
			timer.stop()
			was_on_drone = false
	
	if hp <= 0:
		$DeathTimer.start()

func _on_DeathTimer_timeout():
	alien.slowmo.end_slowmo()
	die()
	
func die():
	queue_free()

func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()
