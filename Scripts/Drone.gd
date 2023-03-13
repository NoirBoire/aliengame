extends Node2D

# Statemachine enum
enum {
	IDLE,
	DAMAGED,
	SHOOT,
	RETURN
}

const speed := 48
const knockback_speed := 140
const motion := Vector2()
const wait_time := 0.35

var motion_x := 0
var motion_y := 0
var player_colliding := false
var was_player_colliding := false
var can_slowmo := true
var taking_damage := false
var state = IDLE
var can_fire = true
var spawn_x
var spawn_y
var spawn_coordinates := Vector2()
var can_flip := true
var yield_function = "_pass"
var can_return = false
var hp_to_lose = 0

# Onready vars
@onready var alien := owner.owner.get_node("Alien")
@onready var coyote_timer = alien.coyote_timer
@onready var bullet_scene := preload("res://Scenes/Nodes/Bullet.tscn")
@onready var shockwave_scene := preload("res://Scenes/Effects/BulletShockwave.tscn")

func _ready():
	$Sprite2D.flip_h = owner.start_flip
	spawn_x = owner.position.x
	spawn_y = owner.position.y
	spawn_coordinates.x = spawn_x
	spawn_coordinates.y = spawn_y

func _physics_process(delta):
	
	#if owner.name == "Drone7":
	#	print(state)
	
	if owner.position.distance_to(spawn_coordinates) > 150:
		state = RETURN
	if owner.position.distance_to(alien.position) > 150:
		state = RETURN
	
	# Check for jump on alien
	
	if owner.has_node("CollisionShape2D"):
		owner.get_node("CollisionShape2D").position = Vector2(position.x, position.y+3)
	
	if $Jumpbox.overlaps_body(alien):
		player_colliding = true
		was_player_colliding = true

		# Allow alien jumping
		coyote_timer.start()
		
		# Slowmo and damage
		if alien.dash_anim && alien.motion.y >= 0 && $Hurtbox.overlaps_area(alien.get_node("Hitbox")):
			if can_slowmo:
				alien.slowmo.start_slowmo()
				hp_to_lose = 2
				state = DAMAGED
				$Timers/SlowmoTimer.start()
				can_slowmo = false
				
		if (Input.is_action_just_pressed(Global.button_jump) || !alien.jump_buffer.is_stopped()) && player_colliding:
			if !alien.is_on_floor():
				if alien.position.y > global_position.y+3:
					alien.position.y = global_position.y
				alien.can_dash = true
				$Sprite2D/AnimationPlayer.current_animation = "Enemy Step"
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
	
	# Statemachine
	match state:
		IDLE:
			motion_x = 0
			motion_y = 0
			if (abs(alien.position.x - owner.position.x) > 8) && abs(alien.position.x - owner.position.x) < 100:
				if alien.position.x > owner.position.x:
					await get_tree().create_timer(0.3).timeout
					$Sprite2D.flip_h = true
				elif alien.position.x < owner.position.x:
					await get_tree().create_timer(0.3).timeout
					$Sprite2D.flip_h = false
			else:
				$Sprite2D.flip_h = false
			if check_distance(alien) < 120 && abs(alien.position.y - owner.position.y) < 30:
				if check_for_body(alien, alien.position):
					state = SHOOT
			# Animation
			if $Sprite2D/AnimationPlayer.current_animation != "Enemy Step":
				$Sprite2D/AnimationPlayer.current_animation = "Idle"
				$AnimationPlayer.set_speed_scale(1.0)
				$AnimationPlayer.play()
		DAMAGED:
			if !taking_damage:
				if player_colliding:
					if alien.position.x > owner.position.x:
						$Sprite2D.flip_h = false
					elif alien.position.x < owner.position.x:
						$Sprite2D.flip_h = true
				else:
					$Sprite2D.flip_h = !$Sprite2D.flip_h
				motion_x = (knockback_speed if !$Sprite2D.flip_h else -knockback_speed)
				taking_damage = true
				can_fire = true
				$Timers/ShootTimer.stop()
				$Timers/DamageTimer.start()
			if owner.hp <= 0:
				if owner.has_node("CollisionShape2D"):
					owner.get_node("CollisionShape2D").queue_free()
			# Animation
			$AnimationPlayer.set_speed_scale(1.0)
			$Sprite2D/AnimationPlayer.current_animation = "Damaged"
		SHOOT:
			# Animation
			if position.y != 0:
				$AnimationPlayer.set_speed_scale(8.0)
				if $AnimationPlayer.current_animation_position >= 2:
					$AnimationPlayer.play("Idle")
				else:
					$AnimationPlayer.play_backwards("Idle")
			else:
				$AnimationPlayer.stop(true)
				$AnimationPlayer.set_speed_scale(1.0)
			if !$Sprite2D/AnimationPlayer.current_animation == "Shoot":
				if $Sprite2D/AnimationPlayer.current_animation != "Enemy Step":
					$Sprite2D/AnimationPlayer.current_animation = "Ready"
				else:
					$Timers/ShootTimer.stop()
					$Timers/ShootTimer.start()
			
			if (abs(alien.position.x - owner.position.x) < 100):
				if check_for_body(alien, alien.position):
					if alien.position.x > owner.position.x:
						if !($Sprite2D/AnimationPlayer.current_animation == "Shoot" && $Sprite2D/AnimationPlayer.is_playing()):
								$Sprite2D.flip_h = true
					elif alien.position.x < owner.position.x:
						if !($Sprite2D/AnimationPlayer.current_animation == "Shoot" && $Sprite2D/AnimationPlayer.is_playing()):
							$Sprite2D.flip_h = false
					#var position_to_check = Vector2(owner.position.x + (100 * (1 if $Sprite2D.flip_h else -1)), owner.position.y+16)
					if abs(global_position.y - alien.position.y) < 24:
						if can_fire:
							$Timers/ShootTimer.start()
							can_fire = false
		RETURN:
			owner.motion.x = 0
			owner.motion.y = 0
			if $Timers/YieldTimer.is_stopped():
				custom_yield(2.0, "_return")
			if (abs(owner.position.x - spawn_x) > 20 || abs(owner.position.y - spawn_y) > 20) && can_return:
				$AnimationPlayer.set_speed_scale(1.0)
				$AnimationPlayer.play()
				if owner.position.x > spawn_x:
					motion_x = -speed/3
					$Sprite2D.flip_h = false
				elif owner.position.x < spawn_x:
					motion_x = speed/3
					$Sprite2D.flip_h = true
			else:
				can_return = false
				state = IDLE
			# Animation
			$AnimationPlayer.play()
			
	# Horizontal movement
	owner.motion.x = lerp(owner.motion.x, motion_x*1.0, ((1 / ((1.0/Engine.get_frames_per_second())/delta)) if abs(motion_x) > 0 else (0.1 / ((1.0/Engine.get_frames_per_second())/delta))))
	
	# Flip hitboxes
	if !$Sprite2D.flip_h:
		if owner.has_node("CollisionShape2D"):
			owner.get_node("CollisionShape2D").position.x = 0
		$Hurtbox/CollisionShape2D.position.x = -1
		$Jumpbox/CollisionShape2D.position.x = -1
	else:
		if owner.has_node("CollisionShape2D"):
			owner.get_node("CollisionShape2D").position.x = 0
		$Hurtbox/CollisionShape2D.position.x = 5
		$Jumpbox/CollisionShape2D.position.x = 5
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
	$Sprite2D/AnimationPlayer.current_animation = "Idle"
	state = SHOOT
