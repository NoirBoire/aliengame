extends CharacterBody2D
class_name Ploopy

# Constants
const max_speed := 64
const speed := 64
const UP := Vector2(0, -1)
const max_jump_height := 2.25 * Global.UNIT_SIZE
const min_jump_height := 0.25 * Global.UNIT_SIZE
const jump_duration := 0.5
const dash_duration := 0.16
const dash_speed := 5

# Statemachine enum/vars
enum {
	IDLE,
	DAMAGED,
	MOVE_RIGHT,
	MOVE_LEFT,
	JUMP,
	JUMP_RELEASE,
	DASH,
	DASH_JUMP
}

var state = IDLE

# Basic movement vars
var motion := Vector2()
var motion_x := 0

# Jump vars
var max_jump_vel
var min_jump_vel
var gravity

var is_jumping := false
var was_on_floor
var jump_buffer_jump := false
var invincible := false

# Dash vars
var speed_modifier := 1
var dashing := false
var dash_anim := false
var can_dash := true
var air_dash := false
var can_sprint := false

# Jump vars
var buffering_jump := false
var buffering_dash := false

var hp = 5

# Child vars
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer = $JumpBuffer
@onready var slowmo = $Slowmo
@onready var anim_state = $Sprite2D/AnimationTree.get("parameters/playback")

# Controls
var button_left := Global.button_left
var button_right := Global.button_right
var button_jump := Global.button_jump
var button_dash := Global.button_dash
var button_restart := Global.button_restart


func _ready():
	
	# Set gravity and jump values
	
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	max_jump_vel = -sqrt(2 * gravity * max_jump_height)
	min_jump_vel = -sqrt(2 * gravity * min_jump_height)
	
	# Declare self as player on global.gd
	
	Global.player = self
	
	# Disable hitbox
	
	$Hitbox/CollisionShape2D.disabled = true
	reset_hurtbox()

func _physics_process(delta):
	
	# Gravity and coyote timer check
	was_on_floor = is_on_floor()
	
	if !dashing:
		motion.y += gravity * delta
	elif !is_on_floor():
		motion.y = 0

	
	set_velocity(motion)
	set_up_direction(UP)
	move_and_slide()
	
	if is_on_floor():
		
		# Stop gravity when on floor
		if motion.y > 0:
			motion.y = 0
		
		# Allow dashing
		can_dash = true

	if is_on_ceiling():
		
		# Stop jump when hitting ceiling
		if motion.y < 0:
			motion.y = 0

	# Restarting
	if Input.is_action_just_pressed(button_restart):
		die()
	
	# Statemachine
	match state:
		IDLE:
			motion_x = 0
		MOVE_RIGHT:
			motion_x = speed
			$Sprite2D.flip_h = false
		MOVE_LEFT:
			motion_x = -speed
			$Sprite2D.flip_h = true
		JUMP:
			jump()
		JUMP_RELEASE:
			if motion.y < min_jump_vel:
				motion.y = min_jump_vel
		DASH:
			if !dash_anim:
				dash()
		DASH_JUMP:
			dash()
			jump()
		DAMAGED:
			if $DamageTimer.is_stopped():
				stop_dashing()
				stop_dash_anim(true)
				motion_x = 0
				hp -= 1
				if motion.y > 0:
					motion.y = 0
				motion.y = max_jump_vel/1.2
				if $Sprite2D.flip_h:
					motion.x = 100
				elif !$Sprite2D.flip_h:
					motion.x = -100
				$DamageTimer.start()
			motion.x = lerp(motion.x, motion_x*1.0, 0.05)
	
	# Horizontal movement and stopping
	if state != DAMAGED:
		if !dashing:
			if Input.is_action_pressed(button_right):
				state = MOVE_RIGHT
			elif Input.is_action_pressed(button_left):
				state = MOVE_LEFT
			else:
				state = IDLE
		elif motion_x == 0:
			motion_x = -speed*(1 if $Sprite2D.flip_h else -1)
	
	# Dashing
	if Input.is_action_just_pressed(button_dash):
		if can_dash:
			if is_on_floor():
				buffering_dash = true
				$DashJumpBuffer.start()
			else:
				dash()
	
	# Jumping
	if !is_on_floor() && was_on_floor && !is_jumping:
		coyote_timer.start()
	
	if ((is_on_floor() && !jump_buffer.is_stopped()) || (!coyote_timer.is_stopped() && !jump_buffer.is_stopped()) && motion.y > (max_jump_vel+100)):
		if is_on_floor():
			buffering_jump = true
			$DashJumpBuffer.start()
		else:
			jump()
	
	if Input.is_action_just_pressed(button_jump):
		if is_on_floor():
			buffering_jump = true
			$DashJumpBuffer.start()
		else:
			jump()
	
	if Input.is_action_just_released(button_jump):
		if motion.y < min_jump_vel:motion.y = min_jump_vel
	if motion.y >= 0:
		is_jumping = false
	
	# Move player
	if state != DAMAGED:
		motion.x = lerpf(motion.x, motion_x*speed_modifier, get_lerp_weight(delta, dashing, motion_x))
	
	# Animation
	if !dash_anim:
		if is_on_floor():
			if motion.x > speed/2 || motion.x < -speed/2:
				anim_state.travel("Run")
			else:
				anim_state.travel("Idle")
		else:
			if motion.y < 0: 
				anim_state.travel("Jump")
			elif motion.y > 0:
				anim_state.travel("Fall")
	else:
		if !is_jumping:
			if !air_dash:
				anim_state.travel("Air Dash")
			elif air_dash:
				anim_state.travel("Air Dash")
		elif is_jumping:
			anim_state.travel("Jump")
	
	
	
	
	if position.y > 500:
		die()
	
