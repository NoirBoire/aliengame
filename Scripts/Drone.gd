extends Node2D

# Statemachine enum
enum {
	IDLE,
	DAMAGED,
	PURSUIT
}

const speed := 56
const knockback_speed := 124
const motion := Vector2()
const wait_time := 0.35

var motion_x := 0
var player_colliding := false
var was_player_colliding := false
var can_slowmo := true
var taking_damage := false
var state = IDLE

# Onready vars
onready var alien := owner.owner.get_node("Alien")
onready var coyote_timer = alien.coyote_timer

func _ready():
	$Sprite.flip_h = owner.start_flip

func _physics_process(delta):
	
	# Check for jump on alien
	if (Input.is_action_just_pressed(Global.button_jump) || !alien.jump_buffer.is_stopped()) && player_colliding:
		if alien.position.y > global_position.y+3:
			alien.position.y = global_position.y
		alien.can_dash = true
	
	if owner.has_node("CollisionShape2D"):
		owner.get_node("CollisionShape2D").position = Vector2(position.x, position.y+3)
	
	if $Area2D.overlaps_body(alien):
		player_colliding = true
		was_player_colliding = true

		# Allow alien jumping
		coyote_timer.start()
		
		# Slowmo
		if alien.dash_anim && alien.motion.y >= 0:
			if can_slowmo:
				alien.slowmo.start_slowmo()
				state = DAMAGED
				$SlowmoTimer.start()
				can_slowmo = false
	else:
		player_colliding = false
		if state != DAMAGED:
			can_slowmo = true
		if !player_colliding && was_player_colliding:
			coyote_timer.stop()
			was_player_colliding = false
	
	# Statemachine
	match state:
		IDLE:
			if (abs(alien.position.x - owner.position.x) > 8) && abs(alien.position.x - owner.position.x) < 124:
				if alien.position.x > owner.position.x:
						$Sprite.flip_h = true
				elif alien.position.x < owner.position.x:
					$Sprite.flip_h = false
			else:
				$Sprite.flip_h = false
			# Animation
			$Sprite/AnimationPlayer.current_animation = "Idle"
		DAMAGED:
			if !taking_damage:
				if player_colliding:
					if alien.position.x > owner.position.x:
						$Sprite.flip_h = false
					elif alien.position.x < owner.position.x:
						$Sprite.flip_h = true
				motion_x = (knockback_speed if !$Sprite.flip_h else -knockback_speed)
				owner.hp -= 1
				taking_damage = true
				$DamageTimer.start()
			$AnimationPlayer.stop(false)
			if owner.hp <= 0:
				if owner.has_node("CollisionShape2D"):
					owner.get_node("CollisionShape2D").queue_free()
			# Animation
			$Sprite/AnimationPlayer.current_animation = "Damaged"
		PURSUIT:
			if abs(alien.position.x - owner.position.x) > 5:
				if alien.position.x > owner.position.x:
					motion_x = speed
					$Sprite.flip_h = true
				elif alien.position.x < owner.position.x:
					motion_x = -speed
					$Sprite.flip_h = false
			else:
				motion_x = 0
			# Animation
			$Sprite/AnimationPlayer.current_animation = "Idle"
	
	# Horizontal movement
	owner.motion.x = lerp(owner.motion.x, motion_x, ((1 / ((1.0/Engine.get_frames_per_second())/delta)) if abs(motion_x) > 0 else (0.1 / ((1.0/Engine.get_frames_per_second())/delta))))

# Timer timeouts
func _on_DamageTimer_timeout():
	motion_x = 0
	$DamageAnimTimer.start()
func _on_DamageAnimTimer_timeout():
	if owner.hp <= 0:
		die()
	taking_damage = false
	state = IDLE
	$AnimationPlayer.play()

func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()

# Custom functions
func die():
	owner.queue_free()