func _on_SlowmoTimer_is_done():
	alien.slowmo.end_slowmo()

# Custom functions
func check_distance(body) -> float:
	if typeof(body) == 5:
		return sqrt(pow((body.x - owner.position.x), 2)+pow((body.y - owner.position.y), 2))
	else:
		return sqrt(pow((body.position.x - owner.position.x), 2)+pow((body.position.y - owner.position.y), 2))
func check_for_body(body, target : Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.new()
	params.from = global_position
	params.to = target
	params.collision_mask = owner.collision_mask && 1
	params.exclude = [self, owner]
	var sight_check = space_state.intersect_ray(params)
	if sight_check:
		if sight_check.collider.name == body.name:
			return true
		else:
			return false
	else:
		return false
func check_line_of_sight(body : Vector2) -> Object:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.new()
	params.from = global_position
	params.to = body
	params.collision_mask = owner.collision_mask
	params.exclude = [self, owner]
	var sight_check = space_state.intersect_ray(params)
	if sight_check:
		return sight_check["collider"]
	return null
func die():
	owner.get_parent().add_child(owner.particol)
	owner.particol.position = owner.position
	owner.particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("GPUParticles2D").emitting = true
	owner.particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("Particles2D2").emitting = true
	owner.queue_free()
func take_damage():
	pass
func custom_yield(time : float, function):
	$Timers/YieldTimer.stop()
	$Timers/YieldTimer.wait_time = time
	$Timers/YieldTimer.start()
	yield_function = function
func shoot():
	if state != DAMAGED:
		$Sprite2D/AnimationPlayer.current_animation = "Shoot"
		$Sprite2D/AnimationPlayer.play()
		
		# Shoot bullet
		var bullet: CharacterBody2D = bullet_scene.instantiate()
		owner.owner.add_child(bullet)
		bullet.global_position.y = global_position.y + 3
		bullet.global_position.x = (global_position.x -4 if !$Sprite2D.flip_h else global_position.x + 8)
		bullet.motion_x = (-72 if !$Sprite2D.flip_h else 72)
		
		# Bullet shockwave
		var shockwave: Node2D = shockwave_scene.instantiate()
		owner.owner.add_child(shockwave)
		shockwave.get_node("Sprite2D/AnimationPlayer").set_speed_scale(1.0)
		shockwave.global_position.x = (global_position.x -3 if !$Sprite2D.flip_h else global_position.x + 6)
		shockwave.global_position.y = global_position.y + 3
		
		can_fire = true
func _pass():
	pass
func _return():
	can_return = true

func _on_YieldTimer_timeout():
	call(yield_function)

func _on_ShootTimer_timeout():
	shoot()
