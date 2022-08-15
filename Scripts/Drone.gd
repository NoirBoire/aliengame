extends Node2D

# Basic movement vars
var speed := 82
var motion := Vector2()
var motion_x := 0

onready var alien := owner.owner.get_node("Alien")
onready var timer = alien.coyote_timer
#var timer_duration := 0.01
var wait_time := 0.35
var on_drone := false
var was_on_drone := false
var can_slowmo := true
var taking_damage := false

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	
	# Check for jump on alien
	if (Input.is_action_just_pressed(Global.button_jump) || !alien.jump_buffer.is_stopped()) && on_drone:
		if alien.position.y > global_position.y+3:
			alien.position.y = global_position.y
		alien.can_dash = true
	
	if owner.name == "Drone2":
		print(owner.motion.x)
	
	if $Area2D.overlaps_body(alien):
		on_drone = true
		was_on_drone = true

		# Allow alien jumping
		timer.start()
		
		# Slowmo
		if alien.dash_anim && alien.motion.y >= 0:
			if can_slowmo:
				alien.slowmo.start_slowmo()
				if taking_damage == false:
					owner.hp -= 1
					taking_damage = true
					$AnimationPlayer.stop(false)
					if alien.position.x > owner.position.x:
						$Sprite.flip_h = false
					elif alien.position.x < owner.position.x:
						$Sprite.flip_h = true
					motion_x = (speed if !$Sprite.flip_h else -speed)
					$DamageTimer.start()
				$SlowmoTimer.start()
				can_slowmo = false
	else:
		on_drone = false
		can_slowmo = true
		if !on_drone && was_on_drone:
			timer.stop()
			was_on_drone = false
	
	# Horizontal movement
	owner.motion.x = lerp(owner.motion.x, motion_x, ((1 / ((1.0/Engine.get_frames_per_second())/delta)) if abs(motion_x) > 0 else (0.1 / ((1.0/Engine.get_frames_per_second())/delta))) )
	
	# Animation
	if taking_damage:
		$Sprite/AnimationPlayer.current_animation = "Damage"
	elif !taking_damage:
		$Sprite/AnimationPlayer.current_animation = "Idle"
	
func _on_DamageTimer_timeout():
	motion_x = 0
	$DamageAnimTimer.start()
func _on_DamageAnimTimer_timeout():
	taking_damage = false
	if owner.hp <= 0:
		die()
	$AnimationPlayer.play()

	
func die():
	queue_free()

func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()


