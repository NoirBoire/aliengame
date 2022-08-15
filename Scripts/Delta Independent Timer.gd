extends Node2D

export var wait_time := 0.0
export var one_shot := true
export var autostart := false

var time_left := 0.0
var active := true

signal is_done

func _physics_process(delta):
	
	if time_left > 0.0:
		time_left -= delta*(1/Engine.time_scale)
	
	elif time_left < 0.0:
		time_left = 0.0

	if time_left <= 0.0 && active:
		emit_signal("is_done")
		active = false

func stop():
	time_left = 0.0

func start():
	if time_left > 0.0:
		time_left = 0.0
	time_left = wait_time
	active = true

func is_stopped() -> bool:
	if time_left <= 0.0:
		return true
	else:
		return false