func jump():
	if state != DAMAGED:
		if is_on_floor() || !coyote_timer.is_stopped():
			if dashing && !air_dash:
				motion.y = max_jump_vel*1.2
				can_dash = false
			else:
				dash_anim = false
				stop_dash_anim(false)
				motion.y = max_jump_vel
			is_jumping = true
			if dashing:
				dashing = false
				stop_dashing()
			coyote_timer.stop()
			$Slowmo.end_slowmo()
		elif !is_on_floor():
			jump_buffer.start()

func dash():
	if state != DAMAGED && $DashCooldown.is_stopped():
		if is_on_floor():
			air_dash = false
		else:
			air_dash = true
		dashing = true
		dash_anim = true
		can_dash = false
		speed_modifier = dash_speed
		$Invincibility.start()
		invincible = true
		$Dash/DashTimer.wait_time = dash_duration
		$Dash/DashAnimTimer.wait_time = dash_duration*1.4
		$Dash/DashTimer.start()
		$Dash/DashAnimTimer.start()
		$Dash/GhostTimer.start()
		$DashCooldown.start()

func stop_dashing():
	speed_modifier = 1
	dashing = false

func stop_dash_anim(anim_only : bool):
	dash_anim = false
	$Dash/GhostTimer.stop()
	if !anim_only:
		motion.x = motion_x

func reset_hurtbox():
	$Hurtbox/Dash.disabled = true
	$Hurtbox/Normal.disabled = false
	$Hitbox/CollisionShape2D.disabled = true

func die():
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func take_damage():
	if !invincible:
		state = DAMAGED

func _on_DashJumpBuffer_is_done():
	if buffering_dash && buffering_jump:
		dash()
		jump()
		buffering_dash = false
		buffering_jump = false
	elif buffering_dash:
		dash()
		can_sprint = true
		buffering_dash = false
	elif buffering_jump:
		jump()
		buffering_jump = false
		


func _on_DamageTimer_timeout():
	if hp <= 0:
		die()
	else:
		state = IDLE


func _on_Invincibility_timeout() -> void:
	invincible = false;

func get_lerp_weight(delta: float, dashing: bool, motion_x: float) -> float:
	var default_weight := 0.2 / ((1.0/Engine.get_frames_per_second())/delta)
	if dashing:
		return default_weight
	if abs(motion_x) > 0:
		return default_weight
	return 0.8
