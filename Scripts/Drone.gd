extends Node2D

# Statemachine enum
enum {
	IDLE,
	DAMAGED,
	PURSUIT,
	SHOOT,
	RETURN
}

const speed := 48
const knockback_speed := 124
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

# Onready vars
onready var alien := owner.owner.get_node("Alien")
onready var bullet_scene := preload("res://Scenes/Nodes/Bullet.tscn")
onready var coyote_timer = alien.coyote_timer

func _ready():
	$Sprite.flip_h = owner.start_flip
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
		
		# Slowmo and damage
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
			motion_x = 0
			motion_y = 0
			if (abs(alien.position.x - owner.position.x) > 8) && abs(alien.position.x - owner.position.x) < 100:
				if alien.position.x > owner.position.x:
					yield(get_tree().create_timer(0.3),"timeout")
					$Sprite.flip_h = true
				elif alien.position.x < owner.position.x:
					yield(get_tree().create_timer(0.3),"timeout")
					$Sprite.flip_h = false
			else:
				$Sprite.flip_h = false
			if check_distance(alien) < 100 && abs(alien.position.y - owner.position.y) < 30:
				if check_for_body(alien, alien.position):
					state = SHOOT
			# Animation
			$Sprite/AnimationPlayer.current_animation = "Idle"
			$AnimationPlayer.play()
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
			if check_for_body(alien, alien.position):
				var position_to_check = Vector2(owner.position.x + (30 * (1 if $Sprite.flip_h else -1)), global_position.y)
				if !((check_line_of_sight(position_to_check)) is TileMap):
					if abs(alien.position.x - owner.position.x) > 100:
						if alien.position.x > owner.position.x:
							motion_x = speed
							$Sprite.flip_h = true
						elif alien.position.x < owner.position.x:
							motion_x = -speed
							$Sprite.flip_h = false
					else:
						motion_x = 0
						motion_y = 0
						state = SHOOT

				# Animation
				if !(($Sprite/AnimationPlayer.current_animation == "Shoot" || $Sprite/AnimationPlayer.current_animation == "Damaged") && $Sprite/AnimationPlayer.is_playing()):
					$Sprite/AnimationPlayer.current_animation = "Idle"
				$AnimationPlayer.stop(false)
			else:
				var position_to_check = Vector2(owner.position.x + (30 * (1 if $Sprite.flip_h else -1)), global_position.y)
				if !((check_line_of_sight(position_to_check)) is TileMap):
					if $Sprite.flip_h:
						motion_x = lerp(motion_x, speed/2, 0.1)
					elif !$Sprite.flip_h:
						motion_x = lerp(motion_x, -speed/2, 0.1)
				else:
					motion_x = 0
					if abs(owner.motion.x) < 0.5:
						yield(get_tree().create_timer(0.5),"timeout")
						if can_flip:
							$Sprite.flip_h = !$Sprite.flip_h
							can_flip = false
							yield(get_tree().create_timer(0.5),"timeout")
							can_flip = true
				# Animation
				if !($Sprite/AnimationPlayer.current_animation == "Shoot" && $Sprite/AnimationPlayer.is_playing()):
					$Sprite/AnimationPlayer.current_animation = "Idle"
				$AnimationPlayer.play()
		SHOOT:
			# Animation
			$AnimationPlayer.stop(false)
			
			if (abs(alien.position.x - owner.position.x) < 100):
				if check_for_body(alien, alien.position):
					if alien.position.x > owner.position.x:
						if !($Sprite/AnimationPlayer.current_animation == "Shoot" && $Sprite/AnimationPlayer.is_playing()):
								$Sprite.flip_h = true
					elif alien.position.x < owner.position.x:
						if !($Sprite/AnimationPlayer.current_animation == "Shoot" && $Sprite/AnimationPlayer.is_playing()):
							$Sprite.flip_h = false
					var position_to_check = Vector2(owner.position.x + (100 * (1 if $Sprite.flip_h else -1)), owner.position.y+16)
					if abs(global_position.y - alien.position.y) < 24:
						yield(get_tree().create_timer(rand_range(1, 1.5)),"timeout")
						if can_fire && state != DAMAGED:
							$Sprite/AnimationPlayer.current_animation = "Shoot"
							$Sprite/AnimationPlayer.play()
							var bullet: KinematicBody2D = bullet_scene.instance()
							owner.owner.add_child(bullet)
							bullet.global_position.y = global_position.y + 3
							bullet.global_position.x = (global_position.x -4 if !$Sprite.flip_h else global_position.x + 8)
							bullet.motion_x = (-72 if !$Sprite.flip_h else 72)
							can_fire = false
							yield(get_tree().create_timer(1.5),"timeout")
							can_fire = true
				else:
					yield(get_tree().create_timer(1),"timeout")
					state = PURSUIT
			else:
				state = PURSUIT
		RETURN:
			owner.motion.x = 0
			owner.motion.y = 0
			yield(get_tree().create_timer(2),"timeout")
			if abs(owner.position.x - spawn_x) > 20 || abs(owner.position.y - spawn_y) > 20:
				$AnimationPlayer.play()
				if owner.position.x > spawn_x:
					motion_x = -speed
					$Sprite.flip_h = false
				elif owner.position.x < spawn_x:
					motion_x = speed
					$Sprite.flip_h = true
			else:
				state = IDLE
			# Animation
			$AnimationPlayer.play()
			
			
	# Horizontal movement
	owner.motion.x = lerp(owner.motion.x, motion_x, ((1 / ((1.0/Engine.get_frames_per_second())/delta)) if abs(motion_x) > 0 else (0.1 / ((1.0/Engine.get_frames_per_second())/delta))))
	owner.motion.y = lerp(owner.motion.y, motion_y, ((0.5 / ((1.0/Engine.get_frames_per_second())/delta))))
	
# Timer timeouts
func _on_DamageTimer_timeout():
	motion_x = 0
	$DamageAnimTimer.start()
func _on_DamageAnimTimer_timeout():
	if owner.hp <= 0:
		die()
	taking_damage = false
	$Sprite/AnimationPlayer.current_animation = "Idle"
	state = SHOOT
	yield(get_tree().create_timer(0.75),"timeout")
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
	var sight_check = space_state.intersect_ray(global_position, target, [self, owner], owner.collision_mask && 1)
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
	owner.queue_free()
