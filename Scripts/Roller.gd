extends Node2D

# Statemachine enum
enum {
	MOVE,
	DAMAGED,
	RETURN
}

const speed := 40
const knockback_speed := 200
const motion := Vector2()
const wait_time := 0.35

var motion_x := 0
var motion_y := 0
var motion_multiplier := 1
var player_colliding := false
var was_player_colliding := false
var can_slowmo := true
var taking_damage := false
var state = MOVE
var spawn_x
var spawn_y
var spawn_coordinates := Vector2()
var sprites_flipped := false
var current_animation := "Move"
var yield_function = "_pass"
var can_return = false
var hp_to_lose = 0
var jump_grace = false

# Onready vars
onready var alien := owner.owner.get_node("Alien")
onready var coyote_timer = alien.coyote_timer

func _ready():
	sprites_flipped = owner.start_flip
	spawn_x = owner.position.x
	spawn_y = owner.position.y
	spawn_coordinates.x = spawn_x
	spawn_coordinates.y = spawn_y

func _physics_process(delta):
	# Check for alien in jumpbox
	if $Jumpbox.overlaps_body(alien):
		player_colliding = true
		was_player_colliding = true

		# Allow alien jumping
		coyote_timer.start()

		
		# Enemy step
		if (Input.is_action_just_pressed(Global.button_jump) || !alien.jump_buffer.is_stopped()) && player_colliding:
			if alien.position.y > global_position.y+3:
				alien.position.y = global_position.y
			alien.can_dash = true
			if !alien.is_on_floor():
				jump_grace = true
				$Timers/JumpGraceTimer.start()
				$Chassis/AnimationPlayer.current_animation = "Enemy Step"
			owner.motion.x = -owner.motion.x
			if state == DAMAGED:
				if hp_to_lose > 0:
					hp_to_lose -= 1
					pass
	else:
		player_colliding = false
		if state != DAMAGED:
			can_slowmo = true
		if !player_colliding && was_player_colliding:
			coyote_timer.stop()
			was_player_colliding = false
	
	# Slowmo and damage
	if alien.dash_anim && alien.motion.y >= 0 && $Hurtbox.overlaps_area(alien.get_node("Hitbox")):
		if can_slowmo:
			alien.slowmo.start_slowmo()
			hp_to_lose = 2
			state = DAMAGED
			$Timers/SlowmoTimer.start()
			can_slowmo = false
	
	# Raycast
	if !$GroundChecker.is_colliding() || $WallChecker.is_colliding():
		sprites_flipped = !sprites_flipped
	$GroundChecker.position.x = -10 if !sprites_flipped else 21
	$WallChecker.cast_to.x = - 12 if !sprites_flipped else 12
	
	# Disable jump grace
	if jump_grace:
		if alien.is_on_floor():
			$Timers/JumpGraceTimer.stop()
	
	#Animation
	$Chassis.flip_h = sprites_flipped
	$Wheel.flip_h = sprites_flipped
	if !($Chassis/AnimationPlayer.current_animation == "Enemy Step" && $Chassis/AnimationPlayer.is_playing()):
		if check_distance(alien) <= 100:
			if check_for_body(alien, alien.position):
				$Chassis/AnimationPlayer.current_animation = str(current_animation + " Alarm")
				$Chassis/AnimationPlayer.playback_speed = 1.2
				$Wheel/AnimationPlayer.playback_speed = 1.2
				motion_multiplier = 2
			else:
				$Chassis/AnimationPlayer.current_animation = current_animation
				motion_multiplier = 1
				$Chassis/AnimationPlayer.playback_speed = 1
				$Wheel/AnimationPlayer.playback_speed = 1
		else:
			$Chassis/AnimationPlayer.current_animation = current_animation
			motion_multiplier = 1
			$Chassis/AnimationPlayer.playback_speed = 1
			$Wheel/AnimationPlayer.playback_speed = 1
	$Wheel/AnimationPlayer.current_animation = current_animation
	# Statemachine
	match state:
		MOVE:
			motion_x = speed if sprites_flipped else -speed
			motion_y = 0
			
			if $Hitbox.overlaps_area(alien.get_node("Hurtbox")) && $Timers/YieldTimer.is_stopped():
				# Enemy step grace period
				custom_yield(0.01, "_attack")
			# Animation
			if !($Chassis/AnimationPlayer.current_animation == "Enemy Step" && $Chassis/AnimationPlayer.is_playing()):
				current_animation = "Move"
		DAMAGED:
			if !taking_damage:
				if player_colliding:
					if alien.position.x > owner.position.x:
						sprites_flipped = false
					elif alien.position.x < owner.position.x:
						sprites_flipped = true
				motion_x = (knockback_speed if !sprites_flipped else -knockback_speed)
				taking_damage = true
				$Timers/DamageTimer.start()
			if owner.hp <= 0:
				if owner.has_node("CollisionShape2D"):
					owner.get_node("CollisionShape2D").queue_free()
			# Animation
			current_animation = "Damaged"
		RETURN:
