extends KinematicBody2D

# Basic movement vars
var max_speed := 64
var speed := 64
var motion := Vector2()
var motion_x := 0

# Jump vars
var max_jump_vel
var min_jump_vel
var gravity
var max_jump_height := 2.25 * Global.UNIT_SIZE
var min_jump_height := 0.25 * Global.UNIT_SIZE
var jump_duration := 0.5
var is_jumping := false
var coyote_timer_duration := 0.1
var was_on_floor
var jump_buffer_jump := false

# Dash vars
var dash_duration := 0.16
var dash_speed := 5
var dash_jump_speed := 0.75
var speed_modifier := 1
var dashing := false
var dash_anim := false
var can_dash := true
var air_dash := false

# Child vars
onready var coyote_timer = $CoyoteTimer
onready var jump_buffer = $JumpBuffer
onready var slowmo = $Slowmo
onready var anim_state = $Sprite/AnimationTree.get("parameters/playback")

# Controls
var button_left := Global.button_left
var button_right := Global.button_right
var button_jump := Global.button_jump
var button_dash := Global.button_dash
var button_restart := Global.button_restart

const UP := Vector2(0, -1)

func _ready():
	
	# Set gravity and jump values
	
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	max_jump_vel = -sqrt(2 * gravity * max_jump_height)
	min_jump_vel = -sqrt(2 * gravity * min_jump_height)
	
	# Set speed
	
	speed = max_speed

func _physics_process(delta):
	
	# Gravity and coyote timer check
	was_on_floor = is_on_floor()
	
	if !dashing:
		motion.y += gravity * delta
	elif !is_on_floor():
		motion.y = 0

	
	move_and_slide(motion, UP)
	
	if is_on_floor():
		# Stop gravity when on floor
		
		if motion.y > 0:
			motion.y = 0
		
		# Allow dashing
		if Engine.time_scale >= 1:
			can_dash = true
		else:
			can_dash = false
	
	if is_on_ceiling():
		# Stop jump when hitting ceiling
		if motion.y < 0:
			motion.y = 0

	# Jumping
	if !is_on_floor() && was_on_floor && !is_jumping:
		coyote_timer.start()
	if ((is_on_floor() && !jump_buffer.is_stopped()) || (!coyote_timer.is_stopped() && !jump_buffer.is_stopped())) && motion.y > (max_jump_vel+100):
		jump()
	
	if Input.is_action_just_pressed(button_jump):
		jump()
	if Input.is_action_just_released(button_jump):
		if motion.y < min_jump_vel:
			motion.y = min_jump_vel
	if motion.y >= 0:
		is_jumping = false
	
	if Input.is_action_just_pressed(button_restart):
		die()
	
	# Dashing
	
	if Input.is_action_just_pressed(button_dash):
		if can_dash:
			dash()
			if Input.is_action_just_pressed(button_jump):
				jump()
	
	# Horizontal movement and stopping
	
	if !dashing:
		if Input.is_action_pressed(button_right):
			motion_x = speed
			$Sprite.flip_h = false
		elif Input.is_action_pressed(button_left):
			motion_x = -speed
			$Sprite.flip_h = true
		else:
			motion_x = 0
	elif motion_x == 0:
		motion_x = -speed*(1 if $Sprite.flip_h else -1)

	motion.x = lerp(motion.x, motion_x*speed_modifier, (0.5 / ((1.0/Engine.get_frames_per_second())/delta) if dashing else 0.2 / ((1.0/Engine.get_frames_per_second())/delta)))

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
			anim_state.travel("Dash")
		elif is_jumping:
			anim_state.travel("Jump")
	if position.y > 500:
		die()
	if Input.is_action_pressed("ui_alt") && Input.is_action_just_pressed("ui_enter"):
		OS.window_fullscreen = !OS.window_fullscreen

	
func jump():

	if is_on_floor() || !coyote_timer.is_stopped():
		if dashing && !air_dash:
			motion.y = max_jump_vel*1.2
			can_dash = false
		else:
			dash_anim = false
			stop_dash_anim()
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
	if is_on_floor():
		air_dash = false
	else:
		air_dash = true
	dashing = true
	dash_anim = true
	can_dash = false
	speed_modifier = dash_speed
	$Dash/DashTimer.wait_time = dash_duration
	$Dash/DashAnimTimer.wait_time = dash_duration*1.4
	$Dash/DashTimer.start()
	$Dash/DashAnimTimer.start()
	$Dash/GhostTimer.start()
func stop_dashing():
	speed_modifier = 1
	dashing = false
func stop_dash_anim():
	dash_anim = false
	motion.x = motion_x
	$Dash/GhostTimer.stop()
func die():
	get_tree().change_scene("res://Scenes/Main.tscn")