#			owner.motion.x = 0
#			owner.motion.y = 0
#			if $Timers/YieldTimer.is_stopped():
#				custom_yield(2.0, "_return")
#			if (abs(owner.position.x - spawn_x) > 20 || abs(owner.position.y - spawn_y) > 20) && can_return:
#				$AnimationPlayer.playback_speed = 1
#				$AnimationPlayer.play()
#				if owner.position.x > spawn_x:
#					motion_x = -speed/3
#					sprites_flipped = false
#				elif owner.position.x < spawn_x:
#					motion_x = speed/3
#					sprites_flipped = true
#			else:
#				can_return = false
#				state = MOVE
			pass
			
	# Horizontal movement
	owner.motion.x = lerp(owner.motion.x, motion_x*motion_multiplier, ((0.2 / ((1.0/Engine.get_frames_per_second())/delta)) if abs(motion_x) > 0 else (0.2 / ((1.0/Engine.get_frames_per_second())/delta))))
	
# Timer timeouts
func _on_DamageTimer_timeout():
	motion_x = 0
	$Timers/DamageAnimTimer.start()
func _on_DamageAnimTimer_timeout():
	owner.hp -= hp_to_lose
	hp_to_lose = 0
	if owner.hp <= 0:
		die()
	taking_damage = false
	current_animation = "Idle"
	state = MOVE
func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()
func _on_YieldTimer_timeout():
	call(yield_function)
func _on_JumpGraceTimer_timeout() -> void:
	jump_grace = false


# Custom functions
func check_distance(body) -> float:
	if typeof(body) == 5:
		return sqrt(pow((body.x - owner.position.x), 2)+pow((body.y - owner.position.y), 2))
	else:
		return sqrt(pow((body.position.x - owner.position.x), 2)+pow((body.position.y - owner.position.y), 2))
func check_for_body(body, target : Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var sight_check = space_state.intersect_ray(global_position, target, [self, owner], 1)
	
	if sight_check:
		if sight_check.collider.name == body.name:
			return true
		else:
			return false
	else:
		return false
func check_line_of_sight(body : Vector2) -> Object:
	var space_state = get_world_2d().direct_space_state
	var sight_check = space_state.intersect_ray(global_position, body, [self, owner], owner.collision_mask)
	if sight_check:
		return sight_check["collider"]
	return null
func die():
	owner.get_parent().add_child(owner.particol)
	owner.particol.position = owner.position
	owner.particol.get_node("ViewportContainer").get_node("Viewport").get_node("Particles2D").emitting = true
	owner.particol.get_node("ViewportContainer").get_node("Viewport").get_node("Particles2D2").emitting = true
	owner.queue_free()
func custom_yield(time : float, function):
	$Timers/YieldTimer.stop()
	$Timers/YieldTimer.wait_time = time
	$Timers/YieldTimer.start()
	yield_function = function
func _pass():
	pass
func _return():
	can_return = true
func _attack():
	if $Hitbox.overlaps_area(alien.get_node("Hurtbox")) && !alien.dashing && !jump_grace:
		alien.take_damage()
